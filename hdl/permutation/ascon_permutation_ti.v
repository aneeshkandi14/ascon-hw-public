module Permutation_ti (
    
    // Inputs
    input           clk,
    input           reset,
    input   [4:0]   ctr,
    input   [319:0] S_0, S_1, S_2,
    input   [4:0]   rounds,
    input           start,
    input   [63:0]  r0,r1,r2,r3,r4,r5,r6,

    // Outputs
    output  [319:0] out_0, out_1, out_2,
    output          done            // Done signal when counter = no. of rounds
);

    // No. of rounds * (Add round constant -> Substitution Layer -> Linear Diffusion Layer)

    // Splitting the input state into 5 registers
    reg[63:0] x0_0_q,x1_0_q,x2_0_q,x3_0_q,x4_0_q;
    reg[63:0] x0_1_q,x1_1_q,x2_1_q,x3_1_q,x4_1_q;
    reg[63:0] x0_2_q,x1_2_q,x2_2_q,x3_2_q,x4_2_q;

    wire[63:0] x0_0_d,x1_0_d,x2_0_d,x3_0_d,x4_0_d;
    wire[63:0] x0_1_d,x1_1_d,x2_1_d,x3_1_d,x4_1_d;
    wire[63:0] x0_2_d,x1_2_d,x2_2_d,x3_2_d,x4_2_d;
    
    wire[63:0] x0,x1,x2,x3,x4;
    assign x0 = x0_0_q ^ x0_1_q ^ x0_2_q;
    assign x1 = x1_0_q ^ x1_1_q ^ x1_2_q;
    assign x2 = x2_0_q ^ x2_1_q ^ x2_2_q;
    assign x3 = x3_0_q ^ x3_1_q ^ x3_2_q;
    assign x4 = x4_0_q ^ x4_1_q ^ x4_2_q;

    // Done register
    reg Done;

    // Updating the registers with clock cycles
    always @(posedge clk) begin
        if(reset) begin
            {x0_0_q,x1_0_q,x2_0_q,x3_0_q,x4_0_q} <= 0;
            {x0_1_q,x1_1_q,x2_1_q,x3_1_q,x4_1_q} <= 0;
            {x0_2_q,x1_2_q,x2_2_q,x3_2_q,x4_2_q} <= 0;
            Done <= 0;
        end
        else begin
            if(start) begin
                if(ctr == 0) begin
                    {x0_0_q,x1_0_q,x2_0_q,x3_0_q,x4_0_q} <= S_0;
                    {x0_1_q,x1_1_q,x2_1_q,x3_1_q,x4_1_q} <= S_1;
                    {x0_2_q,x1_2_q,x2_2_q,x3_2_q,x4_2_q} <= S_2;
                end
                else begin
                    {x0_0_q,x1_0_q,x2_0_q,x3_0_q,x4_0_q} <= {x0_0_d,x1_0_d,x2_0_d,x3_0_d,x4_0_d};
                    {x0_1_q,x1_1_q,x2_1_q,x3_1_q,x4_1_q} <= {x0_1_d,x1_1_d,x2_1_d,x3_1_d,x4_1_d};
                    {x0_2_q,x1_2_q,x2_2_q,x3_2_q,x4_2_q} <= {x0_2_d,x1_2_d,x2_2_d,x3_2_d,x4_2_d};       
                end
            end
        end
        if(ctr == rounds)
            Done <= 1;
        else
            Done <= 0;
    end

    // Done signal
    assign done = Done;

    // Output
    assign out_0 = {x0_0_q,x1_0_q,x2_0_q,x3_0_q,x4_0_q};
    assign out_1 = {x0_1_q,x1_1_q,x2_1_q,x3_1_q,x4_1_q};
    assign out_2 = {x0_2_q,x1_2_q,x2_2_q,x3_2_q,x4_2_q};


    // Adding Round Constant

    wire [63:0] rc_out_0, rc_out_1, rc_out_2, rc_out;
    assign rc_out = rc_out_0 ^ rc_out_1 ^ rc_out_2;
    roundconstant_0 rc0(
        .x2(x2_0_q), .r0(r5),
        .out(rc_out_0),
        .rounds(rounds)
    );

    roundconstant_1 rc1(
        .x2(x2_1_q), .r1(r6),
        .out(rc_out_1),
        .rounds(rounds)
    );

    roundconstant_2 rc2(
        .x2(x2_2_q), .r0(r5), .r1(r6),
        .ctr(ctr),
        .out(rc_out_2),
        .rounds(rounds)
    );

    // Substituition Layer
    wire[63:0] y0_0,y1_0,y2_0,y3_0,y4_0;
    wire[63:0] y0_1,y1_1,y2_1,y3_1,y4_1;
    wire[63:0] y0_2,y1_2,y2_2,y3_2,y4_2;
    wire[63:0] y0,y1,y2,y3,y4;

    assign y0 = (y0_0 ^ y0_1 ^ y0_2);
    assign y1 = (y1_0 ^ y1_1 ^ y1_2);
    assign y2 = (y2_0 ^ y2_1 ^ y2_2);
    assign y3 = (y3_0 ^ y3_1 ^ y3_2);
    assign y4 = (y4_0 ^ y4_1 ^ y4_2);

    sub_layer_ti_0 s0(
        x0_0_q,x1_0_q,rc_out_0,x3_0_q,x4_0_q,
        x0_1_q,x1_1_q,rc_out_1,x3_1_q,x4_1_q,
        x0_2_q,x1_2_q,rc_out_2,x3_2_q,x4_2_q,

        y0_0,y1_0,y2_0,y3_0,y4_0
    );

    sub_layer_ti_1 s1(
        x0_0_q,x1_0_q,rc_out_0,x3_0_q,x4_0_q,
        x0_1_q,x1_1_q,rc_out_1,x3_1_q,x4_1_q,
        x0_2_q,x1_2_q,rc_out_2,x3_2_q,x4_2_q,

        y0_1,y1_1,y2_1,y3_1,y4_1
    );

    sub_layer_ti_2 s2(
        x0_0_q,x1_0_q,rc_out_0,x3_0_q,x4_0_q,
        x0_1_q,x1_1_q,rc_out_1,x3_1_q,x4_1_q,
        x0_2_q,x1_2_q,rc_out_2,x3_2_q,x4_2_q,

        y0_2,y1_2,y2_2,y3_2,y4_2
    );

    // Linear Layer
    wire[63:0] ll0,ll1,ll2,ll3,ll4;
    assign ll0 = (x0_0_d ^ x0_1_d ^ x0_2_d);
    assign ll1 = (x1_0_d ^ x1_1_d ^ x1_2_d);
    assign ll2 = (x2_0_d ^ x2_1_d ^ x2_2_d);
    assign ll3 = (x3_0_d ^ x3_1_d ^ x3_2_d);
    assign ll4 = (x4_0_d ^ x4_1_d ^ x4_2_d);

    linear_layer_0 l0(
        y0_0,y1_0,y2_0,y3_0,y4_0,
        r0,r1,r2,r3,r4,

        x0_0_d,x1_0_d,x2_0_d,x3_0_d,x4_0_d
    );

    linear_layer_1 l1(
        y0_1,y1_1,y2_1,y3_1,y4_1,
        r0,r1,r2,r3,r4,

        x0_1_d,x1_1_d,x2_1_d,x3_1_d,x4_1_d
    );

    linear_layer_2 l2(
        y0_2,y1_2,y2_2,y3_2,y4_2,
        r0,r1,r2,r3,r4,
        
        x0_2_d,x1_2_d,x2_2_d,x3_2_d,x4_2_d
    );
    
endmodule