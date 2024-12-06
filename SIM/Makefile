
SIMULATOR = vsim             # Use your simulator here (e.g., vsim for QuestaSim)
RTL_DIR = ../RTL             # Path to the RTL directory
OUTPUT_DIR = ./output        # Simulation output directory
TOP_MODULE = uart_tb_top     # Replace with your top module name
WAVEFORM = waveform.wlf      # Waveform file for QuestaSim

# Source Files
 SRCS = $(RTL_DIR)/uart_rx.sv \
 $(RTL_DIR)/uart_tx.sv \
 $(RTL_DIR)/uart.sv \
 $(RTL_DIR)/uart_if.sv

# Testbenches
TESTBENCH = $(RTL_DIR)/uart_tx_tb.sv \
            $(RTL_DIR)/uart_rx_tb.sv

# Targets
.PHONY: all compile simulate clean

all: simulate

#  Compile RTL and testbench
compile:
$(SIMULATOR) -c -do
	"vlib $(OUTPUT_DIR)/work; \
	vmap work $(OUTPUT_DIR)/work; \
	vlog $(SRCS) $(TESTBENCH)"

## Simulate the design
simulate: compile
$(SIMULATOR) -c -do "vsim $(TOP_MODULE) -l $(OUTPUT_DIR)/simulation.log; \
	run -all; \
	wave -name $(OUTPUT_DIR)/$(WAVEFORM); \
	exit;"
#Clean output files
clean:
	rm -rf $(OUTPUT_DIR)/work $(OUTPUT_DIR)/*.log $(OUTPUT_DIR)/*.wlf												
