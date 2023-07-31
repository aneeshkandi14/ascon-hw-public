#!/bin/bash  

iverilog -o test -c program_files.txt 
./test >> testcases.txt
# gtkwave test.vcd