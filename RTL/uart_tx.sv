`include "uart_if.sv"

module uart_tx
  #(parameter
    // Configuration parameters for the UART transmitter
    DATA_WIDTH = 8,         // Data width (in bits) for transmission
    BAUD_RATE  = 115200,    // Baud rate for the transmission
    CLK_FREQ   = 100_000_000, // Clock frequency for the system

    // Local parameters calculated based on above parameters
    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH),          // Log base 2 of data width
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE,       // Number of clock cycles per baud bit
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH),        // Log base 2 of pulse width
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2             // Half the pulse width (for stop bit timing)
   )
   (
    input  logic       clk,       // System clock input
    input  logic       rstn,      // Active-low reset input
     uart_if.tx  txif       // UART interface signals
  );

   // Define state machine states
   typedef enum logic [1:0] { 
     STT_WAIT = 2'b00,   // Wait for valid data to be transmitted
     STT_DATA = 2'b01,   // Transmit data bits
     STT_STOP = 2'b10    // Transmit stop bit (end of transmission)
   } statetype;

   // Internal state and signal registers
   statetype state;                // Current state of the state machine
   logic [DATA_WIDTH-1:0] data_r;  // Register holding the data to be transmitted
   logic sig_r;                    // Signal output for transmitting data bit
   logic ready_r;                  // Indicates when the transmitter is ready to accept new data
   logic [LB_DATA_WIDTH-1:0] data_cnt; // Counter to track the current data bit being transmitted
   logic [LB_PULSE_WIDTH:0] clk_cnt;  // Counter for the baud rate clock cycles

   // Main process for handling UART transmission
   always_ff @(posedge clk) begin
      if (!rstn) begin
         // Reset the state machine and internal signals
         state    <= STT_WAIT;
         sig_r    <= 1'b1;
         data_r   <= {DATA_WIDTH{1'b0}};
         ready_r  <= 1'b1;
         data_cnt <= 0;
         clk_cnt  <= 0;
      end
      else begin
         case(state)
           // STATE: Wait for valid data to start transmission
           STT_WAIT: begin
              if (clk_cnt > 0) begin
                 clk_cnt <= clk_cnt - 1; // Decrement clock counter
              end
              else if (!ready_r) begin
                 ready_r <= 1'b1; // Indicate readiness for new data
              end
              else if (txif.valid) begin
                 // When valid data is ready, start transmission
                 state    <= STT_DATA;
                 sig_r    <= 1'b0;      // Start bit (low)
                 data_r   <= txif.data; // Load the data to be transmitted
                 ready_r  <= 1'b0;      // Not ready until the transmission is complete
                 data_cnt <= 0;         // Start from the first data bit
                 clk_cnt  <= PULSE_WIDTH; // Reset the clock counter
              end
           end

           // STATE: Transmitting data bits
           STT_DATA: begin
              if (clk_cnt > 0) begin
                 clk_cnt <= clk_cnt - 1; // Decrement clock counter
              end
              else begin
                 // Transmit the current data bit
                 sig_r <= data_r[data_cnt]; 
                 clk_cnt <= PULSE_WIDTH; // Reset clock counter for next bit

                 if (data_cnt == DATA_WIDTH - 1) begin
                    // Once all data bits are transmitted, go to the stop bit state
                    state <= STT_STOP;
                 end
                 else begin
                    data_cnt <= data_cnt + 1; // Move to the next bit
                 end
              end
           end

           // STATE: Transmitting stop bit
           STT_STOP: begin
              if (clk_cnt > 0) begin
                 clk_cnt <= clk_cnt - 1; // Decrement clock counter
              end
              else begin
                 // Stop bit is always '1', indicating end of transmission
                 state   <= STT_WAIT;   // Go back to wait state after stop bit
                 sig_r   <= 1'b1;       // Stop bit (high)
                 clk_cnt <= PULSE_WIDTH + HALF_PULSE_WIDTH; // Set stop bit duration
              end
           end

           default: begin
              state <= STT_WAIT; // Default state is to wait for valid data
           end
         endcase
      end
   end

   // Output the signal and ready status to the UART interface
   assign txif.sig   = sig_r;
   assign txif.ready = ready_r;

endmodule

