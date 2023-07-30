`timescale 1ns/1ns
module tb_decryption;

    parameter k = 128;            // Key size
    parameter r = 64;            // Rate
    parameter a = 12;             // Initialization round no.
    parameter b = 6;              // Intermediate round no.
    parameter l = 40;             // Length of associated data
    parameter y = 80;             // Length of Plain Text
    parameter TI = 1;
    parameter FP = 0;

    parameter PERIOD = 20;          // Clock frequency
    parameter max = (k>y && k>l)? k: ((y>l)? y: l);

    reg       clk = 0;
    reg       rst;
    reg [2:0] keyxSI;
    reg [2:0] noncexSI;
    reg [2:0] associated_dataxSI;
    reg [2:0] cipher_textxSI;
    reg       decryption_startxSI;
    reg [6:0] r_64xSI;
    reg       r_128xSI;
    reg       r_ptxSI;
    integer ctr = 0;
    reg [y-1:0] plain_text;
    reg [127:0] tag;

    wire  plain_textxSO;
    wire  tagxSO;
    wire  decryption_readyxSO;
    integer check_time;

    parameter KEY = 'h2db083053e848cefa30007336c47a5a1;
    parameter NONCE = 'h3f3607dbce3503ba84f5843d623de056;
    parameter AD = 'h4153434f4e;
    parameter CT = 'h87a59a2ea49b233259e3;

    Ascon #(
    k,r,a,b,l,y,TI,FP
    ) uut (
        clk,
        rst,
        keyxSI,
        noncexSI,
        associated_dataxSI,
        cipher_textxSI,
        decryption_startxSI,
        r_64xSI,
        r_128xSI,
        r_ptxSI,
        plain_textxSO,
        tagxSO,
        decryption_readyxSO
    );

    // Clock Generator of 10ns
    always #(PERIOD) clk = ~clk;

    task write;
    input [max-1:0] rd, i, key, nonce, ass_data, ct; 
    begin
        @(posedge clk);
        {r_128xSI, r_ptxSI, r_64xSI, keyxSI[2:1], associated_dataxSI[2:1], cipher_textxSI[2:1], noncexSI[2:1]} = rd;
        keyxSI[0] = key[k-1-i];
        noncexSI[0] = nonce[127-i];
        cipher_textxSI[0] = ct[y-1-i];
        associated_dataxSI[0] = ass_data[l-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        plain_text[i] = plain_textxSO;
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
            write($random, ctr, KEY, NONCE, AD, CT);
            ctr = ctr + 1;
        end
        ctr = 0;
        decryption_startxSI = 1;
        check_time = $time;
        #(0.5*PERIOD)
        $display("Key:\t%h", uut.key);
        $display("Nonce:\t%h", uut.nonce);
        $display("AD:\t%h", uut.associated_data);
        $display("CT:\t%h", uut.cipher_text);
        #(4.5*PERIOD)
        decryption_startxSI = 0;
    end

    always @(*) begin
        if(decryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Decryption Done! It took%d clock cycles", check_time/(2*PERIOD));
            #(4*PERIOD)
            repeat(max) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("PT:\t%h", plain_text);
            $display("Tag:\t%h", tag);
            $finish;
        end
    end
endmodule