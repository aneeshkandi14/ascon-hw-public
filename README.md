# ASCON Hardware
This repository contains accompanying HDL codes for the paper **Hardware Implementation of ASCON**.

## Contents of the Repository
- Verilog codes for ASCON (HDL)
- SBox implementations for Threshold (sbox)
- Testbench for testing the implementation (testbench)

## Hierarchy of Verilog Modules
- `Ascon` is the top module containing the bit-wise wrapper and unwrapper modules. The unwrapper sends the data to the module `FC`. Source: `hdl/ascon.v`
- `FC` module connects to the subsequent appropriate modules according to the parameters - `TI` and `FA`. If parameter `FA` is set to 1, then the process is triplicated, followed by the majority operation. The respective threshold processes are called if the TI parameter is set to 1. Source: `hdl/fault_countermeasures.v`
- `Encryption_ti`, `Decryption_ti`, `Encryption` and `Decryption` modules, called by the `FA` module, contain the ASCON FSM for encryption and decryption with or without threshold. Source: `hdl/encryption/` and `hdl/decryption/`.
- `Permutation_ti` (for threshold) or `Permutation` and `RoundCounter` modules are called by the encryption and decryption modules. The `Permutation` module contains the ASCON Permutation FSM, and `RoundCounter` is a counter used by the permutation process. Source: `hdl/permutation/` and `hdl/roundcounter.v`.
- `roundconstant`, `sub_layer` and `linear_layer` modules are called from the `Permutation` module, which contains the ASCON round constant layer, substitution layer and linear diffusion layer, respectively. Source: `hdl/permutation/`

## Additional Files
- `Hash` and `Hash_ti` modules contain the ASCON Hash FSM. Source: `hdl/hashing/`
- The proposed SBOXes for Threshold. Source: `ascon_sbox_ti/`

 ## Verifying the Code
We have used `iverilog` verilog compiler and `gtkwave` tool for viewing the waveforms. The testbench directory contains the testbench, `test_tb.v`, and a bash script to run the test. Ensure all three files are in the same directory as `ascon.v`, and then run the bash script. The results will be copied to a text file where you can see the working. To view the waveforms, uncomment the line `gtkwave test.vcd` in the `run.sh` file.

The configuration of the ASCON variant can be changed by changing the different parameters in the `test_tb.v` file. The key, nonce, associated_data and plain_text values can also be changed in the same file. 
