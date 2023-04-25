module Hash #(
    parameter k = 128,
    parameter r = 64,
    parameter a = 12,
    parameter b = 12,
    parameter h = 256,
    parameter l = 256,
    parameter y = 40
) (
    input clk,
    input rst,
    input [y-1:0] message,
    input start,

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
    wire [63:0] IV;
    wire [r-1:0] Sr;
    wire [c-1:0] Sc;
    reg [319:0] S;
    reg [2:0] state;
    reg [4:0] rounds;
    wire [4:0] ctr;
    wire permutation_ready;
    reg permutation_start;
    reg [319:0] P_in;
    wire [319:0] P_out;
    reg [t:0] block_ctr;
    wire [Y-1:0] M;
    reg [h-1:0] H;
    reg ready_1;

    // Assignments
    assign {Sr, Sc} = S;
    assign IV = r << 48 | a << 40 | (a-b) << 12 | h;
    // assign IV = 'h00400c0000000100;
    assign M = {message, 1'b1, {nz_m{1'b0}}};
    assign hash = ready? H[h-1 -: l] : 0;
    assign ready = ready_1;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            S <= 0;
            ready_1 <= 0;
            H <= 0;
            block_ctr <= 0;
        end
        else begin
            case (state)

                // Idle Stage
                IDLE: begin
                    S <= {IV, {c{1'b0}}};
                    ready_1 <= 0;
                    if(start)
                        state <= INITIALIZE;
                end 

                // Initialization
                INITIALIZE: begin
                    if(permutation_ready) begin
                        state <= ABSORB;
                        S <= P_out;
                    end
                end

                // Absorb Message
                ABSORB: begin
                    if(block_ctr == s-1) begin
                        state <= SQUEEZE;
                        $display("%h",M[r*s-1 -: r]);
                        S <= {Sr ^ M[r*s-1 -: r], Sc};
                    end
                    else if(permutation_ready && block_ctr != s)
                        S <= P_out;

                    if (permutation_ready && block_ctr == s-1) 
                        block_ctr <= 0;
                    else if(permutation_ready && block_ctr != s)
                        block_ctr <= block_ctr + 1; 
                end

                // Squeeze Hash
                SQUEEZE: begin
                    if(permutation_ready && block_ctr == t) begin
                        state <= DONE;
                        block_ctr <= 0;
                    end
                    else if(permutation_ready && block_ctr == 0) begin
                        S <= P_out;
                        H[t*r-1 -: r] <= P_out[319 -: r];
                        block_ctr <= block_ctr + 1;
                    end
                    else if(permutation_ready && block_ctr < t) begin
                        S <= P_out;
                        H[(t-block_ctr)*r-1 -: r] <= P_out[319 -: r];
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
        P_in = 0;
        rounds = a;
        permutation_start = 0;

        case (state)
            INITIALIZE: begin
                P_in = S;
                rounds = a;
                permutation_start = (permutation_ready)? 1'b0: 1'b1;
            end

            ABSORB: begin
                P_in = {Sr^M[(s-block_ctr)*r-1 -: r], Sc};
                rounds = b;
                if(block_ctr == s-1)
                    permutation_start = 0;
                else
                    permutation_start = 1;
            end

            SQUEEZE: begin
                P_in = S;
                if(block_ctr == 0)
                    rounds = a;
                else
                    rounds = b;
                permutation_start = 1;
            end

        endcase
    end

    // Permutation Block
    Permutation p1(
        .clk(clk),
        .reset(rst),
        .S(P_in),
        .out(P_out),
        .done(permutation_ready),
        .ctr(ctr),
        .rounds(rounds),
        .start(permutation_start)
    );

    // Round Counter
    RoundCounter RC(
        clk,
        rst,
        permutation_start,
        permutation_ready,
        ctr
    );

endmodule