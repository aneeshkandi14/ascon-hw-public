module Ascon #(
    parameter r = 64,
    parameter a = 12,
    parameter b = 12,
    parameter h = 256,
    parameter l = 256,
    parameter y = 40,
    parameter TI = 0,              // 1 for Yes; else No
    parameter FP = 0               // 1 for Yes; else No
)(
    input       clk,
    input       rst,
    input [2:0] messagexSI,
    input       startxSI,
    input [6:0] r_64xSI,
    input       r_faultxSI,

    output reg  hash_textxSO,
    output      readyxSO //
);

    reg     [y-1:0]     message, random_m1, random_m2;
    reg     [63:0]      r0,r1,r2,r3,r4,r5,r6;
    reg     [31:0]      i,j;
    reg     [l-1:0]     random_fault;
    wire    [l-1:0]     hash_text;
    wire                ready_1, ready, start;
    wire                permutation_ready, permutation_start;

    // Left shift for Inputs
    always @(posedge clk) begin
        if(rst)
            {message, random_m1, random_m2,
            r0,r1,r2,r3,r4,r5,r6,
            i, j} <= 0;

        else begin
            if(i < y) begin
                message <= {message[y-2:0], messagexSI[0]};
                random_m1 <= {random_m1[y-2:0], messagexSI[1]};
                random_m2 <= {random_m2[y-2:0], messagexSI[2]};
            end

            if(i < l) 
                random_fault <= {random_fault[l-2:0], r_faultxSI};

            if(i < 64) begin
                r0 <= {r0[62:0],r_64xSI[0]};
                r1 <= {r1[62:0],r_64xSI[1]};
                r2 <= {r2[62:0],r_64xSI[2]};
                r3 <= {r3[62:0],r_64xSI[3]};
                r4 <= {r4[62:0],r_64xSI[4]};
                r5 <= {r5[62:0],r_64xSI[5]};
                r6 <= {r6[62:0],r_64xSI[6]};
            end

            i <= i+1;
        end

        // Right Shift for encryption outputs
        if(ready) begin
            if(j < l)
                hash_textxSO <= hash_text[j];

            j <= j + 1;
        end
    end

    assign ready_1 = ((i>y) && (i>l) && (i>64))? 1 : 0;
    assign start = ready_1 & startxSI;
    assign readyxSO = ready;

    // Instantiating Fault Countermeasure module
    FC #(
        r,a,b,h,l,y,TI,FP
    ) f(
            clk,
            rst,
            message, random_m1, random_m2,
            start,
            r0,r1,r2,r3,r4,r5,r6,
            random_fault,

            hash_text,
            ready
    );
endmodule