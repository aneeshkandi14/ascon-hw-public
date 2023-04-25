`timescale 1ns/1ns
module test_tb;

    parameter k = 128;            // Key size
    parameter r = 64;            // Rate
    parameter a = 12;             // Initialization round no.
    parameter b = 6;              // Intermediate round no.
    parameter l = 40;             // Length of associated data
    parameter y = 40;             // Length of Plain Text
    parameter TI = 1;
    parameter FP = 1;

    reg       clk = 0;
    reg       rst;
    reg [2:0] keyxSI;
    reg [2:0] noncexSI;
    reg [2:0] associated_dataxSI;
    reg [2:0] plain_textxSI;
    reg       encryption_startxSI;
    reg       decryption_startxSI = 0;
    reg [6:0] rxSI;
    integer ctr = 0;
    reg [y-1:0] cipher_text;
    reg [127:0] tag;

    wire  cipher_textxSO;
    wire  tagxSO;
    wire  encryption_readyxSO;
    wire  decryption_readyxSO;
    integer check_time;

    parameter KEY = 'h7540e9d968c534f3347c799342ed1264;
    parameter NONCE = 'h3f0a465dfb478805be644a2627f7c7e8;
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
        decryption_startxSI,
        rxSI,
        cipher_textxSO,
        tagxSO,       
        encryption_readyxSO,
        decryption_readyxSO     //
    );

    // Clock Generator of 10ns
    always #10 clk = ~clk;

    task write;
    input [127:0] rd, i, key, nonce, ass_data, pt; 
    begin
        @(posedge clk);
        {rxSI,keyxSI[2:1],associated_dataxSI[2:1],plain_textxSI[2:1],noncexSI[2:1]} = rd;
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
        #15
        rst = 0;
        ctr = 0;
        repeat(k) begin
            write($random, ctr, KEY, NONCE, AD, PT);
            ctr = ctr + 1;
        end
        ctr = 0;
        encryption_startxSI = 1;
        check_time = $time;
        #5
        $display("Key:\t%h", uut.key);
        $display("Nonce:\t%h", uut.nonce);
        $display("AD:\t%h", uut.associated_data);
        $display("PT:\t%h", uut.plain_text);
        #45
        encryption_startxSI = 0;
    end

    always @(*) begin
        if(encryption_readyxSO & !decryption_startxSI) begin
            check_time = $time - check_time;
            $display("Encryption Done! It took%d clock cycles", check_time/20);
            #40
            repeat(k) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("CT:\t%h", cipher_text);
            $display("Tag:\t%h", tag);
            decryption_startxSI = 1;
            check_time = $time;
        end

        if (decryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Decryption Done! It took%d clock cycles", check_time/20);
            #40
            $display("PT:\t%h", uut.dec_plain_text);
            $display("Tag:\t%h", uut.dec_tag);
            $finish;
        end
    end
endmodule