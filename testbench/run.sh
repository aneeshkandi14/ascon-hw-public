#!/bin/bash  

iverilog -o test -c program_files.txt 
./test
# gtkwave test.vcd