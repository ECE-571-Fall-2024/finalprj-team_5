



`include "uart_if.sv"

module uart_rx
  #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE  = 9600,
    CLK_FREQ   = 100_000_000,
    PULSE_WIDTH = (CLK_FREQ/BAUD_RATE))
    (uart_if.rx  rxif,
    input logic clk,
    input logic rstn);

    localparam LB_DATA_WIDTH = $clog2(DATA_WIDTH), LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH);

typedef enum logic [4:0] {
S0 = 5'b00000, S1 = 5'b00001, S2 = 5'b00010, S3 = 5'b00011, 
S4 = 5'b00100, S5 = 5'b00101, S6 = 5'b00110, S7 = 5'b01000, 
S8 = 5'b01001, S9 = 5'b01010, S10 = 5'b01100, S11 = 5'b10000,
S12 = 5'b10001, S13 = 5'b10010, S14 = 5'b10100, S15 = 5'b11000  
 } st;

st N_S;

typedef enum logic [1:0] { STT_DATA, STT_STOP, STT_WAIT } states;
/*
function logic majority5(input [4:0] val);
    int ones_count = $countones(val);
    if (ones_count >= 3)
        return 1;
    else
        return 0;
endfunction
*/

function logic high(input [4:0] val);
      case(val)
        S0, S1, S2, S3, S4, S5, S6, S7, S8,
        S9, S10, S11, S12, S13, S14, S15: high = 0;
        default:  high = 1;
      endcase

   endfunction
    

   logic [1:0] scnt;
   logic [4:0] sig_q;
   logic       sig_r;

   always_ff @(posedge clk) begin
      if(rstn) begin
	sig_q <= {rxif.sig, sig_q[4:1]}; // Shift the signal queue
	sig_r <= high(sig_q);       // Apply majority voting
	scnt <= (scnt == 0) ? 1 : 0; end
      else begin
        scnt <= 0;
        sig_q        <= 5'b11111;
        sig_r        <= 1;
    end
    end

//typedef enum logic [1:0] { STT_DATA, STT_STOP, STT_WAIT } states;

states state;

   logic [DATA_WIDTH-1:0]   data_tmp_r;
   logic [LB_DATA_WIDTH:0]  dcnt;
   logic [LB_PULSE_WIDTH:0] clk_cnt;
   logic                    rx_done;

   always_ff @(posedge clk) begin
      if(!rstn) begin
         state      <= STT_WAIT;
         data_tmp_r <= 0;
         dcnt   <= 0;
         clk_cnt    <= 0;
      end
      else begin
	case(state)
	   STT_DATA: begin
              if(clk_cnt > 0) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else begin
                 data_tmp_r <= {sig_r, data_tmp_r[DATA_WIDTH-1:1]};
                 clk_cnt    <= PULSE_WIDTH;

                 if(dcnt == DATA_WIDTH - 1) begin
                    state <= STT_STOP;
                 end
                 else begin
                    dcnt <= dcnt + 1;
                 end
              end
           end

           STT_STOP: begin
              if(clk_cnt > 0) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else if(sig_r) begin
                 state <= STT_WAIT;
              end
           end

           STT_WAIT: begin
              if(sig_r == 0) begin
                 clk_cnt  <= (PULSE_WIDTH*1.5);
                 dcnt <= 0;
                 state    <= STT_DATA;
              end
           end

           default: begin
              state <= STT_WAIT;
           end
         endcase
      end
   end

   assign rx_done = (state == STT_STOP) && (clk_cnt == 0);


 
   logic [DATA_WIDTH-1:0] data_r;
   logic                  valid_r;

   always_ff @(posedge clk) begin
      if(!rstn) begin
         data_r  <= 0;
         valid_r <= 0;
      end
      else if(rx_done && !valid_r) begin
         valid_r <= 1;
         data_r  <= data_tmp_r;
      end
      else if(valid_r && rxif.ready) begin
         valid_r <= 0;
      end
   end

   assign rxif.data  = data_r;
   assign rxif.valid = valid_r;



endmodule






