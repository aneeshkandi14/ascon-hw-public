module roundconstant (
    input   [63:0]  x2,
    input   [4:0]   ctr,
    input   [4:0]   rounds,
    output  [63:0]  out 
);

    reg [63:0] out_buf;
    assign out = out_buf;

    always @(*) begin
        if(rounds == 6)
            out_buf = x2 ^ (8'h96 - (ctr-1) * 15);
        else if(rounds == 8)
            out_buf = x2 ^ (8'hb4 - (ctr-1) * 15);
        else 
            out_buf = x2 ^ (8'hf0 - (ctr-1) * 15);
    end

endmodule