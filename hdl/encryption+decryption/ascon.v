module Ascon #(
    parameter k = 128,            // Key size
    parameter r = 128,            // Rate
    parameter a = 12,             // Initialization round no.
    parameter b = 6,              // Intermediate round no.
    parameter l = 80,            // Length of associated data
    parameter y = 80,             // Length of Plain Text
    parameter TI = 0,              // 1 for Yes; else No
    parameter FP = 0               // 1 for Yes; else No
)(
    input       clk,
    input       rst,
    input [2:0] keyxSI,
    input [2:0] noncexSI,
    input [2:0] associated_dataxSI,
    input [2:0] plain_textxSI,
    input       encryption_startxSI,
    input       decryption_startxSI,
    input [6:0] rxSI,

    output reg  cipher_textxSO,
    // output reg  plain_textxS0,
    output reg  tagxSO,       
    output      encryption_readyxSO,
    output      decryption_readyxSO     //
);
    
    reg     [k-1:0]     key,random_key_1,random_key_2;      
    reg     [127:0]     nonce,random_nonce_1,random_nonce_2;
    reg     [l-1:0]     associated_data, random_ad_1, random_ad_2; 
    reg     [y-1:0]     plain_text, random_pt_1, random_pt_2;
    wire    [y-1:0]     dec_plain_text;
    reg     [63:0]      r0,r1,r2,r3,r4,r5,r6;
    reg     [7:0]       i,j;
    wire    [y-1:0]     cipher_text;
    wire    [127:0]     tag, dec_tag;
    wire                ready, encryption_start;
    wire                permutation_ready, permutation_start;

    // Left shift for Inputs
    always @(posedge clk) begin
        if(rst)
            {key,random_key_1,random_key_2,nonce,random_nonce_1,random_nonce_2,random_ad_1,random_ad_2,associated_data,random_pt_1,random_pt_2,plain_text,i,j} <= 0;

        else begin
            if(i < k) begin
                key <= {key[k-2:0], keyxSI[0]}; 
                random_key_1 <= {random_key_1[k-2:0], keyxSI[1]};
                random_key_2 <= {random_key_2[k-1:0], keyxSI[2]};
            end

            if(i < 128) begin
                nonce <= {nonce[126:0], noncexSI[0]};
                random_nonce_1 <= {random_nonce_1[126:0], noncexSI[1]};
                random_nonce_2 <= {random_nonce_2[126:0], noncexSI[2]};
            end

            if(i < l) begin
                associated_data <= {associated_data[l-2:0], associated_dataxSI[0]};
                random_ad_1 <= {random_ad_1[l-2:0], associated_dataxSI[1]};
                random_ad_2 <= {random_ad_2[l-2:0], associated_dataxSI[2]};
            end

            if(i < y) begin
                plain_text <= {plain_text[y-2:0], plain_textxSI[0]};
                random_pt_1 <= {random_pt_1[y-2:0], plain_textxSI[1]};
                random_pt_2 <= {random_pt_2[y-2:0], plain_textxSI[2]};
            end

            if(i < 64) begin
                r0 <= {r0[62:0],rxSI[0]};
                r1 <= {r1[62:0],rxSI[1]};
                r2 <= {r2[62:0],rxSI[2]};
                r3 <= {r3[62:0],rxSI[3]};
                r4 <= {r4[62:0],rxSI[4]};
                r5 <= {r5[62:0],rxSI[5]};
                r6 <= {r6[62:0],rxSI[6]};
            end

            if(i<130)
                i <= i+1;
        end
    end

    assign ready = ((i>k) && (i>128) && (i>l) && (i>y))? 1 : 0;
    assign encryption_start = ready & encryption_startxSI;

    // Right Shift for Outputs 
    always @(posedge clk) begin
        if(encryption_ready) begin
            if(j < l)
                cipher_textxSO <= cipher_text[j];
            
            if(j < 128)
                tagxSO <= tag[j];

            if(j < 128)
                j <= j+1;
        end
    end

    // assign encryption_readyxSO = ((j>(l-1)) && (j>127))? 1: 0;
    assign encryption_readyxSO = encryption_ready;
    assign decryption_readyxSO = decryption_ready;

    // Instantiating Fault Countermeasure module
    FC #(
        k,r,a,b,l,y,TI,FP
    ) f(
        clk,
        rst,
        key, random_key_1, random_key_2,
        nonce, random_nonce_1, random_nonce_2,
        associated_data, random_ad_1, random_ad_2,
        plain_text, random_pt_1, random_pt_2,
        encryption_start,
        decryption_startxSI,
        r0,r1,r2,r3,r4,r5,r6,
        cipher_text,
        dec_plain_text,            
        tag,           
        dec_tag,          
        encryption_ready,
        decryption_ready
    );
endmodule