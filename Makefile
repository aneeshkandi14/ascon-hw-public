GTK_ENABLED = $(if $(filter yes,$(GTK)),1,0)

default:
	@echo "To compile and simulate (x), run make x"
	@echo "x : encryption, decryption, ascon, hash"
	@echo "Default variants: Ascon-128, Ascon-Hash. Can be changed in run.py file"
	@echo "Default protection configuration: TI = 0; FP = 0. Can be changed in run.py file"

ascon:
	@echo "Running ascon encryption + decryption testcase"
	@python3 run.py 'aead'
	@cd testbench && \
	iverilog -o test -c program_files.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> output.txt; \
		gtkwave test.vcd; \
	else \
		./test >> output.txt; \
	fi

encryption:
	@echo "Running ascon encryption testcase"
	@python3 run.py 'aead'
	@cd testbench && \
	iverilog -o test -c program_files_enc.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> output.txt; \
		gtkwave test.vcd; \
	else \
		./test >> output.txt; \
	fi

decryption:
	@echo "Running ascon decryption testcase"
	@python3 run.py 'aead'
	@cd testbench && \
	iverilog -o test -c program_files_dec.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> output.txt; \
		gtkwave test.vcd; \
	else \
		./test >> output.txt; \
	fi


hash:
	@echo "Running ascon hash testcase"
	@python3 run.py 'hash'
	@cd testbench && \
	iverilog -o test -c program_files_hash.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> output.txt; \
		gtkwave test.vcd; \
	else \
		./test >> output.txt; \
	fi

clean:
	@echo "Removing test files"
	@rm -rf testbench/test testbench/test.vcd