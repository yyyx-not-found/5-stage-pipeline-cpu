TEST_DIR = ../../testcase/cpu_test
INSTRUCTION_FILE = instructions.bin
DATA_FILE = data.bin

compile: cpu.v test_cpu.v alu.v register.v InstructionRAM.v MainMemory.v
	iverilog -o CPU test_cpu.v

test: cpu.v test_cpu.v alu.v register.v InstructionRAM.v MainMemory.v
	iverilog -o CPU test_cpu.v
	vvp CPU

my_test:
	cp $(TEST_DIR)/my_machine_code.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/MY_DATA_RAM.txt

test1:
	cp $(TEST_DIR)/machine_code1.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM1.txt

test2:
	cp $(TEST_DIR)/machine_code2.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM2.txt

test3:
	cp $(TEST_DIR)/machine_code3.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM3.txt

test4:
	cp $(TEST_DIR)/machine_code4.txt $(INSTRUCTION_FILE)
	vvp CPU	
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM4.txt

test5:
	cp $(TEST_DIR)/machine_code5.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM5.txt

test6:
	cp $(TEST_DIR)/machine_code6.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM6.txt

test7:
	cp $(TEST_DIR)/machine_code7.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM7.txt

test8:
	cp $(TEST_DIR)/machine_code8.txt $(INSTRUCTION_FILE)
	vvp CPU
	cmp $(DATA_FILE) $(TEST_DIR)/DATA_RAM8.txt

clean:
	rm -f test.vcd CPU


