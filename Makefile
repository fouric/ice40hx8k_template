.PHONY: prepare upload clean tb

PROJECT = example
PCF = example.pcf
SRCS = $(filter-out $(PROJECT).v, $(filter-out %_tb.v, $(wildcard *.v)))
TBS = $(wildcard *_tb.v)
VCDS = $(TBS:_tb.v=.vcd)

$(display $(SRCS))

upload: $(PROJECT).bin
	sudo iceprog $(PROJECT).bin
sram: $(PROJECT).bin
	sudo iceprog -S $(PROJECT).bin
	icetime -p $(PCF) -P ct256 -d hx8k -t $(PROJECT).txt

$(PROJECT).bin: $(PROJECT).txt
	icepack $(PROJECT).txt $(PROJECT).bin

$(PROJECT).txt: $(PROJECT).blif
	arachne-pnr -d 8k -p $(PCF) -o $(PROJECT).txt $(PROJECT).blif

$(PROJECT).blif: $(PROJECT).v $(SRCS)
	echo $(SRCS) $(PROJECT).v
	yosys -p "read_verilog $(SRCS) $(PROJECT).v; synth_ice40 -blif $(PROJECT).blif"

clean:
	-rm -f $(PROJECT).bin $(PROJECT).txt $(PROJECT).blif $(VCDS) *.vvp *.vhdl

tb:	$(TBS) $(SRCS) $(VCDS)

%_tb.vvp: %_tb.v %.v
	# $@ is %_tb.aout
	# $? is %_tb.v
	iverilog -o $@ $?

%.vcd: %_tb.vvp
	vvp $? -fst && gtkwave $@
%.vhdl: %.v
	iverilog -o $@ $? -t vhdl

prepare:
	git submodule init
	git submodule update
	cd icestorm;make -j9;sudo make install;cd -
	cd arachne-pnr;make -j9;sudo make install;cd -
	cd yosys;make -j9;sudo make install; cd -
	cd yodl;./configure;cd -
	cd yodl/vhdlpp;make -j9;sudo make install;cd -
	sudo echo 'ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"' >/etc/udev/rules.d/53-lattice-ftdi.rules

upload: example.bin
	sudo iceprog example.bin && rm example.bin

example.bin: example.txt
	icepack example.txt example.bin && rm example.txt

example.txt: example.blif
	arachne-pnr -d 8k -p example.pcf -o example.txt example.blif && rm example.blif

example.blif: example.v
	yosys -p "read_verilog example.v; synth_ice40 -blif example.blif"
