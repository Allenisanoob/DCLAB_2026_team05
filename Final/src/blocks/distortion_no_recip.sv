`timescale 1ns/1ps
module distortion (
    input                      i_clk,
    input                      i_rst,      // active-low reset
    input        signed [15:0] i_data,     // Q1.15 signed
    input               [7:0]  i_gain,     // Q2.6 unsigned
    input                      i_en,
    output       logic signed [15:0] o_data,
    output       logic         o_en
);

    // Hard clipping threshold: about 90% of Q1.15 full scale
    localparam signed [31:0] CLIP_MAX = 32'sd29491;
    localparam signed [31:0] CLIP_MIN = -32'sd29491;

    // ==========================================
    // Stage 0: input register
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [7:0]  i_gain_r;
    logic               i_en_r;

    // ==========================================
    // Submodule raw output
    // ==========================================
    logic signed [15:0] tanh_unnorm_w;

    // ==========================================
    // Stage 1: pipeline registers after tanh
    // ==========================================
    logic signed [15:0] tanh_unnorm_r;
    logic signed [15:0] i_data_r2;
    logic        [7:0]  i_gain_r2;
    logic               i_en_r2;

    logic signed [31:0] tanh_unnorm_ext;
    logic signed [31:0] y_boosted;
    logic signed [15:0] dist_out;

    // No recip_tanh normalization is used here.
    // tanh_unnorm is directly boosted and hard-clipped.
    tanh u_tanh (
        .i_data (i_data_r),
        .i_gain (i_gain_r),
        .o_data (tanh_unnorm_w)
    );

    // ==========================================
    // Pipeline registers
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            i_data_r      <= 16'sd0;
            i_gain_r      <= 8'd0;
            i_en_r        <= 1'b0;

            tanh_unnorm_r <= 16'sd0;
            i_data_r2     <= 16'sd0;
            i_gain_r2     <= 8'd0;
            i_en_r2       <= 1'b0;
        end else begin
            // Stage 0: capture input sample/gain/valid
            i_data_r <= i_data;
            i_gain_r <= i_gain;
            i_en_r   <= i_en;

            // Stage 1: register output from tanh.
            // Also delay data/gain/en by the same one cycle for alignment.
            tanh_unnorm_r <= tanh_unnorm_w;
            i_data_r2     <= i_data_r;
            i_gain_r2     <= i_gain_r;
            i_en_r2       <= i_en_r;
        end
    end

    // ==========================================
    // Combinational logic: boost + hard clipping
    // Uses pipelined tanh_unnorm_r.
    // ==========================================
    always_comb begin
        tanh_unnorm_ext = 32'sd0;
        y_boosted       = 32'sd0;
        dist_out        = 16'sd0;

        if (i_gain_r2 <= 8'd4) begin
            // Bypass path must use the data delayed to the same stage.
            dist_out = i_data_r2;
        end else begin
            // 1. No recip_tanh normalization.
            // Sign-extend Q1.15 tanh output to 32-bit, then boost by 2x.
            tanh_unnorm_ext = $signed({{16{tanh_unnorm_r[15]}}, tanh_unnorm_r});
            y_boosted       = tanh_unnorm_ext <<< 1;

            // 2. Hard clipping
            if (y_boosted > CLIP_MAX) begin
                dist_out = 16'sd29491;
            end else if (y_boosted < CLIP_MIN) begin
                dist_out = -16'sd29491;
            end else begin
                dist_out = y_boosted[15:0];
            end
        end
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            o_data <= 16'sd0;
            o_en   <= 1'b0;
        end else begin
            o_en <= i_en_r2;
            if (i_en_r2) begin
                o_data <= dist_out >>> 1;
            end
        end
    end

endmodule
