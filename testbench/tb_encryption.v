`timescale 1ns/1ns
module tb_encryption;

    parameter k = 128;            // Key size
    parameter r = 64;            // Rate
    parameter a = 12;             // Initialization round no.
    parameter b = 6;              // Intermediate round no.
    parameter l = 40;             // Length of associated data
    parameter y = 40;             // Length of Plain Text
    parameter TI = 1;
    parameter FP = 1;

    parameter PERIOD = 20;          // Clock frequency
    parameter max = (k>y && k>l)? k: ((y>l)? y: l);

    reg       clk = 0;
    reg       rst;
    reg [2:0] keyxSI;
    reg [2:0] noncexSI;
    reg [2:0] associated_dataxSI;
    reg [2:0] plain_textxSI;
    reg       encryption_startxSI;
    reg [6:0] r_64xSI;
    reg       r_128xSI;
    reg       r_ptxSI;
    integer ctr = 0;
    reg [y-1:0] cipher_text;
    reg [127:0] tag;

    wire  cipher_textxSO;
    wire  tagxSO;
    wire  encryption_readyxSO;
    integer check_time;

    parameter KEY = 'h2db083053e848cefa30007336c47a5a1;
    parameter NONCE = 'h3f3607dbce3503ba84f5843d623de056;
    parameter AD = 'h4153434f4e;
    parameter PT = 'h6173636f6e;

    Ascon #(
    k,r,a,b,l,y,TI,FP
    ) uut (
        clk,
        rst,
        keyxSI,
        noncexSI,
        associated_dataxSI,
        plain_textxSI,
        encryption_startxSI,
        r_64xSI,
        r_128xSI,
        r_ptxSI,
        cipher_textxSO,
        tagxSO,
        encryption_readyxSO
    );

    // Clock Generator of 10ns
    always #(PERIOD) clk = ~clk;

    task write;
    input [max-1:0] rd, i, key, nonce, ass_data, pt; 
    begin
        @(posedge clk);
        {r_128xSI, r_ptxSI, r_64xSI, keyxSI[2:1], associated_dataxSI[2:1], plain_textxSI[2:1], noncexSI[2:1]} = rd;
        keyxSI[0] = key[k-1-i];
        noncexSI[0] = nonce[127-i];
        plain_textxSI[0] = pt[y-1-i];
        associated_dataxSI[0] = ass_data[l-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        cipher_text[i] = cipher_textxSO;
        tag[i] = tagxSO;
    end
    endtask

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        $display("Start!");
        rst = 1;
        #(1.5*PERIOD)
        rst = 0;
        ctr = 0;
        repeat(max) begin
            write($random, ctr, KEY, NONCE, AD, PT);
            ctr = ctr + 1;
        end
        ctr = 0;
        encryption_startxSI = 1;
        check_time = $time;
        #(0.5*PERIOD)
        $display("Key:\t%h", uut.key);
        $display("Nonce:\t%h", uut.nonce);
        $display("AD:\t%h", uut.associated_data);
        $display("PT:\t%h", uut.plain_text);
        #(4.5*PERIOD)
        encryption_startxSI = 0;
    end

    always @(*) begin
        if(encryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Encryption Done! It took%d clock cycles", check_time/(2*PERIOD));
            #(4*PERIOD)
            repeat(max) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("CT:\t%h", cipher_text);
            $display("Tag:\t%h", tag);
            $finish;
        end
    end
endmodule