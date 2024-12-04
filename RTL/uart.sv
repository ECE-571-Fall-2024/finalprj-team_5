
`include "uart_if.sv"


module uart( uart_if.rx   rxif,
    uart_if.tx   txif,
    input logic  clk,
    input logic  rstn);	
	
parameter DATA_WIDTH = 8, 
    BAUD_RATE  = 9600,
    CLK_FREQ   = 100_000_000, PULSE_WIDTH = (CLK_FREQ/BAUD_RATE);

uart_rx 
       #(CLK_FREQ,
	 BAUD_RATE
	)
      receiver
             (
              .clk(clk),
	      .rstn(rstn),
	      .rxif(rxif)
             );


uart_tx 
        #(CLK_FREQ,
	 BAUD_RATE
	)
      transmitter			 
               (               
                .clk(clk),
		.rstn(rstn),
		.txif(txif)		
               );

endmodule











