TOP_MODULE   ?=
TB_SRC       ?=
VSIM_OPTIONS ?=
XSIM_OPTIONS ?=
GHDL_OPTIONS ?=

.PHONY: vsim xsim ghdl-gtkwave clean

vsim: $(TB_SRC)
	vsim $(VSIM_OPTIONS) -do 'do $@.tcl "$(TB_SRC)" $(TOP_MODULE)'

xsim: $(TB_SRC)
	xvhdl --2008 $(TB_SRC)
	xelab -debug typical -s top tb_$(TOP_MODULE)
	xsim $(XSIM_OPTIONS) -t xsim.tcl top -gui

ghdl-gtkwave: $(TB_SRC)
	@echo AaAsasA $(GHDL_OPTIONS)
	test -e work || mkdir work
	ghdl -a $(GHDL_OPTIONS) $(TB_SRC)
	ghdl -e $(GHDL_OPTIONS) tb_$(TOP_MODULE)
	ghdl -r $(GHDL_OPTIONS) tb_$(TOP_MODULE) --stop-time=10us --wave=work/wavedump.ghw
	gtkwave work/wavedump.ghw

clean:
	rm transcript *.wlf modelsim.ini *.log *.pb *.jou webtalk*.* *.wdb 2>/dev/null \
	rm -rf xsim.dir work .Xil *.o 2>/dev/null