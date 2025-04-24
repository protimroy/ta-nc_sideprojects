module jtag_uart_0_drom_module (
                                 // inputs:
                                  clk,
                                  incr_addr,
                                  reset_n,

                                 // outputs:
                                  new_rom,
                                  num_bytes,
                                  q,
                                  safe
                               )
;

  parameter POLL_RATE = 100;


  output           new_rom;
  output  [ 31: 0] num_bytes;
  output  [  7: 0] q;
  output           safe;
  input            clk;
  input            incr_addr;
  input            reset_n;

  reg     [ 11: 0] address;
  reg              d1_pre;
  reg              d2_pre;
  reg              d3_pre;
  reg              d4_pre;
  reg              d5_pre;
  reg              d6_pre;
  reg              d7_pre;
  reg              d8_pre;
  reg              d9_pre;
  reg     [  7: 0] mem_array [2047: 0];
  reg     [ 31: 0] mutex [  1: 0];
  reg              new_rom;
  wire    [ 31: 0] num_bytes;
  reg              pre;
  wire    [  7: 0] q;
  wire             safe;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  assign q = mem_array[address];
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
        begin
          d1_pre <= 0;
          d2_pre <= 0;
          d3_pre <= 0;
          d4_pre <= 0;
          d5_pre <= 0;
          d6_pre <= 0;
          d7_pre <= 0;
          d8_pre <= 0;
          d9_pre <= 0;
          new_rom <= 0;
        end
      else 
        begin
          d1_pre <= pre;
          d2_pre <= d1_pre;
          d3_pre <= d2_pre;
          d4_pre <= d3_pre;
          d5_pre <= d4_pre;
          d6_pre <= d5_pre;
          d7_pre <= d6_pre;
          d8_pre <= d7_pre;
          d9_pre <= d8_pre;
          new_rom <= d9_pre;
        end
    end



   assign     num_bytes = mutex[1];
                   reg        safe_delay;
   reg [31:0] poll_count;
   reg [31:0] mutex_handle;
   wire       interactive = 1'b0 ; // '
   assign     safe = (address < mutex[1]);

   initial poll_count = POLL_RATE;

   always @(posedge clk or negedge reset_n) begin
      if (reset_n !== 1) begin
         safe_delay <= 0;
      end else begin
         safe_delay <= safe;
      end
   end // safe_delay

   always @(posedge clk or negedge reset_n) begin
      if (reset_n !== 1) begin  // dont worry about null _stream.dat file
         address <= 0;
         mem_array[0] <= 0;
         mutex[0] <= 0;
         mutex[1] <= 0;
         pre <= 0;
      end else begin            // deal with the non-reset case
         pre <= 0;
         if (incr_addr && safe) address <= address + 1;
         if (mutex[0] && !safe && safe_delay) begin
            // and blast the mutex after falling edge of safe if interactive
            if (interactive) begin
               mutex_handle = $fopen ("jtag_uart_0_input_mutex.dat");
               $fdisplay (mutex_handle, "0");
               $fclose (mutex_handle);
               // $display ($stime, "\t%m:\n\t\tMutex cleared!");
            end else begin
               // sleep until next reset, do not bash mutex.
               wait (!reset_n);
            end
         end // OK to bash mutex.
         if (poll_count < POLL_RATE) begin // wait
            poll_count = poll_count + 1;
         end else begin         // do the interesting stuff.
            poll_count = 0;
            $readmemh ("jtag_uart_0_input_mutex.dat", mutex);
            if (mutex[0] && !safe) begin
            // read stream into mem_array after current characters are gone!
               // save mutex[0] value to compare to address (generates 'safe')
               mutex[1] <= mutex[0];
               // $display ($stime, "\t%m:\n\t\tMutex hit: Trying to read %d bytes...", mutex[0]);
               $readmemb("jtag_uart_0_input_stream.dat", mem_array);
               // bash address and send pulse outside to send the char:
               address <= 0;
               pre <= -1;
            end // else mutex miss...
         end // poll_count
      end // reset
   end // posedge clk


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule