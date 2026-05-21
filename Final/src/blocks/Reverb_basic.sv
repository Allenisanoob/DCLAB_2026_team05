module Reverb_basic(
    input                i_clk,
    input                i_rst,
    input                i_valid,
    input         [23:0] r, // Q0.24
    input signed  [15:0] i_cosw, // Q1.15
    input         [7:0]  w_rate, // Q0.8
    input signed  [15:0] i_data, // Q16.0
    output               o_valid,
    output signed [15:0] o_data // Q16.0
);

    logic        [23:0] r_r, r_w; // Q0.24
    logic signed [15:0] i_cosw_r, i_cosw_w; // Q1.15
    logic        [7:0]  w_rate_r, w_rate_w; // Q0.8
    logic signed [15:0] i_data_r, i_data_w; // Q16.0
    logic               state_r, state_w;
    logic               o_valid_r, o_valid_w;
    logic signed [15:0] o_data_r, o_data_w; // Q16.0
    logic signed [15:0] x1_r, x1_w, y1_r, y1_w, y2_r, y2_w; // Q16.0

    localparam IDLE = 1'b0, CALC = 1'b1;

    assign o_valid = o_valid_r;
    assign o_data  = o_data_r;

    // y1_w = i_data_r + r_r  * i_cosw_r * (2 * y1_r - x1_r) - r_r * r_r * y2_r
    // o_data_w = i_data_r + w_rate_r * (r_r  * i_cosw_r * (2 * y1_r - x1_r) - r_r * r_r * y2_r)

    logic signed [40:0] A; // Q2.39
    logic        [47:0] B; // Q0.48
    logic signed [17:0] C; // Q18.0
    logic signed [58:0] D; // Q20.39
    logic signed [64:0] E; // Q17.48
    logic signed [68:0] F; // Q21.48
    logic signed [77:0] G; // Q22.56
    logic signed [20:0] H; // Q21.0
    logic signed [21:0] I; // Q22.0
    logic signed [21:0] J; // Q22.0
    logic signed [22:0] K; // Q23.0

    always_comb begin
        r_w       = r_r;
        i_cosw_w  = i_cosw_r;
        w_rate_w  = w_rate_r;
        i_data_w  = i_data_r;
        state_w   = state_r;
        o_valid_w = o_valid_r;
        o_data_w  = o_data_r;
        x1_w      = x1_r;
        y1_w      = y1_r;
        y2_w      = y2_r;
        A = $signed($signed({1'b0, r_r}) * i_cosw_r); // Q2.39
        B = r_r * r_r; // Q0.48
        C = $signed($signed({y1_r[15], y1_r, 1'b0}) - $signed({2{x1_r[15]}, x1_r})); // Q18.0
        D = $signed(A * C); // Q20.39
        E = $signed($signed({1'b0, B}) * y2_r); // Q17.48
        F = $signed($signed({D[58], D, 9'd0}) - $signed({4{E[64]}, E})); // Q21.48
        G = $signed($signed({1'b0, w_rate_r}) * F); // Q22.56
        H = $signed($signed(F[68:48]) + $signed({20'd0, F[47]})); // Q21.0
        I = $signed($signed(G[77:56]) + $signed({21'd0, G[55]})); // Q22.0
        J = $signed($signed({H[20], H}) + $signed({6{i_data_r[15]}, i_data_r})); // Q22.0
        K = $signed($signed({I[21], I}) + $signed({7{i_data_r[15]}, i_data_r})); // Q23.0
        case (state_r)
            IDLE: begin
                if (i_valid) begin
                    r_w       = r;
                    i_cosw_w  = i_cosw;
                    w_rate_w  = w_rate;
                    i_data_w  = i_data;
                    state_w   = CALC;
                end
                o_valid_w = 1'b0;
                o_data_w  = 16'sd0;
            end
            CALC: begin
                state_w   = IDLE;
                o_valid_w = 1'd1;
                if (K > 23'sd32767) begin
                    o_data_w = 16'sd32767;
                end else if (K < -23'sd32768) begin
                    o_data_w = -16'sd32768;
                end else begin
                    o_data_w = $signed(K[15:0]);
                end
                x1_w = i_data_r;
                if (J > 22'sd32767) begin
                    y1_w = 16'sd32767;
                end else if (J < -22'sd32768) begin
                    y1_w = -16'sd32768;
                end else begin
                    y1_w = $signed(J[15:0]);
                end
                y2_w = y1_r;
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            r_r       <= 24'd0;
            i_cosw_r  <= 16'd0;
            w_rate_r  <= 8'd0;
            i_data_r  <= 16'sd0;
            state_r   <= IDLE;
            o_valid_r <= 1'd0;
            o_data_r  <= 16'sd0;
            x1_r      <= 16'sd0;
            y1_r      <= 16'sd0;
            y2_r      <= 16'sd0;
        end else begin
            r_r       <= r_w;
            i_cosw_r  <= i_cosw_w;
            w_rate_r  <= w_rate_w;
            i_data_r  <= i_data_w;
            state_r   <= state_w;
            o_valid_r <= o_valid_w;
            o_data_r  <= o_data_w;
            x1_r      <= x1_w;
            y1_r      <= y1_w;
            y2_r      <= y2_w;
        end
    end

endmodule