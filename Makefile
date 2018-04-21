SRC_DIR   := src
BUILD_DIR := build
SIM_DIR   := sim

MAKE_BUILD  := $(MAKE) -C $(BUILD_DIR)
MAKE_SIM    := $(MAKE) -C $(SIM_DIR)

include src.mk

XDC_SRC_REL   ?=
VHDL_SRC_REL  ?=
TB_SRC_REL    ?=
BUILD_SRC_REL ?=

export XDC_SRC   := $(abspath $(XDC_SRC_REL))
export VHDL_SRC  := $(abspath $(VHDL_SRC_REL))
export TB_SRC    := $(abspath $(TB_SRC_REL))
export BUILD_SRC := $(abspath $(BUILD_SRC_REL))

export TOP_MODULE := uart
export FPGA_PART  := xc7a35ticsg324-1l

# Must point to the directory where the GHDL Xilinx libraries have been compiled
GHDL_XILINX_UNISIM_DIR = $(HOME)/.local/lib/ghdl/vendors/xilinx-vivado/unisim/v93
export GHDL_OPTIONS += --workdir=work -P$(GHDL_XILINX_UNISIM_DIR) --ieee=synopsys -fexplicit
export VSIM_OPTIONS +=
export XSIM_OPTIONS +=

.PHONY: build program vsim xsim ghdl-gtkwave lint clean

build: TOP_MODULE := uart_loopback
build:
	$(MAKE_BUILD) $@

program: TOP_MODULE := uart_loopback
program:
	$(MAKE_BUILD) $@

vsim:
	$(MAKE_SIM) $@

xsim:
	$(MAKE_SIM) $@

ghdl-gtkwave:
	@echo sdfsdf $(GHDL_OPTIONS)
	$(MAKE_SIM) $@

# Used for sublime text editor linting
lint: $(TB_SRC)
	@xvhdl --2008 $(TB_SRC)

clean:
	rm xvhdl.* 2>/dev/null \
	rm -rf xsim.dir 2>/dev/null
	$(MAKE_BUILD) $@
	$(MAKE_SIM) $@