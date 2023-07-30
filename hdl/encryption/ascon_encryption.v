// Encryption FSM
module Encryption #(
    parameter k = 128,            // Key size
    parameter r = 128,            // Rate
    parameter a = 12,             // Initialization round no.
    parameter b = 6,              // Intermediate round no.
    parameter l = 40,            // Length of associated data
    parameter y = 40             // Length of Plain Text
)(
    input           clk,
    input           rst,
    input  [k-1:0]  key,
    input  [127:0]  nonce,
    input  [l-1:0]  associated_data,
    input  [y-1:0]  plain_text,
    input           encryption_start,

    output [y-1:0]  cipher_text,            // Plain text converted to cipher text
    output [127:0]  tag,                    // Final Tag after Encryption 
    output          encryption_ready        // To indicate the end of Encryption
);

    // Constants
    parameter c = 320-r;

    parameter nz_ad =  ((l+1)%r == 0)? 0 : r-((l+1)%r);
    parameter L = l+1+nz_ad;
    parameter s = L/r;

    parameter nz_p =  ((y+1)%r == 0)? 0 : r-((y+1)%r);
    parameter Y = y+1+nz_p;
    parameter t = Y/r;

    // Buffer variables
    reg  [4:0]          rounds;
    reg  [127:0]        Tag;
    reg  [127:0]        Tag_d;
    reg                 encryption_ready_1;
    wire [190-k-1:0]    IV;
    reg  [319:0]        S;
    wire [r-1:0]        Sr;
    wire [c-1:0]        Sc;
    reg  [319:0]        P_in;
    wire [319:0]        P_out;
    wire                permutation_ready;
    reg                 permutation_start;
    wire [L-1:0]        A;
    wire [Y-1:0]        P;
    reg  [Y-1:0]        C;
    reg  [Y-1:0]        C_d;
    reg  [t:0]          block_ctr;  
    wire [4:0]          ctr;

    assign IV = k << 24 | r << 16 | a << 8 | b;
    assign {Sr,Sc} = S;
    assign encryption_ready = encryption_ready_1;
    assign A = {associated_data, 1'b1, {nz_ad{1'b0}}};
    assign P = {plain_text, 1'b1, {nz_p{1'b0}}};
    assign tag = (encryption_ready_1)? Tag : 0;
    if(y>0)
        assign cipher_text = (encryption_ready_1)? C[Y-1 : Y-y] : 0;
    else
        assign cipher_text = 0;
    assign state_1 = state;

    // FSM States
    parameter IDLE              = 'd0,
              INITIALIZE        = 'd1,
              ASSOCIATED_DATA   = 'd2,
              PTCT              = 'd3,
              FINALIZE          = 'd4, 
              DONE              = 'd5;  
    reg [2:0] state;

    // ---------------------------------------------------------------------------------------
    //                               FSM Starts here
    // ---------------------------------------------------------------------------------------

    // Sequential Block
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            S <= 0;
            Tag <= 0;
            C <= 0;
            block_ctr <= 0;
            // $display(L, s, nz_ad);
        end
        else begin
            case(state)

                // IDLE Stage
                IDLE: begin
                    S <= {IV, {(160-k){1'b0}}, key, nonce};
                    if(encryption_start)
                        state <= INITIALIZE;
                end

                // Initialization
                INITIALIZE: begin
                    if(permutation_ready) begin
                        if (l != 0)
                            state <= ASSOCIATED_DATA;
                        else if (l == 0 && y != 0)
                            state <= PTCT;
                        else
                            state <= FINALIZE;
                        S <= P_out ^ {{(320-k){1'b0}}, key};
                    end
                end

                //Processing Associated Data
                ASSOCIATED_DATA: begin
                    if(permutation_ready && block_ctr == s-1) begin
                        if (y != 0)
                            state <= PTCT;
                        else
                            state <= FINALIZE;
                        S <= P_out^({{319{1'b0}}, 1'b1});
                    end
                    else if(permutation_ready && block_ctr != s)
                        S <= P_out;
                    
                    if (permutation_ready && block_ctr == s-1) 
                        block_ctr <= 0;
                    else if(permutation_ready && block_ctr != s)
                        block_ctr <= block_ctr+1; 

                end

                // Processing Plain Text
                PTCT: begin
                    if(block_ctr == t-1) begin
                        state <= FINALIZE;
                        S <= {C_d[r-1:0],Sc};
                        C <= C + C_d;
                    end
                    else if(permutation_ready && block_ctr != t) begin
                        S <= P_out;
                        C <= C + C_d;
                    end

                    if (permutation_ready && block_ctr == t-1) 
                        block_ctr <= 0;
                    else if(permutation_ready && block_ctr != t)
                        block_ctr <= block_ctr + 1; 
                end

                // Finalization
                FINALIZE: begin
                    if(permutation_ready) begin
                        S <= P_out;
                        state <= DONE;
                        Tag <= Tag_d;
                    end
                end

                // Done Stage
                DONE: begin
                    if(encryption_start)
                        state <= IDLE;
                end

                // Invalid state? go to idle
                default: 
                    state <= IDLE;
            endcase
        end
    end

    // Combinational Block
    always @(*) begin
        C_d = 0;
        Tag_d = 0;
        encryption_ready_1 = 0;
        case (state)
            IDLE: begin
                C_d = 0;
                Tag_d = 0;
                encryption_ready_1 = 0;
                permutation_start = 0;
                rounds = a;
                P_in = S;
            end

            INITIALIZE: begin
                C_d = 0;
                Tag_d = 0;
                encryption_ready_1 = 0;
                rounds = a;
                permutation_start = (permutation_ready)? 1'b0: 1'b1;
                P_in = S;
            end
            
            ASSOCIATED_DATA: begin
                C_d = 0;
                encryption_ready_1 = 0;
                rounds = b;
                Tag_d = 0;
                if(permutation_ready && block_ctr == (s-1))
                    permutation_start = 0;
                else
                    permutation_start = 1;

                P_in = {Sr^A[L-1-(block_ctr*r)-:r], Sc};
            end

            PTCT: begin
                encryption_ready_1 = 0;
                rounds = b;
                Tag_d = 0;
                C_d[Y-1-(block_ctr*r)-:r] = Sr ^ P[Y-1-(block_ctr*r)-:r];
                P_in = {Sr ^ P[Y-1-(block_ctr*r)-:r], Sc};
                if(block_ctr == (t-1))
                    permutation_start = 0;
                else
                    permutation_start = 1;
            end

            FINALIZE: begin
                C_d = 0;
                rounds = a;
                P_in = S ^ ({{r{1'b0}},key,{(c-k){1'b0}}});
                permutation_start = (permutation_ready)? 1'b0: 1'b1;
                encryption_ready_1 = 1'b0;
                Tag_d = P_out ^ key;
            end

            DONE: begin
                Tag_d = 0;
                C_d = 0;
                rounds = a;
                P_in = 0;
                permutation_start = 0;
                encryption_ready_1 = 1;
            end

            default: begin
                Tag_d = 0;
                rounds = 0;
                P_in = S;
                permutation_start = 0;
                encryption_ready_1 = 0;
                C_d = 0;
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
    
    // Debugger
    // always @(posedge clk or posedge rst) begin
    //     // $display("State: %d counter: %d block_ctr: %d \n S: %h \n start: %b ready: %b", state, ctr, block_ctr, S, permutation_start, permutation_ready);
    // end
endmodule