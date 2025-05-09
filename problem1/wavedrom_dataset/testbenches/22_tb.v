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
// Generated by : protim on 4/24/25, 3:52 AM
//
//
module testbench;
	reg [0:1] indata_array;
	reg bench_reset;
	wire bench_clk;
	wire bench_in;
	wire bench_out;



	assign bench_clk = indata_array[0:0];
	assign bench_in = indata_array[1:1];

	initial
	begin
    $dumpfile("22.vcd");
    $dumpvars(1, testbench);
		#10 bench_reset = 1'b0;
	end

	always
	begin
		#5  indata_array = $random;
	end

	e16_pulse2toggle inst(
        .clk(bench_clk), 
        .in(bench_in), 
        .out(bench_out), 
        .reset(bench_reset)
    );

	initial
	begin
		$monitor($time, " bench_reset = %b, clk = %b , in = %b , out = %b  ",
			bench_reset, bench_clk, bench_in, bench_out);
	end

	initial
	begin
		#199 $finish;
	end

endmodule
