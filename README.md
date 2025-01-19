# 5-stage-pipeline-cpu

## Overview
This project implements a 5-stage pipeline CPU as part of the coursework for CSC 3050 at The Chinese University of Hong Kong, Shenzhen. The primary purpose of this project is to demonstrate the design and functionality of a simplified pipelined CPU.

The CPU follows a traditional 5-stage pipeline architecture, including:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)

## Features
- Instruction-level parallelism using pipelining.
- Basic hazard handling, including:
  - Data hazards with forwarding and stalling mechanisms.
  - Control hazards with branch prediction and flushing.
  - Support for a limited instruction set suitable for the project demonstration.
 
## How to Run
1. Clone this repository to your local machine.
2. Compile the project:
   ```
   make compile
   ```
3. Load instructions into `instructions.bin`, then execute the program by
   ```
   make test
   ```
4. After execution, the contents of main memory and the register files will show in terminal. In addition, the main memory will also be dumped in `data.bin`.

## Disclaimer
This project is for educational and demonstration purposes only. Do not use this project for assignments or academic submissions.
