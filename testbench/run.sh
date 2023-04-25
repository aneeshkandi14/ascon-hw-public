#!/bin/bash  

iverilog -o test -c program_files.txt 
./test >> verilog_output.txt
# gtkwave test.vcd