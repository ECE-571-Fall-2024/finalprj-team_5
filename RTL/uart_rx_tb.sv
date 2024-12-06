`timescale 1ns/1ns

`include "uart_if.sv"

module uart_rx_tb();
	localparam DATA_WIDTH = 8;
	localparam BAUD_RATE  = 9600;
	localparam CLK_FREQ   = 100_000_000;

	uart_if #(DATA_WIDTH) rxif(.*);
	logic clk, rstn;
	
//clock generation
localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;

initial begin
	clk = 1'b0;
end

always #(CLK_PERIOD / 2) begin
	clk = ~ clk;
end

// DUT Instantiation
uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) DUT(.rxif(rxif), .clk(clk), .rstn(rstn));

// test case 
localparam LB_DATA_WIDTH = $clog2(DATA_WIDTH);
localparam PULSE_WIDTH   = CLK_FREQ / BAUD_RATE;

logic [DATA_WIDTH -1 : 0] data     = 0;
int			  success  = 1; 
int			  end_flag = 0; 
int			  index    = 0;

initial begin
	rxif.sig    = 1;
	rxif.ready  = 0;
	rstn        = 0;

	repeat (100) @(posedge clk);
	rstn = 1;

	while(!end_flag) begin
	  for(index = -1; index <= DATA_WIDTH; index++) begin
	    case(index)
	    -1 :	rxif.sig = 0;
	    DATA_WIDTH: rxif.sig = 1;
	    default:	rxif.sig = data[index];
	    endcase
	    
	    repeat(PULSE_WIDTH) @(posedge clk);
	  end
	  
	  while(!rxif.valid) @(posedge clk);
	  $display("Data Transmitted:", data, ", Data Received:", rxif.data);
	  if(data != rxif.data) begin
	 	success = 0;
	  end
	
	  repeat($urandom_range(PULSE_WIDTH/2, PULSE_WIDTH)) @(posedge clk);
	  rxif.ready = 1;
	  repeat(1) @(posedge clk);
	  rxif.ready = 0;
	  
	  if(data == 8'b1111_1111) begin
		end_flag = 1;
	  end
	  else begin
		data = data+1;
	  end
	end

	if(success) begin
		$display("Transmitted Data is matched with Received Data");
	end
	else begin
		$display("Transmitted Data is not matched with Received Data");
	end

	$finish;
end


endmodule
