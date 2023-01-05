module memory(clk, data_in, data_out, addr, wr_en);
   parameter                   WIDTH=16, SIZE=64;
   localparam                  LOGSIZE=$clog2(SIZE);
   input [WIDTH-1:0]           data_in;
   output logic [WIDTH-1:0]    data_out;
   input [LOGSIZE-1:0]         addr;
   input                       clk, wr_en;
    
   logic [SIZE-1:0][WIDTH-1:0] mem;
    
   always_ff @(posedge clk) begin
      data_out <= mem[addr];
      if (wr_en)
         mem[addr] <= data_in;
   end
endmodule



module control3(clk, reset, input_valid, input_ready, output_ready, output_valid, addr_x, wr_en_x, addr_w, clear_acc, en_acc, en_mult, inc, done);
   parameter M=13, N=16, P=1, addrW=8, addrX=4;
   input clk, reset, input_valid, output_ready, done;
   output logic wr_en_x, clear_acc, en_acc, output_valid, input_ready, en_mult;
   output logic [addrW-1:0] addr_w;
   output logic [addrX-1:0] addr_x;
   output logic signed [31:0] inc;

   always_comb begin
      output_valid = 0;

      if (reset) begin           
         output_valid = 0;
      end
      
      if (inc == (addr_w+3)) begin
         output_valid = 1;
      end
    
      if (done) begin
         output_valid = 0;
      end
   end
   
   always_ff @(posedge clk) begin
      if (reset) begin
         addr_x <= 0;
         wr_en_x <= 1;
         addr_w <= 0;
         clear_acc <= 0;
         en_acc <= 0;
         input_ready <= 1;
         inc <= 0;
         en_mult <= 0;
      end
      else begin
         if (input_valid && input_ready) begin
            wr_en_x <= 1;

            if (addr_x < N-1) begin
               addr_x <= addr_x+1;
               wr_en_x <= 1;
            end
            else if (addr_x == N-1) begin
               wr_en_x <= 0;
               input_ready <= 0;
               addr_w <= 0;
               addr_x <= 0;
               inc <= 0;
               en_mult <= 1;
            end
         end
         else if ((!input_ready) && (!output_valid)) begin
            inc <= inc+1;
            en_acc <= en_mult;
            clear_acc <= 0;

            if (inc < (M*N-(P-1)*N-1)) begin
               if (addr_x < N-1) begin
                  addr_w <= addr_w+1;
                  addr_x <= addr_x+1;
               end
            end

            if ((addr_x == 1) && (inc == addr_w)) begin
               clear_acc <= 1;
            end
            else begin
               clear_acc <= 0;
            end

            if (inc == (M*N-(P-1)*N+2)) begin
               inc <= M*N-(P-1)*N+2;
            end

            if (done && (inc < (M*N-(P-1)*N+2))) begin
               addr_x <= 0;
               addr_w <= (addr_w+1)+N*(P-1);
               inc <= (addr_w+1)+N*(P-1);
            end

            if (done && (inc == (M*N-(P-1)*N+2))) begin
               input_ready <= 1;
               clear_acc <= 0;
               en_acc <= 0;
               en_mult <= 0;
               addr_x <= 0;
               addr_w <= 0;
               inc <= 0;
               wr_en_x <= 1;
            end
         end
      end
   end
endmodule
