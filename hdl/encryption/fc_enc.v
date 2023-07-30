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
    input  [y-1:0]  plain_text, random_pt_1, random_pt_2,
    input           encryption_start,
    input  [63:0]   r0,r1,r2,r3,r4,r5,r6,
    input  [127:0]  random_fault_1,
    input  [y-1:0]  random_fault_2,

    output [y-1:0]  cipher_text,            // Plain text converted to cipher text
    output [127:0]  tag,                    // Final Tag after Encryption 
    output          encryption_ready        // To indicate the end of Encryption
);
    
    if(FP == 1) begin
        wire [y-1:0] c1,c2,c3;
        wire [127:0] tag1,tag2,tag3;
        wire er1,er2,er3;
        wire fault_detect;

        if(TI == 1) begin
            Encryption_ti #(
                k,r,a,b,l,y
            ) d1 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                plain_text, random_pt_1, random_pt_2,
                encryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                c1,     
                tag1,              
                er1
            );
            
            Encryption_ti #(
                k,r,a,b,l,y
            ) d2 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                plain_text, random_pt_1, random_pt_2,
                encryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                c2,     
                tag2,              
                er2
            );
    
            Encryption_ti #(
                k,r,a,b,l,y
            ) d3 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                plain_text, random_pt_1, random_pt_2,
                encryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                c3,     
                tag3,              
                er3
            );
        end
    
        else begin
            Encryption #(
                k,r,a,b,l,y
            ) d1 (
                clk,
                rst,
                key, 
                nonce, 
                associated_data,
                plain_text,
                encryption_start,
                c1,
                tag1,          
                er1
            );
            
            Encryption #(
                k,r,a,b,l,y
            ) d2 (
                clk,
                rst,
                key, 
                nonce, 
                associated_data, 
                plain_text, 
                encryption_start,
                c2,     
                tag2,              
                er2
            );
    
            Encryption #(
                k,r,a,b,l,y
            ) d3 (
                clk,
                rst,
                key, 
                nonce, 
                associated_data,
                plain_text,
                encryption_start,
                c3,     
                tag3,              
                er3
            );
        end
    
        assign fault_detect = (c1 == c2 || c2 == c3)? 1 : 0;
        
        // Bitwise Majority function
        assign cipher_text = (c1 == c2 || c2 == c3)? (c1 & c2) ^ (c2 & c3) ^ (c1 & c3) : random_fault_2;
        assign tag = (tag1 == tag2 || tag2 == tag3)? (tag1 & tag2) ^ (tag2 & tag3) ^ (tag1 & tag3) : random_fault_1;
        assign encryption_ready = (er1 & er2) ^ (er2 & er3) ^ (er1 & er3);
    end
    
    else begin
        if(TI == 1) begin
            Encryption_ti #(
                k,r,a,b,l,y
            ) d1 (
                clk,
                rst,
                key, random_key_1, random_key_2,
                nonce, random_nonce_1, random_nonce_2,
                associated_data, random_ad_1, random_ad_2,
                plain_text, random_pt_1, random_pt_2,
                encryption_start,
                r0,r1,r2,r3,r4,r5,r6,
                cipher_text,     
                tag,              
                encryption_ready
            );
        end
        
        else begin
            Encryption #(
                k,r,a,b,l,y
            ) d1 (
                clk,
                rst,
                key, 
                nonce, 
                associated_data,
                plain_text,
                encryption_start,
                cipher_text,
                tag,          
                encryption_ready
            );
        end
    end
        
endmodule