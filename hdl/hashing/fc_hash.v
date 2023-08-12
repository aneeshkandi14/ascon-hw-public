// Fault countermeasure
module FC #(
    parameter r = 64,
    parameter a = 12,
    parameter b = 12,
    parameter h = 256,
    parameter l = 256,
    parameter y = 40,
    parameter TI = 1,
    parameter FP = 1
)(
    input           clk,
    input           rst,
    input [y-1:0]   message, random_m1, random_m2,
    input           start,
    input [63:0]    r0,r1,r2,r3,r4,r5,r6,
    input [l-1:0]   random_fault,

    output [l-1:0]  hash_text,
    output          ready           //
);
    
    if(FP == 1) begin
        wire [l-1:0] h1,h2,h3;
        wire ready1,ready2,ready3;

        if(TI == 1) begin
            Hash_ti #(
                r,a,b,h,l,y
            ) d1 (
                clk,
                rst,
                message, random_m1, random_m2,
                start,
                r0,r1,r2,r3,r4,r5,r6,
                ready1,
                h1
            ); 

            Hash_ti #(
                r,a,b,h,l,y
            ) d2 (
                clk,
                rst,
                message, random_m1, random_m2,
                start,
                r0,r1,r2,r3,r4,r5,r6,
                ready2,
                h2
            ); 

            Hash_ti #(
                r,a,b,h,l,y
            ) d3 (
                clk,
                rst,
                message, random_m1, random_m2,
                start,
                r0,r1,r2,r3,r4,r5,r6,
                ready3,
                h3
            ); 
        end
    
        else begin
            Hash #(
                r,a,b,h,l,y
            ) d1 (
                clk,
                rst,
                message,
                start,
                ready1,
                h1
            );

            Hash #(
                r,a,b,h,l,y
            ) d2 (
                clk,
                rst,
                message,
                start,
                ready2,
                h2
            );

            Hash #(
                r,a,b,h,l,y
            ) d3 (
                clk,
                rst,
                message,
                start,
                ready3,
                h3
            );
        end
    
        // Bitwise Majority function
        assign hash_text = (h1 == h2 || h2 == h3)? (h1 & h2) ^ (h2 & h3) ^ (h1 & h3) : random_fault;
        assign ready = (ready1 & ready2) ^ (ready2 & ready3) ^ (ready1 & ready3);
    end
    
    else begin
        if(TI == 1) begin
            Hash_ti #(
                r,a,b,h,l,y
            ) d1 (
                clk,
                rst,
                message, random_m1, random_m2,
                start,
                r0,r1,r2,r3,r4,r5,r6,
                ready,
                hash_text
            ); 
        end
        
        else begin
            Hash #(
                r,a,b,h,l,y
            ) d1 (
                clk,
                rst,
                message,
                start,
                ready,
                hash_text
            );
        end
    end
        
endmodule