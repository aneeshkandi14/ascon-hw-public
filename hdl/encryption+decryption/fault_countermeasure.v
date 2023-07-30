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
    input  [k-1:0]  key, random_key_1, random_key_2, random_key_3, random_key_4,
    input  [127:0]  nonce, random_nonce_1, random_nonce_2, random_nonce_3, random_nonce_4,
    input  [l-1:0]  associated_data, random_ad_1, random_ad_2, random_ad_3, random_ad_4,
    input  [y-1:0]  plain_text, random_pt_1, random_pt_2, random_ct_1, random_ct_2,
    input           encryption_start,
    input           decryption_start,
    input  [63:0]   r0,r1,r2,r3,r4,r5,r6,
    input  [63:0]   r7,r8,r9,r10,r11,r12,r13,
    input  [127:0]  random_fault_1, random_fault_2,
    input  [y-1:0]  random_fault_3, random_fault_4,

    output [y-1:0]  cipher_text,            // Plain text converted to cipher text
    output [y-1:0]  dec_plain_text,         // Decrypted Text
    output [127:0]  tag,                    // Final Tag after Encryption 
    output [127:0]  dec_tag,                // Tag after Decryption
    output          encryption_ready,       // To indicate the end of Encryption
    output          decryption_ready,       // To indicate the end of Decryption
    output          message_authentication  // Indicates whether the message is authenticated
);
    
    if(FP == 1) begin
        wire [y-1:0] c1,c2,c3,p1,p2,p3;
        wire [127:0] tag1,tag2,tag3,tag4,tag5,tag6;
        wire er1,er2,er3,dr1,dr2,dr3;
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
            
            Decryption_ti #(
                k,r,a,b,l,y
            ) d4 (
                clk,
                rst,
                key, random_key_3, random_key_4,
                nonce, random_nonce_3, random_nonce_4,
                associated_data, random_ad_3, random_ad_4,
                c1, random_ct_1, random_ct_2,
                decryption_start,
                r7,r8,r9,r10,r11,r12,r13,
                p1,             
                tag4,                    
                dr1        
            );

            Decryption_ti #(
                k,r,a,b,l,y
            ) d5 (
                clk,
                rst,
                key, random_key_3, random_key_4,
                nonce, random_nonce_3, random_nonce_4,
                associated_data, random_ad_3, random_ad_4,
                c2, random_ct_1, random_ct_2,
                decryption_start,
                r7,r8,r9,r10,r11,r12,r13,
                p2,             
                tag5,                    
                dr2        
            );

            Decryption_ti #(
                k,r,a,b,l,y
            ) d6 (
                clk,
                rst,
                key, random_key_3, random_key_4,
                nonce, random_nonce_3, random_nonce_4,
                associated_data, random_ad_3, random_ad_4,
                c3, random_ct_1, random_ct_2,
                decryption_start,
                r7,r8,r9,r10,r11,r12,r13,
                p3,             
                tag6,                    
                dr3        
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

            Decryption #(
                k,r,a,b,l,y
            ) d4 (
                clk,
                rst,
                key,
                nonce,
                associated_data,
                c1,
                decryption_start,
                p1,             
                tag4,                     
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
                c2,
                decryption_start,
                p2,             
                tag5,                     
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
                c3,
                decryption_start,
                p3,             
                tag6,                     
                dr3        
            );
        end
    
    assign fault_detect = (c1 == c2 || c2 == c3)? 1 : 0;
    
    // Bitwise Majority function
    assign cipher_text = (c1 == c2 || c2 == c3)? (c1 & c2) ^ (c2 & c3) ^ (c1 & c3) : random_fault_3;
    assign dec_plain_text = (p1 == p2 || p2 == p3)? (p1 & p2) ^ (p2 & p3) ^ (p1 & p3) : random_fault_4;
    assign tag = (tag1 == tag2 || tag2 == tag3)? (tag1 & tag2) ^ (tag2 & tag3) ^ (tag1 & tag3) : random_fault_1;
    assign dec_tag = (tag4 == tag5 || tag5 == tag6)? (tag4 & tag5) ^ (tag5 & tag6) ^ (tag4 & tag6) : random_fault_2;
    assign encryption_ready = (er1 & er2) ^ (er2 & er3) ^ (er1 & er3);
    assign decryption_ready = (dr1 & dr2) ^ (dr2 & dr3) ^ (dr1 & dr3);
    assign message_authentication = (decryption_ready)? (tag1 == tag4): 0;
    
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

            Decryption_ti #(
                k,r,a,b,l,y
            ) d2 (
                clk,
                rst,
                key, random_key_3, random_key_4,
                nonce, random_nonce_3, random_nonce_4,
                associated_data, random_ad_3, random_ad_4,
                cipher_text, random_ct_1, random_ct_2,
                decryption_start,
                r7,r8,r9,r10,r11,r12,r13,
                dec_plain_text,             
                dec_tag,                    
                decryption_ready        
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
                dec_plain_text,             
                dec_tag,                     
                decryption_ready        
            );
        end

        assign message_authentication = (decryption_ready)? (dec_tag == tag): 0;
    end
        
endmodule