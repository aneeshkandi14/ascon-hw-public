`timescale 1ns/1ns
module tb_hash;

    // parameter k = 0;
    // parameter r = 64;
    // parameter a = 12;
    // parameter b = 12;
    // parameter h = 256;
    // parameter l = 256;
    // parameter y = 80;
    // parameter TI = 1;
    // parameter FP = 0;

    parameter PERIOD = 20;          // Clock frequency
    parameter max = (`h>=`y && `h>=`l)? `h: ((`y>=`l)? `y: `l);

    reg       clk = 0;
    reg       rst;
    reg [2:0] messagexSI;
    reg       startxSI = 0;
    reg [6:0] r_64xSI;
    reg       r_faultxSI;
    integer ctr = 0;
    reg [`l-1:0] hash_text;

    wire  hash_textxSO;
    wire  readyxSO;
    integer check_time;

    // parameter MESSAGE = 'h656e6372797074696f6e;

    Ascon #(
        `r,`a,`b,`h,`l,`y,`TI,`FP
    ) uut (
        clk,
        rst,
        messagexSI,
        startxSI,
        r_64xSI,
        r_faultxSI,

        hash_textxSO,
        readyxSO //
    );

    // Clock Generator of 10ns
    always #(PERIOD) clk = ~clk;

    task write;
    input [max-1:0] rd, i, mes; 
    begin
        @(posedge clk);
        {r_faultxSI, r_64xSI, messagexSI[2:1]} = rd;
        messagexSI[0] = mes[`y-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        hash_text[i] = hash_textxSO;
    end
    endtask

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        $display("Start!");
        rst = 1;
        #(2*PERIOD)
        rst = 0;
        ctr = 0;
        repeat(max) begin
            write($random, ctr, `MESSAGE);
            ctr = ctr + 1;
        end
        ctr = 0;
        startxSI = 1;
        check_time = $time;
        #(0.5*PERIOD)
        $display("Message:\t%h", uut.message);
        #(4.5*PERIOD)
        startxSI = 0;
    end

    always @(*) begin
        if(readyxSO) begin
            check_time = $time - check_time;
            $display("Hashing Done! It took%d clock cycles", check_time/(2*PERIOD));
            #(4*PERIOD)
            repeat(max) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("Hash:\t%h", hash_text);
            $finish;
        end
    end
endmodule