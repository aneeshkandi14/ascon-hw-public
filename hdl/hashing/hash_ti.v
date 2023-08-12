module Hash_ti #(
    parameter r = 64,
    parameter a = 12,
    parameter b = 12,
    parameter h = 256,
    parameter l = 256,
    parameter y = 40
) (
    input clk,
    input rst,
    input [y-1:0] message, random_m1, random_m2, 
    input start,
    input  [63:0]   r0,r1,r2,r3,r4,r5,r6,

    output ready,
    output [l-1:0] hash
);
    // Constants
    localparam c = 320-r;
    localparam nz_m = ((y+1)%r == 0)? 0 : r-((y+1)%r);
    localparam Y = y+1+nz_m;
    localparam s = Y/r;
    localparam t = l/r;

    // FSM States
    localparam IDLE = 'd0;
    localparam INITIALIZE = 'd1;
    localparam ABSORB = 'd2;
    localparam SQUEEZE = 'd3;
    localparam DONE = 'd4;

    // Buffer Variables
    wire [63:0]     IV;
    reg  [319:0]    S_0, S_1, S_2;
    wire [r-1:0]    Sr_0, Sr_1, Sr_2;
    wire [c-1:0]    Sc_0, Sc_1, Sc_2;

    reg  [2:0]      state;
    reg  [4:0]      rounds;
    wire [4:0]      ctr;

    // Permutation variables
    reg  [319:0]    P_in_0, P_in_1, P_in_2;
    wire [319:0]    P_out_0, P_out_1, P_out_2;
    wire            permutation_ready;
    reg             permutation_start;

    reg  [t:0]      block_ctr;
    wire [Y-1:0]    M_0, M_1, M_2;
    reg  [h-1:0]    H_0, H_1, H_2;
    reg             ready_1;

    // Assignments
    assign IV = r << 48 | a << 40 | (a-b) << 12 | h;

    assign {Sr_0,Sc_0} = S_0;
    assign {Sr_1,Sc_1} = S_1;
    assign {Sr_2,Sc_2} = S_2;

    assign M_0 = {random_m1, 1'b1, {nz_m{1'b0}}};
    assign M_1 = {random_m2, 1'b1, {nz_m{1'b0}}};
    assign M_2 = {random_m1 ^ random_m2 ^ message, 1'b1, {nz_m{1'b0}}};

    assign hash = ready? (H_0[h-1 -: l] ^ H_1[h-1 -: l] ^ H_2[h-1 -: l]) : 0;
    assign ready = ready_1;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            {S_0, S_1, S_2} <= 0;
            ready_1 <= 0;
            {H_0, H_1, H_2} <= 0;
            block_ctr <= 0;
        end
        else begin
            case (state)

                // Idle Stage
                IDLE: begin
                    S_0 <= {IV, {c{1'b0}}};
                    S_1 <= {IV, {c{1'b0}}};
                    S_2 <= {IV, {c{1'b0}}};
                    ready_1 <= 0;
                    if(start)
                        state <= INITIALIZE;
                end 

                // Initialization
                INITIALIZE: begin
                    if(permutation_ready) begin
                        state <= ABSORB;
                        {S_0, S_1, S_2} <= {P_out_0, P_out_1, P_out_2};
                    end
                end

                // Absorb Message
                ABSORB: begin
                    if(block_ctr == s-1) begin
                        state <= SQUEEZE;
                        S_0 <= {Sr_0 ^ M_0[r-1 : 0], Sc_0};
                        S_1 <= {Sr_1 ^ M_1[r-1 : 0], Sc_1};
                        S_2 <= {Sr_2 ^ M_2[r-1 : 0], Sc_2};
                    end
                    else if(permutation_ready && block_ctr != s) begin
                        S_0 <= P_out_0;
                        S_1 <= P_out_1;
                        S_2 <= P_out_2;
                    end

                    if (block_ctr == s-1) 
                        block_ctr <= 0;
                    else if(permutation_ready && block_ctr != s)
                        block_ctr <= block_ctr + 1; 
                end

                // Squeeze Hash
                SQUEEZE: begin
                    if(permutation_ready && block_ctr == t-1) begin
                        state <= DONE;
                        block_ctr <= 0;
                        H_0[r-1 : 0] <= P_out_0[319 -: r];
                        H_1[r-1 : 0] <= P_out_1[319 -: r];
                        H_2[r-1 : 0] <= P_out_2[319 -: r];
                    end
                    else if(permutation_ready && block_ctr != t) begin
                        {S_0, S_1, S_2} <= {P_out_0, P_out_1, P_out_2};
                        H_0[(t-block_ctr)*r-1 -: r] <= P_out_0[319 -: r];
                        H_1[(t-block_ctr)*r-1 -: r] <= P_out_1[319 -: r];
                        H_2[(t-block_ctr)*r-1 -: r] <= P_out_2[319 -: r];
                        block_ctr <= block_ctr + 1;
                    end
                end

                // Done Stage
                DONE: begin
                    ready_1 <= 1;
                    if(start)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    always @(*) begin

        // Default Values
        P_in_0 = 0;
        P_in_1 = 0;
        P_in_2 = 0;
        rounds = a;
        permutation_start = 0;

        case (state)
            INITIALIZE: begin
                {P_in_0, P_in_1, P_in_2} = {S_0, S_1, S_2};
                rounds = a;
                permutation_start = (permutation_ready)? 1'b0: 1'b1;
            end

            ABSORB: begin
                P_in_0 = {Sr_0 ^ M_0[(s-block_ctr)*r-1 -: r], Sc_0};
                P_in_1 = {Sr_1 ^ M_1[(s-block_ctr)*r-1 -: r], Sc_1};
                P_in_2 = {Sr_2 ^ M_2[(s-block_ctr)*r-1 -: r], Sc_2};
                rounds = b;
                if(block_ctr == s-1)
                    permutation_start = 0;
                else
                    permutation_start = 1;
            end

            SQUEEZE: begin
                {P_in_0, P_in_1, P_in_2} = {S_0, S_1, S_2};
                if(block_ctr == 0)
                    rounds = a;
                else
                    rounds = b;
                permutation_start = 1;
            end

        endcase
    end

    // ---------------------------------------------------------------------------------------
    //                                  Permutation
    // ---------------------------------------------------------------------------------------
    Permutation_ti p1(
        .clk(clk),
        .reset(rst),
        .S_0(P_in_0), .S_1(P_in_1), .S_2(P_in_2),
        .out_0(P_out_0), .out_1(P_out_1), .out_2(P_out_2),
        .done(permutation_ready),
        .ctr(ctr),
        .rounds(rounds),
        .start(permutation_start),
        .r0(r0),.r1(r1),.r2(r2),.r3(r3),.r4(r4),.r5(r5),.r6(r6)
    );
    
    // ---------------------------------------------------------------------------------------
    //                                  Round Counter
    // ---------------------------------------------------------------------------------------
    RoundCounter RC(
        clk,
        rst,
        permutation_start,
        permutation_ready,
        ctr
    );

endmodule