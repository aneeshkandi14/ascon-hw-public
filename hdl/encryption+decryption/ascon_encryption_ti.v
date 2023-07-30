// Encryption FSM
module Encryption_ti #(
    parameter k = 128,            // Key size
    parameter r = 128,            // Rate
    parameter a = 12,             // Initialization round no.
    parameter b = 6,              // Intermediate round no.
    parameter l = 40,            // Length of associated data
    parameter y = 40             // Length of Plain Text
)(
    input           clk,
    input           rst,
    input  [k-1:0]  key, random_key_1, random_key_2,
    input  [127:0]  nonce, random_nonce_1, random_nonce_2,
    input  [l-1:0]  associated_data, random_ad_1, random_ad_2,
    input  [y-1:0]  plain_text, random_pt_1, random_pt_2,
    input           encryption_start,
    input  [63:0]   r0,r1,r2,r3,r4,r5,r6,

    output [y-1:0]  cipher_text,            // Plain text converted to cipher text
    output [127:0]  tag,                    // Final Tag after Encryption 
    output          encryption_ready        // To indicate the end of Encryption
);

    // ---------------------------------------------------------------------------------------
    //                                          Constants
    // ---------------------------------------------------------------------------------------
    
    parameter c = 320-r;

    // Associated Data
    parameter nz_ad =  ((l+1)%r == 0)? 0 : r-((l+1)%r);
    parameter L = l+1+nz_ad;
    parameter s = L/r;

    // Plain Text
    parameter nz_p =  ((y+1)%r == 0)? 0 : r-((y+1)%r);
    parameter Y = y+1+nz_p;
    parameter t = Y/r;

    // FSM States
    parameter IDLE              = 'd0,
              INITIALIZE        = 'd1,
              ASSOCIATED_DATA   = 'd2,
              PTCT              = 'd3,
              FINALIZE          = 'd4, 
              DONE              = 'd5;  

    // ---------------------------------------------------------------------------------------
    //                                Storage Buffers and Wire Assignments
    // ---------------------------------------------------------------------------------------

    // General
    reg  [4:0]          rounds;
    reg  [t:0]          block_ctr;  
    reg  [2:0]          state;
    wire [4:0]          ctr;

    // Ascon State
    wire [190-k-1:0]    IV;
    reg  [319:0]        S_0, S_1, S_2;
    wire [r-1:0]        Sr_0, Sr_1, Sr_2;
    wire [c-1:0]        Sc_0, Sc_1, Sc_2;

    // Permutation variables
    reg  [319:0]        P_in_0, P_in_1, P_in_2;
    wire [319:0]        P_out_0, P_out_1, P_out_2;
    wire                permutation_ready;
    reg                 permutation_start;

    // Encryption variables
    wire [L-1:0]        A_0, A_1, A_2;                              // Padded Associated Data
    wire [Y-1:0]        P_0, P_1, P_2;                              // Padded Plain Text
    reg  [Y-1:0]        C_0, C_1, C_2, Cd_0, Cd_1, Cd_2;            // Cipher Text
    reg  [127:0]        Tag_0, Tag_1, Tag_2, Tag_d_0, Tag_d_1, Tag_d_2;
    reg                 encryption_ready_1;

    // Assigning Wires
    assign IV = k << 24 | r << 16 | a << 8 | b;

    assign {Sr_0,Sc_0} = S_0;
    assign {Sr_1,Sc_1} = S_1;
    assign {Sr_2,Sc_2} = S_2;

    assign encryption_ready = encryption_ready_1;

    assign A_0 = {random_ad_1, 1'b1, {nz_ad{1'b0}}};
    assign A_1 = {random_ad_2, 1'b1, {nz_ad{1'b0}}};
    assign A_2 = {(random_ad_1 ^ random_ad_2 ^ associated_data), 1'b1, {nz_ad{1'b0}}};

    assign P_0 = {random_pt_1, 1'b1, {nz_p{1'b0}}};
    assign P_1 = {random_pt_2, 1'b1, {nz_p{1'b0}}};
    assign P_2 = {(plain_text ^ random_pt_1 ^ random_pt_2), 1'b1, {nz_p{1'b0}}};

    assign tag = (encryption_ready_1)? (Tag_0 ^ Tag_1 ^ Tag_2) : 0;
    if (y>0)
        assign cipher_text = (encryption_ready_1)? (C_0[Y-1 -: y] ^ C_1[Y-1 -: y] ^ C_2[Y-1 -: y]) : 0;
    else
        assign cipher_text = 0;

    // ---------------------------------------------------------------------------------------
    //                                      State Updater
    // ---------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if(rst) 
            state <= IDLE;
        else begin
            case(state)
                IDLE: begin
                    if(encryption_start)
                        state <= INITIALIZE;
                end
                
                INITIALIZE: begin
                    if(permutation_ready)
                        if (l != 0)
                            state <= ASSOCIATED_DATA;
                        else if (l == 0 && y != 0)
                            state <= PTCT;
                        else 
                            state <= FINALIZE;
                end

                ASSOCIATED_DATA: begin
                    if(permutation_ready && block_ctr == s-1)
                        if (y != 0)
                            state <= PTCT;
                        else 
                            state <= FINALIZE;
                end

                PTCT: begin
                    if(block_ctr == t-1)
                        state <= FINALIZE;
                end

                FINALIZE: begin
                    if(permutation_ready)
                        state <= DONE;
                end

                DONE: begin
                    if(encryption_start)
                        state <= IDLE;
                end

                default: 
                    state <= IDLE;
            endcase
        end
    end

    // ---------------------------------------------------------------------------------------
    //                                  FSM Starts here
    // ---------------------------------------------------------------------------------------

    // Sequential Block
    always @(posedge clk) begin
        if(rst) begin
            {S_0, S_1, S_2} <= 0;
            {Tag_0, Tag_1, Tag_2} <= 0;
            {C_0, C_1, C_2} <= 0;
            block_ctr <= 0;
        end
        else begin
            case(state)

                // IDLE Stage
                IDLE: begin
                    S_0 <= {IV, {(160-k){1'b0}}, random_key_1, random_nonce_1};
                    S_1 <= {IV, {(160-k){1'b0}}, random_key_2, random_nonce_2};
                    S_2 <= {IV, {(160-k){1'b0}}, (key ^ random_key_1 ^ random_key_2), (nonce ^ random_nonce_1 ^ random_nonce_2)};
                end

                // Initialization
                INITIALIZE: begin
                    if(permutation_ready) begin
                        S_0 <= P_out_0 ^ {{(320-k){1'b0}}, random_key_1};
                        S_1 <= P_out_1 ^ {{(320-k){1'b0}}, random_key_2};
                        S_2 <= P_out_2 ^ {{(320-k){1'b0}}, (random_key_1 ^ random_key_2 ^ key)};
                    end
                end

                //Processing Associated Data
                ASSOCIATED_DATA: begin
                    if(permutation_ready && block_ctr == s-1) begin
                        S_0 <= P_out_0 ^ {{319{1'b0}}, 1'b1};
                        S_1 <= P_out_1 ^ {{319{1'b0}}, 1'b1};
                        S_2 <= P_out_2 ^ {{319{1'b0}}, 1'b1};
                    end
                    else if(permutation_ready && block_ctr != s) begin
                        S_0 <= P_out_0;
                        S_1 <= P_out_1;
                        S_2 <= P_out_2;    
                    end
                    
                    if (permutation_ready && block_ctr == s-1) 
                        block_ctr <= 0;
                    else if(permutation_ready && block_ctr != s)
                        block_ctr <= block_ctr + 1; 

                end

                // Processing Plain Text
                PTCT: begin
                    if(block_ctr == t-1) begin
                        S_0 <= {Cd_0[r-1:0],Sc_0};
                        S_1 <= {Cd_1[r-1:0],Sc_1};
                        S_2 <= {Cd_2[r-1:0],Sc_2};
                        C_0 <= C_0 + Cd_0;
                        C_1 <= C_1 + Cd_1;
                        C_2 <= C_2 + Cd_2;
                    end
                    else if(permutation_ready && block_ctr != t) begin
                        S_0 <= P_out_0;
                        S_1 <= P_out_1;
                        S_2 <= P_out_2;
                        C_0 <= C_0 + Cd_0;
                        C_1 <= C_1 + Cd_1;
                        C_2 <= C_2 + Cd_2;
                    end

                    if (permutation_ready && block_ctr == t-1) 
                        block_ctr <= 0;
                    else if(permutation_ready && block_ctr != t)
                        block_ctr <= block_ctr + 1; 
                end

                // Finalization
                FINALIZE: begin
                    if(permutation_ready) begin
                        S_0 <= P_out_0;
                        S_1 <= P_out_1;
                        S_2 <= P_out_2;
                        {Tag_0, Tag_1, Tag_2} <= {Tag_d_0, Tag_d_1, Tag_d_2};
                    end

                end
            endcase
        end
    end

    // Combinational Block
    always @(*) begin
        {Cd_0, Cd_1, Cd_2} = 0;
        {Tag_d_0, Tag_d_1, Tag_d_2} = 0;
        encryption_ready_1 = 0;
        case (state)
            IDLE: begin
                permutation_start = 0;
                rounds = a;
                P_in_0 = S_0;
                P_in_1 = S_1;
                P_in_2 = S_2;
            end

            INITIALIZE: begin
                rounds = a;
                permutation_start = (permutation_ready)? 1'b0: 1'b1;
                P_in_0 = S_0;
                P_in_1 = S_1;
                P_in_2 = S_2;
            end
            
            ASSOCIATED_DATA: begin
                rounds = b;
                if(permutation_ready && block_ctr == (s-1))
                    permutation_start = 0;
                else
                    permutation_start = 1;

                P_in_0 = {Sr_0 ^ A_0[L-1-(block_ctr*r)-:r], Sc_0};
                P_in_1 = {Sr_1 ^ A_1[L-1-(block_ctr*r)-:r], Sc_1};
                P_in_2 = {Sr_2 ^ A_2[L-1-(block_ctr*r)-:r], Sc_2};
            end

            PTCT: begin
                rounds = b;
                Cd_0[Y-1-(block_ctr*r)-:r] = Sr_0 ^ P_0[Y-1-(block_ctr*r)-:r];
                Cd_1[Y-1-(block_ctr*r)-:r] = Sr_1 ^ P_1[Y-1-(block_ctr*r)-:r];
                Cd_2[Y-1-(block_ctr*r)-:r] = Sr_2 ^ P_2[Y-1-(block_ctr*r)-:r];

                P_in_0 = {Cd_0[Y-1-(block_ctr*r)-:r], Sc_0};
                P_in_1 = {Cd_1[Y-1-(block_ctr*r)-:r], Sc_1};
                P_in_2 = {Cd_2[Y-1-(block_ctr*r)-:r], Sc_2};

                if(block_ctr == (t-1))
                    permutation_start = 0;
                else
                    permutation_start = 1;
            end

            FINALIZE: begin
                rounds = a;
                P_in_0 = S_0 ^ ({{r{1'b0}}, random_key_1,{(c-k){1'b0}}});
                P_in_1 = S_1 ^ ({{r{1'b0}}, random_key_2,{(c-k){1'b0}}});
                P_in_2 = S_2 ^ ({{r{1'b0}}, (key ^ random_key_1 ^ random_key_2),{(c-k){1'b0}}});

                permutation_start = (permutation_ready)? 1'b0: 1'b1;
                encryption_ready_1 = 0;
                Tag_d_0 = P_out_0 ^ random_key_1;
                Tag_d_1 = P_out_1 ^ random_key_2;
                Tag_d_2 = P_out_2 ^ (random_key_1 ^ random_key_2 ^ key);
            end

            DONE: begin
                rounds = a;
                P_in_0 = S_0;
                P_in_1 = S_1;
                P_in_2 = S_2;
                permutation_start = 0;
                encryption_ready_1 = 1;
            end

            default: begin
                rounds = 0;
                P_in_0 = S_0;
                P_in_1 = S_1;
                P_in_2 = S_2;
                permutation_start = 0;
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

    // ---------------------------------------------------------------------------------------
    //                                  Debugger
    // ---------------------------------------------------------------------------------------

    // always @(posedge clk or posedge rst) begin
    //     // $display("State: %d counter: %d block_ctr: %d \n S: %h \n start: %b ready: %b", state, ctr, block_ctr, S, permutation_start, permutation_ready);
    // end
endmodule