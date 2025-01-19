VcdFile  = test
ElfFile  = run

test: alu.v test_alu.v
	iverilog -o ALU test_alu.v
	vvp ALU

sim:
	gtkwave $(VcdFile).vcd

clean:
	rm -f ALU
	rm -rf *vcd *.out

