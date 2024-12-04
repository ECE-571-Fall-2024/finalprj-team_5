
`include "uart_if.sv"


module uart( uart_if.rx   rxif,
    uart_if.tx   txif,
    input logic  clk,
    input logic  rst);	
	
parameter DATA_WIDTH = 8, 
    BAUD_RATE  = 19200,
    CLK_FREQ   = 50000000, CLOCK_DIVIDE = (CLK_FREQ/BAUD_RATE);

uart_rx 
       #(CLK_FREQ,
	 BAUD_RATE
	)
      receiver
             (
              .clk(clk),
	      .rst(rst),
	      .rxif(rxif)
             );


uart_tx 
        #(CLK_FREQ,
	 BAUD_RATE
	)
      transmitter			 
               (               
                .clk(clk),
		.rst(rst),
		.txif(txif)		
               );

endmodule











