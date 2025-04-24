module e16_synchronizer #(parameter DW=32) (/*AUTOARG*/
   // Outputs
   out,
   // Inputs
   in, clk, reset
   );


   //Input Side   
   input  [DW-1:0] in;   
   input           clk;      
   input           reset;//asynchronous signal
   
   
   //Output Side
   output [DW-1:0] out;

   reg [DW-1:0] sync_reg0;
   reg [DW-1:0] sync_reg1;
   reg [DW-1:0] out;
     
   //Synchronization between clock domain
   //We use two flip-flops for metastability improvement
   always @ (posedge clk or posedge reset)
     if(reset)
       begin
	  sync_reg0[DW-1:0] <= {(DW){1'b0}};
	  sync_reg1[DW-1:0] <= {(DW){1'b0}};
	  out[DW-1:0]       <= {(DW){1'b0}};
       end
     else
       begin
	  sync_reg0[DW-1:0] <= in[DW-1:0];
	  sync_reg1[DW-1:0] <= sync_reg0[DW-1:0];
	  out[DW-1:0]       <= sync_reg1[DW-1:0];
       end
   


   
   
     

endmodule