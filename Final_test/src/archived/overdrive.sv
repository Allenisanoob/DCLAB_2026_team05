`timescale 1ns/1ps
module Overdrive (
    input                      i_clk,
    input                      i_rst,      // active-low reset
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [7:0]  i_gain,     // Q2.6 (Unsigned)
    input                      i_en,
    output       logic signed [15:0] o_data,    // Q1.15 (Signed)
    output       logic         o_en
);

    // ==========================================
    // Stage 0: input register
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [7:0]  i_gain_r;
    logic               i_en_r;

    // ==========================================
    // Submodule raw outputs
    // ==========================================
    logic signed [15:0] tanh_unnorm_w;
    logic        [15:0] recip_tanh_val_w;

    // ==========================================
    // Stage 1: pipeline registers after tanh / recip_tanh
    // ==========================================
    logic signed [15:0] tanh_unnorm_r;
    logic        [15:0] recip_tanh_val_r;
    logic signed [15:0] i_data_r2;
    logic        [7:0]  i_gain_r2;
    logic               i_en_r2;

    // ==========================================
    // Normalization signals
    // ==========================================
    logic signed [32:0] y_norm_full;
    logic signed [15:0] Overdrive_out;

    // ==========================================
    // Submodule instantiation
    // ==========================================
    tanh u_tanh (
        .i_data (i_data_r),
        .i_gain (i_gain_r),
        .o_data (tanh_unnorm_w)
    );

    recip_tanh u_recip_tanh (
        .i_gain         (i_gain_r),
        .o_recip_tanh_val (recip_tanh_val_w)
    );

    // ==========================================
    // Pipeline registers
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            i_data_r       <= 16'sd0;
            i_gain_r       <= 8'd0;
            i_en_r         <= 1'b0;

            tanh_unnorm_r  <= 16'sd0;
            recip_tanh_val_r <= 16'd0;
            i_data_r2      <= 16'sd0;
            i_gain_r2      <= 8'd0;
            i_en_r2        <= 1'b0;
        end else begin
            // Stage 0: capture input sample/gain/valid
            i_data_r <= i_data;
            i_gain_r <= i_gain;
            i_en_r   <= i_en;

            // Stage 1: register outputs from tanh and recip_tanh
            // Also delay data/gain/en by the same one cycle for alignment.
            tanh_unnorm_r  <= tanh_unnorm_w;
            recip_tanh_val_r <= recip_tanh_val_w;
            i_data_r2      <= i_data_r;
            i_gain_r2      <= i_gain_r;
            i_en_r2        <= i_en_r;
        end
    end

    // ==========================================
    // Combinational logic: normalization + saturation
    // Uses pipelined tanh_unnorm_r / recip_tanh_val_r.
    // ==========================================
    always_comb begin
        Overdrive_out = 16'sd0;
        y_norm_full   = 33'sd0;

        if (i_gain_r2 <= 8'd4) begin
            // bypass path must use the data delayed to the same stage
            Overdrive_out = i_data_r2;
        end else begin
            // Q1.15 signed * Q8.9 signed = Q9.24 signed
            y_norm_full = tanh_unnorm_r * $signed({1'b0, recip_tanh_val_r});

            // Q9.24 -> Q1.15: round, shift right by 9, then saturate
            if (y_norm_full > 33'sd16776447) begin
                Overdrive_out = 16'sd32767;
            end else if (y_norm_full < -33'sd16777216) begin
                Overdrive_out = -16'sd32768;
            end else begin
                if (y_norm_full >= 0)
                    Overdrive_out = (y_norm_full + 33'sd256) >>> 9;
                else
                    Overdrive_out = (y_norm_full - 33'sd256) >>> 9;
            end
        end
    end

    // ==========================================
    // Output register
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            o_data <= 16'sd0;
            o_en   <= 1'b0;
        end else begin
            o_en <= i_en_r2;
            if (i_en_r2) begin
                o_data <= Overdrive_out;
            end
        end
    end

endmodule
