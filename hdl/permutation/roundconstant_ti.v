module roundconstant_0 (
    input   [63:0]  x2, r0,
    input   [4:0]   rounds,
    output  [63:0]  out 
);

    reg [63:0] out_buf;
    assign out = out_buf;

    always @(*) begin
        if(rounds == 6)
            out_buf = x2 ^ r0;
        else if(rounds == 8)
            out_buf = x2 ^ r0;
        else 
            out_buf = x2 ^ r0;
    end

endmodule

module roundconstant_1 (
    input   [63:0]  x2, r1,
    input   [4:0]   rounds,
    output  [63:0]  out 
);

    reg [63:0] out_buf;
    assign out = out_buf;

    always @(*) begin
        if(rounds == 6)
            out_buf = x2 ^ r1;
        else if(rounds == 8)
            out_buf = x2 ^ r1;
        else 
            out_buf = x2 ^ r1;
    end

endmodule

module roundconstant_2 (
    input   [63:0]  x2, r0, r1,
    input   [4:0]   ctr,
    input   [4:0]   rounds,
    output  [63:0]  out 
);

    reg [63:0] out_buf;
    assign out = out_buf;

    always @(*) begin
        if(rounds == 6)
            out_buf = x2 ^ r0 ^ r1 ^ (8'h96 - (ctr-1) * 15);
        else if(rounds == 8)
            out_buf = x2 ^ r0 ^ r1 ^ (8'hb4 - (ctr-1) * 15);
        else if(rounds == 12)
            out_buf = x2 ^ r0 ^ r1 ^ (8'hf0 - (ctr-1) * 15);
            
        // Testing with 1 round permutation
        else
            out_buf = x2 ^ r0 ^ r1 ^ (8'h4b - (ctr-1) * 15);
    end

endmodule