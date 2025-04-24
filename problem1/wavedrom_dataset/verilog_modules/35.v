module nearcmp (tin, uin, vin, triIDin, hit, t, u, v, triID, anyhit, enable, reset, globalreset, clk);

    input[31:0] tin; 
    input[15:0] uin; 
    input[15:0] vin; 
    input[15:0] triIDin; 
    input hit; 
    output[31:0] t; 
    reg[31:0] t;
    output[15:0] u; 
    reg[15:0] u;
    output[15:0] v; 

    reg[15:0] v;
    output[15:0] triID; 
    reg[15:0] triID;
    output anyhit; 
    wire anyhit;
    reg temp_anyhit;
    input enable; 
    input reset; 
    input globalreset; 
    input clk; 


    reg state; 
    reg next_state; 
    reg latchnear; 

	assign anyhit = temp_anyhit;

    always @(posedge clk or posedge globalreset)
    begin
       if (globalreset == 1'b1)
       begin
          state <= 0 ; 
          t <= 0;

          u <= 0;
          v <= 0;
          triID <= 0;
       end
       else
       begin
          state <= next_state ; 
          if (latchnear == 1'b1)
          begin
             t <= tin ; 
             u <= uin ; 
             v <= vin ; 

             triID <= triIDin ; 
          end 
       end 
    end 

    always @(state or tin or t or enable or hit or reset)
    begin

//      latchnear = 1'b0 ; 
       case (state)
          0 :
                   begin
                      if ((enable == 1'b1) & (hit == 1'b1))
                      begin

                         next_state = 1 ; 
                         latchnear = 1'b1 ; 
                      end
                      else
                      begin
                         next_state = 0 ; 
                      end 
				    temp_anyhit = 1'b0;
                   end
          1 :
                   begin
                      if (reset == 1'b1)
                      begin

                         if ((enable == 1'b1) & (hit == 1'b1))
                         begin
                            latchnear = 1'b1 ; 
                            next_state = 1 ; 
                         end
                         else
                         begin
                            next_state = 0 ; 
                         end 
                      end
                      else
                      begin

                         if ((enable == 1'b1) & (hit == 1'b1))
                         begin
                            if (tin < t)
                            begin
                               latchnear = 1'b1 ; 
                            end 
                         end 
                         next_state = 1 ; 
                      end 
				    temp_anyhit = 1'b1;
                   end
       endcase 
    end 

 endmodule