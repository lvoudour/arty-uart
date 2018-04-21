TOP_MODULE ?=
FPGA_PART  ?=
XDC_SRC    ?=
BUILD_SRC  ?=

BITSTREAM_DIR := bit
BITSTREAM := $(BITSTREAM_DIR)/$(TOP_MODULE).bit

.PHONY: build program clean

build: $(BUILD_SRC) $(XDC_SRC)
	vivado -nolog -nojournal -mode batch -source build.tcl -tclargs "$(BUILD_SRC)" "$(XDC_SRC)" $(TOP_MODULE) $(FPGA_PART)

program: $(BITSTREAM)
	vivado -nolog -nojournal -mode batch -source program.tcl -tclargs $(TOP_MODULE)

clean:
	rm *.jou *pb *.log *.wdb *webtalk* 2>/dev/null \
	rm -rf xsim.dir .Xil 2>/dev/null