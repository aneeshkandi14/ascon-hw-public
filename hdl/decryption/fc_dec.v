// Fault countermeasure
module FC #(
    parameter k = 128,            // Key size
    parameter r = 128,            // Rate
    parameter a = 12,             // Initialization round no.
    parameter b = 6,              // Intermediate round no.
    parameter l = 40,             // Length of associated data
    parameter y = 40,             // Length of Plain Text
    parameter TI = 1,
    parameter FP = 1
)(
    input           clk,
    input           rst,
    input  [k-1:0]  key, random_key_1, random_key_2,
    input  [127:0]  nonce, random_nonce_1, random_nonce_2,
    input  [l-1:0]  associated_data, random_ad_1, random_ad_2,
    input  [y-1:0]  cipher_text, random_ct_1, random_ct_2,
    input           decryption_start,
    input  [63:0]   r0,r1,r2,r3,r4,r5,r6,
    input  [127:0]  random_fault_1,
    input  [y-1:0]  random_fault_2,

    output [y-1:0]  plain_text,             // Decrypted Text
    output [127:0]  tag,                    // Tag after Decryption
    output          decryption_ready        // To indicate the end of Decryption
);
    
    if(FP == 1) begin
        wire [y-1:0] p1,p2,p3;
        wire [127:0] tag1,tag2,tag3;
        wire dr1,dr2,dr3;
        wire fault_detect;

        if(TI == 1) begin
            Decryption_ti #(
                k,r,a,b,l,y
            ) d4 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                cipher_text, random_ct_1, random_ct_2,
                decryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                p1,             
                tag1,                    
                dr1        
            );

            Decryption_ti #(
                k,r,a,b,l,y
            ) d5 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                cipher_text, random_ct_1, random_ct_2,
                decryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                p2,             
                tag2,                    
                dr2        
            );

            Decryption_ti #(
                k,r,a,b,l,y
            ) d6 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                cipher_text, random_ct_1, random_ct_2,
                decryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                p3,             
                tag3,                    
                dr3        
            );
        end
    
        else begin
            Decryption #(
                k,r,a,b,l,y
            ) d4 (
                clk,
                rst,
                key,
                nonce,
                associated_data,
                cipher_text,
                decryption_start,
                p1,             
                tag1,                     
                dr1        
            );

            Decryption #(
                k,r,a,b,l,y
            ) d5 (
                clk,
                rst,
                key,
                nonce,
                associated_data,
                cipher_text,
                decryption_start,
                p2,             
                tag2,                     
                dr2        
            );

            Decryption #(
                k,r,a,b,l,y
            ) d6 (
                clk,
                rst,
                key,
                nonce,
                associated_data,
                cipher_text,
                decryption_start,
                p3,             
                tag3,                     
                dr3        
            );
        end
    
        assign fault_detect = (p1 == p2 || p2 == p3)? 1 : 0;
        
        // Bitwise Majority function
        assign plain_text = (p1 == p2 || p2 == p3)? (p1 & p2) ^ (p2 & p3) ^ (p1 & p3) : random_fault_2;
        assign tag = (tag1 == tag2 || tag2 == tag3)? (tag1 & tag2) ^ (tag2 & tag3) ^ (tag1 & tag3) : random_fault_1;
        assign decryption_ready = (dr1 & dr2) ^ (dr2 & dr3) ^ (dr1 & dr3);
    end
    
    else begin
        if(TI == 1) begin
            Decryption_ti #(
                k,r,a,b,l,y
            ) d2 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                cipher_text, random_ct_1, random_ct_2,
                decryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                plain_text,             
                tag,                    
                decryption_ready        
            );
        end
        
        else begin
            Decryption #(
                k,r,a,b,l,y
            ) d2 (
                clk,
                rst,
                key,
                nonce,
                associated_data,
                cipher_text,
                decryption_start,
                plain_text,             
                tag,                     
                decryption_ready        
            );
        end
    end
        
endmodule