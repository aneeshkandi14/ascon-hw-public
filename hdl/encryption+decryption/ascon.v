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
    input [4:0] keyxSI,
    input [4:0] noncexSI,
    input [4:0] associated_dataxSI,
    input [4:0] plain_textxSI,
    input       encryption_startxSI,
    input       decryption_startxSI,
    input [13:0] r_64xSI,
    input [2:0] r_128xSI,
    input [2:0] r_ptxSI,

    output reg  cipher_textxSO,
    output reg  plain_textxS0,
    output reg  tagxSO, dec_tagxSO,      
    output      encryption_readyxSO,
    output      decryption_readyxSO,     
    output      message_authentication   //
);
    
    reg     [k-1:0]     key,random_key_1,random_key_2, random_key_3, random_key_4;      
    reg     [127:0]     nonce,random_nonce_1,random_nonce_2, random_nonce_3, random_nonce_4;
    reg     [l-1:0]     associated_data, random_ad_1, random_ad_2, random_ad_3, random_ad_4; 
    reg     [y-1:0]     plain_text, random_pt_1, random_pt_2, random_ct_1, random_ct_2;
    reg     [63:0]      r0,r1,r2,r3,r4,r5,r6;
    reg     [63:0]      r7,r8,r9,r10,r11,r12,r13;
    reg     [127:0]     random_fault_1, random_fault_2, random_dec_1;
    reg     [y-1:0]     random_fault_3, random_fault_4, random_dec_2;
    reg     [31:0]      i, j, m;        // Counter registers
    wire    [y-1:0]     dec_plain_text;
    wire    [y-1:0]     cipher_text;
    wire    [127:0]     tag, dec_tag;
    wire                ready, encryption_start;
    wire                permutation_ready, permutation_start;

    // Left shift for Inputs
    always @(posedge clk) begin
        if(rst)
            {key,random_key_1,random_key_2,random_key_3,random_key_4,
            nonce,random_nonce_1,random_nonce_2,random_nonce_3,random_nonce_4,
            random_ad_1,random_ad_2,random_ad_3,random_ad_4,associated_data,
            random_pt_1,random_pt_2,plain_text,
            random_ct_1,random_ct_2,
            i,j,m} <= 0;

        else begin
            if(i < k) begin
                key <= {key[k-2:0], keyxSI[0]}; 
                random_key_1 <= {random_key_1[k-2:0], keyxSI[1]};
                random_key_2 <= {random_key_2[k-1:0], keyxSI[2]};
                random_key_3 <= {random_key_3[k-2:0], keyxSI[3]};
                random_key_4 <= {random_key_4[k-1:0], keyxSI[4]};
            end

            if(i < 128) begin
                nonce <= {nonce[126:0], noncexSI[0]};
                random_nonce_1 <= {random_nonce_1[126:0], noncexSI[1]};
                random_nonce_2 <= {random_nonce_2[126:0], noncexSI[2]};
                random_nonce_3 <= {random_nonce_3[126:0], noncexSI[3]};
                random_nonce_4 <= {random_nonce_4[126:0], noncexSI[4]};
                random_fault_1 <= {random_fault_1[126:0], r_128xSI[0]};
                random_fault_2 <= {random_fault_2[126:0], r_128xSI[1]};
                random_dec_1 <= {random_dec_1[126:0], r_128xSI[2]};
            end

            if(i < l) begin
                associated_data <= {associated_data[l-2:0], associated_dataxSI[0]};
                random_ad_1 <= {random_ad_1[l-2:0], associated_dataxSI[1]};
                random_ad_2 <= {random_ad_2[l-2:0], associated_dataxSI[2]};
                random_ad_3 <= {random_ad_3[l-2:0], associated_dataxSI[3]};
                random_ad_4 <= {random_ad_4[l-2:0], associated_dataxSI[4]};
            end

            if(i < y) begin
                plain_text <= {plain_text[y-2:0], plain_textxSI[0]};
                random_pt_1 <= {random_pt_1[y-2:0], plain_textxSI[1]};
                random_pt_2 <= {random_pt_2[y-2:0], plain_textxSI[2]};
                random_ct_1 <= {random_ct_1[y-2:0], plain_textxSI[3]};
                random_ct_2 <= {random_ct_2[y-2:0], plain_textxSI[4]};
                random_fault_3 <= {random_fault_3[y-2:0], r_ptxSI[0]};
                random_fault_4 <= {random_fault_4[y-2:0], r_ptxSI[1]};
                random_dec_2 <= {random_dec_2[y-2:0], r_ptxSI[2]};
            end

            if(i < 64) begin
                r0 <= {r0[62:0],r_64xSI[0]};
                r1 <= {r1[62:0],r_64xSI[1]};
                r2 <= {r2[62:0],r_64xSI[2]};
                r3 <= {r3[62:0],r_64xSI[3]};
                r4 <= {r4[62:0],r_64xSI[4]};
                r5 <= {r5[62:0],r_64xSI[5]};
                r6 <= {r6[62:0],r_64xSI[6]};
                r7 <= {r7[62:0],r_64xSI[7]};
                r8 <= {r8[62:0],r_64xSI[8]};
                r9 <= {r9[62:0],r_64xSI[9]};
                r10 <= {r10[62:0],r_64xSI[10]};
                r11 <= {r11[62:0],r_64xSI[11]};
                r12 <= {r12[62:0],r_64xSI[12]};
                r13 <= {r13[62:0],r_64xSI[13]};
            end

            i <= i+1;
        end

        // Right Shift for encryption outputs
        if(encryption_ready) begin
            if(j < y)
                cipher_textxSO <= cipher_text[j];
            
            if(j < 128)
                tagxSO <= tag[j];

            j <= j+1;
        end

        // Right Shift for decryption outputs
        if(decryption_ready) begin
            if(message_authentication) begin
                if(m < y)
                    plain_textxS0 <= dec_plain_text[m];
                
                if(m < 128)
                    dec_tagxSO <= dec_tag[m];

                m <= m+1;
            end
            // If message is not authenticated, then a random message is outputted
            else begin
               if(m < y)
                    plain_textxS0 <= random_dec_2[m];
                
                if(m < 128)
                    dec_tagxSO <= random_dec_1[m];

                m <= m+1; 
            end
        end
    end

    assign ready = ((i>k) && (i>128) && (i>l) && (i>y))? 1 : 0;
    assign encryption_start = ready & encryption_startxSI;

    assign encryption_readyxSO = encryption_ready;
    assign decryption_readyxSO = decryption_ready;

    // Instantiating Fault Countermeasure module
    FC #(
        k,r,a,b,l,y,TI,FP
    ) f(
        clk,
        rst,
        key, random_key_1, random_key_2, random_key_3, random_key_4,
        nonce, random_nonce_1, random_nonce_2, random_nonce_3, random_nonce_4,
        associated_data, random_ad_1, random_ad_2, random_ad_3, random_ad_4,
        plain_text, random_pt_1, random_pt_2, random_ct_1, random_ct_2,
        encryption_start,
        decryption_startxSI,
        r0,r1,r2,r3,r4,r5,r6,
        r7,r8,r9,r10,r11,r12,r13,
        random_fault_1, random_fault_2,
        random_fault_3, random_fault_4,

        cipher_text,
        dec_plain_text,            
        tag,           
        dec_tag,          
        encryption_ready,
        decryption_ready,
        message_authentication
    );
endmodule