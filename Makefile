GTK_ENABLED = $(if $(filter yes,$(GTK)),1,0)

default:
	@echo "To compile and simulate (x), run make x"
	@echo "x : encryption, decryption, ascon, hash"

ascon:
	@echo "Running ascon encryption + decryption testcase"
	@python3 run.py
	@cd testbench && \
	iverilog -o test -c program_files.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> testcases.txt; \
		gtkwave test.vcd; \
	else \
		./test >> testcases.txt; \
	fi

encryption:
	@echo "Running ascon encryption testcase"
	@python3 run.py
	@cd testbench && \
	iverilog -o test -c program_files_enc.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> testcases.txt; \
		gtkwave test.vcd; \
	else \
		./test >> testcases.txt; \
	fi

decryption:
	@echo "Running ascon decryption testcase"
	@python3 run.py
	@cd testbench && \
	iverilog -o test -c program_files_dec.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> testcases.txt; \
		gtkwave test.vcd; \
	else \
		./test >> testcases.txt; \
	fi


hash:
	@echo "Running ascon hash testcase"
	@python3 run.py
	@cd testbench && \
	iverilog -o test -c program_files_hash.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test >> testcases.txt; \
		gtkwave test.vcd; \
	else \
		./test >> testcases.txt; \
	fi

clean:
	@echo "Removing test files"
	@rm -rf testbench/test testbench/test.vcd