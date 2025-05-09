//////////////////////////////////////////////////////////////
//                                                          //
// This testbench has been generated by the Verilog         //
// testbench generator                .                     //
// Copyright (c) 2012-2022 EDAUtils LLP                 //
// Contact help@edautils.com  for support/info.//
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////
//
//
// Generated by : protim on 4/24/25, 3:51 AM
//
//
module testbench;
	reg [0:83] indata_array;
	reg bench_reset;
	wire [31:0]bench_tin;
	wire [15:0]bench_uin;
	wire [15:0]bench_vin;
	wire [15:0]bench_triIDin;
	wire bench_hit;
	wire [31:0]bench_t;
	wire [15:0]bench_u;
	wire [15:0]bench_v;
	wire [15:0]bench_triID;
	wire bench_anyhit;
	wire bench_enable;
	wire bench_globalreset;
	wire bench_clk;



	assign bench_tin = indata_array[0:31];
	assign bench_uin = indata_array[32:47];
	assign bench_vin = indata_array[48:63];
	assign bench_triIDin = indata_array[64:79];
	assign bench_hit = indata_array[80:80];
	assign bench_enable = indata_array[81:81];
	assign bench_globalreset = indata_array[82:82];
	assign bench_clk = indata_array[83:83];

	initial
	begin
    $dumpfile("13.vcd");
    $dumpvars(1, testbench);
		#10 bench_reset = 1'b0;
	end

	always
	begin
		#5  indata_array = $random;
	end

	nearcmp inst(
        .tin(bench_tin), 
        .uin(bench_uin), 
        .vin(bench_vin), 
        .triIDin(bench_triIDin), 
        .hit(bench_hit), 
        .t(bench_t), 
        .u(bench_u), 
        .v(bench_v), 
        .triID(bench_triID), 
        .anyhit(bench_anyhit), 
        .enable(bench_enable), 
        .reset(bench_reset), 
        .globalreset(bench_globalreset), 
        .clk(bench_clk)
    );

	initial
	begin
		$monitor($time, " bench_reset = %b, tin = %b , uin = %b , vin = %b , triIDin = %b , hit = %b , enable = %b , globalreset = %b , clk = %b , t = %b , u = %b , v = %b , triID = %b , anyhit = %b  ",
			bench_reset, bench_tin, bench_uin, bench_vin, bench_triIDin, bench_hit, bench_enable, bench_globalreset, bench_clk, bench_t, bench_u, bench_v, bench_triID, bench_anyhit);
	end

	initial
	begin
		#199 $finish;
	end

endmodule
