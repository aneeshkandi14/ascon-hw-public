`timescale 1ns/1ns
module test_tb;

    parameter k = 128;            // Key size
    parameter r = 64;            // Rate
    parameter a = 12;             // Initialization round no.
    parameter b = 6;              // Intermediate round no.
    parameter l = 40;             // Length of associated data
    parameter y = 96;             // Length of Plain Text
    parameter TI = 0;
    parameter FP = 0;

    parameter PERIOD = 20;          // Clock frequency
    parameter max = (k>=y && k>=l)? k: ((y>=l)? y: l);

    reg       clk = 0;
    reg       rst;
    reg [4:0] keyxSI;
    reg [4:0] noncexSI;
    reg [4:0] associated_dataxSI;
    reg [4:0] plain_textxSI;
    reg       encryption_startxSI;
    reg       decryption_startxSI = 0;
    reg [13:0] r_64xSI;
    reg [2:0] r_128xSI;
    reg [2:0] r_ptxSI;
    integer ctr = 0;
    reg [y-1:0] cipher_text, plain_text;
    reg [127:0] tag, dec_tag;

    wire  cipher_textxSO, plain_textxS0;
    wire  tagxSO, dec_tagxSO;
    wire  encryption_readyxSO;
    wire  decryption_readyxSO;
    wire  message_authentication;
    integer check_time;
    integer flag = 0;

    parameter KEY = 'h5362006eff0b33bc8bb9950abdb242fc;
    parameter NONCE = 'h1ccfafbc6dc738283ca9fe21ce0fccaa;
    parameter AD = 'h4153434f4e;
    parameter PT = 'h48656c6c6f20576f726c6421;

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
        r_64xSI,
        r_128xSI,
        r_ptxSI,
        cipher_textxSO,
        plain_textxS0,
        tagxSO, dec_tagxSO,
        encryption_readyxSO,
        decryption_readyxSO,
        message_authentication
    );

    // Clock Generator of 10ns
    always #(PERIOD) clk = ~clk;

    task write;
    input [max-1:0] rd, i, key, nonce, ass_data, pt; 
    begin
        @(posedge clk);
        {r_128xSI, r_ptxSI, r_64xSI, keyxSI[4:1], associated_dataxSI[4:1], plain_textxSI[4:1], noncexSI[4:1]} = rd;
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

    task read_dec;
    input integer i;
    begin
        @(posedge clk);
        plain_text[i] = plain_textxS0;
        dec_tag[i] = dec_tagxSO;
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
            write({$random, $random}, ctr, KEY, NONCE, AD, PT);
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
        if(encryption_readyxSO & flag == 0) begin
            flag = 1;
            check_time = $time - check_time;
            $display("Encryption Done! It took%d clock cycles", check_time/(2*PERIOD));
            #(4*PERIOD)
            repeat(max) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("CT:\t%h", cipher_text);
            $display("Tag:\t%h", tag);
            decryption_startxSI = 1;
            check_time = $time;
            ctr = 0;
            #(5*PERIOD)
            decryption_startxSI = 0;
        end

        if (decryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Decryption Done! It took%d clock cycles", check_time/(2*PERIOD));
            #(4*PERIOD)
            repeat(max) begin
                read_dec(ctr);
                ctr = ctr + 1;
            end
            $display("PT:\t%h", plain_text);
            $display("Tag:\t%h", dec_tag);
            $display("Is message authenticated?:\t%b", message_authentication);
            $finish;
        end
    end
endmodule