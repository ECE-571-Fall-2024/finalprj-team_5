interface uart_if
  #(parameter
    DATA_WIDTH = 8) (         
    input logic clk,          
    input logic rstn          
);

   logic sig, valid, ready;
   logic [DATA_WIDTH-1:0] data;
 

   modport tx(output sig, ready,
              input  data, valid
              );

   modport rx(input  sig, ready,
              output data, valid
              );

endinterface


