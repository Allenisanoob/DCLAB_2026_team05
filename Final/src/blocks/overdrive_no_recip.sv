`timescale 1ns/1ps
module Overdrive (
    input                      i_clk,
    input                      i_rst,      // active-low reset
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [9:0]  i_gain,     // Q4.6 (Unsigned)
    input                      i_en,
    output       logic signed [15:0] o_data,    // Q1.15 (Signed)
    output       logic         o_en
);

    // ==========================================
    // Stage 0: input register
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [9:0]  i_gain_r;
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
    logic        [9:0]  i_gain_r2;
    logic               i_en_r2;

    // ==========================================
    // Output selection signal
    // ==========================================
    logic signed [15:0] overdrive_out;

    // ==========================================
    // Submodule instantiation
    // No recip_tanh normalization is used here.
    // Output = tanh(gain * input), except small-gain bypass.
    // ==========================================
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
            i_gain_r      <= 10'd0;
            i_en_r        <= 1'b0;

            tanh_unnorm_r <= 16'sd0;
            i_data_r2     <= 16'sd0;
            i_gain_r2     <= 10'd0;
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
    // Combinational logic: no normalization
    // Uses pipelined tanh_unnorm_r.
    // ==========================================
    always_comb begin
        if (i_gain_r2 <= 10'd4) begin
            // Bypass path must use the data delayed to the same stage.
            overdrive_out = i_data_r2;
        end else begin
            // No recip_tanh normalization:
            // directly use tanh output, already Q1.15 signed.
            overdrive_out = tanh_unnorm_r >>> 1;
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
                o_data <= overdrive_out;
            end
        end
    end

endmodule
