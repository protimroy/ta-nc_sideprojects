import os
import json
import csv
import re
import sys
import subprocess
from tqdm import tqdm
from datasets import load_dataset
from PIL import Image
from concurrent.futures import ProcessPoolExecutor, as_completed

Image.MAX_IMAGE_PIXELS = 200_000_000    # Disable DecompressionBombWarning

# Config
BASE_DIR = "wavedrom_dataset"
DIRS = {
    "verilog": os.path.join(BASE_DIR, "verilog_modules"),
    "testbench": os.path.join(BASE_DIR, "testbenches"),
    "output": os.path.join(BASE_DIR, "iverilog_output"),
    "vcd": os.path.join(BASE_DIR, "vcd"),
    "json": os.path.join(BASE_DIR, "wavedrom"),
    "images": os.path.join(BASE_DIR, "timing_diagrams")
}
OUTPUT_JSONL = os.path.join(BASE_DIR, "dataset.jsonl")
NUM_SAMPLES = 100

# Directory prep
def prepare_directories():
    os.makedirs(BASE_DIR, exist_ok=True)
    for d in DIRS.values():
        os.makedirs(d, exist_ok=True)

# Fetch Verilog files from HF dataset
def fetch_verilog_samples(num_samples=100):
    print("⏳ Fetching samples from Hugging Face...")
    try:
        ds = load_dataset("vkenbeek/verilog-wavedrom")
        count = 0
        for i in range(len(ds["train"])):
            verilog_code = ds["train"][i]["text"]
            if not re.search(r'\b(reset|rst|reset_n)\b', verilog_code):
                continue
            with open(os.path.join(DIRS["verilog"], f"{count}.v"), "w") as f:
                f.write(verilog_code)
            count += 1
            if count >= num_samples:
                break
        print(f"✅ Downloaded {count} Verilog files.")
    except Exception as e:
        print(f"❌ Failed to load dataset: {e}")
        exit(1)

def extract_module_name(filepath):
    with open(filepath, 'r') as f:
        text = f.read()
    match = re.search(r'(?<=module\s)\w+', text)
    return match.group(0) if match else None

def augment_testbench(tb_path, row):
    try:
        with open(tb_path, 'r') as file:
            content = file.read()
        module_match = re.search(r'module\s+(\w+)', content)
        if not module_match:
            raise ValueError("Module name not found in testbench")
        module_name = module_match.group(1)

        def replace_initial_block(match):
            block = match.group(0)
            return block.replace('begin', f'begin\n    $dumpfile("{row}.vcd");\n    $dumpvars(1, {module_name});')

        modified = re.sub(r'initial\s*begin(.*?)end', replace_initial_block, content, count=1, flags=re.DOTALL)
        if content == modified:
            raise ValueError("No initial block found in testbench to augment.")
        with open(tb_path, 'w') as file:
            file.write(modified)
    except Exception as e:
        raise RuntimeError(f"Failed to augment testbench {tb_path}: {e}")

# Process a single sample
def process_sample(idx, vfile):
    row = str(idx)
    verilog_path = os.path.join(DIRS["verilog"], vfile)
    tb_path = os.path.join(DIRS["testbench"], f"{row}_tb.v")
    out_path = os.path.join(DIRS["output"], f"{row}.out")
    vcd_path = os.path.join(DIRS["vcd"], f"{row}.vcd")
    json_path = os.path.join(DIRS["json"], f"{row}.json")
    img_path = os.path.join(DIRS["images"], f"{row}.png")

    try:
        #subprocess.run(["gentbvlog", "-in", verilog_path, "-top", "testbench", "-out", tb_path, "-rst", "reset", "-max_sim_time", "199"], check=True)
        
        module_name = extract_module_name(verilog_path)
        if not module_name:
            raise ValueError(f"[!] Could not extract module name from {verilog_path}")
        subprocess.run(["gentbvlog", "-in", verilog_path, "-top", module_name, "-out", tb_path, "-rst", "reset", "-max_sim_time", "199"], check=True)

        augment_testbench(tb_path, row)

        print( f" Augmenting testbench {tb_path} with $dumpfile and $dumpvars")

        subprocess.run(["iverilog", "-o", out_path, verilog_path, tb_path], check=True)
        subprocess.run(["vvp", out_path], check=True)
        
        # move the dump.vcd to the correct location
        dump_path = f"{row}.vcd"

        if not os.path.exists(dump_path):
            print(f"[!] Warning: dump.vcd not found for sample {row}")
            return None
        os.rename(dump_path, vcd_path)

        with open(json_path, "w") as f:
            subprocess.run(["python3", "-m", "vcd2wavedrom.vcd2wavedrom", "-i", vcd_path], stdout=f, check=True)

        subprocess.run(["wavedrom-cli", "-i", json_path, "-p", img_path], check=True)

        with Image.open(img_path) as im:
            width, height = im.size
            print(f"[✓] {row}.png dimensions: {width}x{height} ({width*height} pixels)")

        return {
            "index": row,
            "verilog": verilog_path,
            "testbench": tb_path,
            "vcd": vcd_path,
            "wavedrom": json_path,
            "image": img_path
        }
    except Exception as e:
        print(f"[!] Sample {row} failed: {e}")
        return None

# Main processing

def generate_dataset():
    manifest_path = os.path.join(BASE_DIR, "manifest.csv")
    manifest = []
    v_files = [f for f in os.listdir(DIRS["verilog"]) if f.endswith(".v") and not f.endswith("_tb.v")]
    print(f"🚀 Generating dataset with {len(v_files)} samples using parallel processing...")
    with ProcessPoolExecutor() as executor:
        futures = [executor.submit(process_sample, idx, vfile) for idx, vfile in enumerate(v_files)]
        for future in tqdm(as_completed(futures), total=len(futures), desc="📦 Collecting results"):
            result = future.result()
            if result:
                manifest.append(result)

    print("💾 Writing manifest.csv...")
    with open(manifest_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["index", "verilog", "testbench", "vcd", "wavedrom", "image"])
        writer.writeheader()
        writer.writerows(manifest)

# Write final jsonl

def write_jsonl():
    entries = []
    manifest_path = os.path.join(BASE_DIR, "manifest.csv")
    with open(manifest_path, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            with open(row["wavedrom"], "r") as jfile:
                code = jfile.read().strip()
            entries.append({"image": row["image"], "code": code})

    print("📝 Writing dataset.jsonl...")
    with open(OUTPUT_JSONL, "w") as f:
        for e in tqdm(entries, desc=f"Writing {OUTPUT_JSONL}"):
            f.write(json.dumps(e) + "\n")

if __name__ == "__main__":
    print("📁 Preparing directories...")
    prepare_directories()
    fetch_verilog_samples(NUM_SAMPLES)
    generate_dataset()
    write_jsonl()
    print("✅ Dataset generation complete.")
