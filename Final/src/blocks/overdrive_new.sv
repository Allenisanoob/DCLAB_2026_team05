`timescale 1ns/1ps
module Overdrive (
    input                      i_clk,
    input                      i_rst,      // active-low reset
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [7:0]  i_gain,     // Q2.6 (Unsigned)
    input        signed [15:0] i_L,        // Q1.15 (Signed, 正數) - 新增的天花板 L
    input                      i_en,
    output       logic signed [15:0] o_data,    // Q1.15 (Signed)
    output       logic         o_en
);

    // ==========================================
    // Stage 0: Input Registers
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [7:0]  i_gain_r;
    logic signed [15:0] i_L_r;
    logic               i_en_r;

    // ==========================================
    // Stage 1: x & v calculations
    // ==========================================
    logic signed [31:0] x_full;
    logic signed [31:0] x_q15_w;
    logic signed [31:0] x_r1;

    logic signed [31:0] v_full;
    logic signed [15:0] v_q115_w;
    logic signed [15:0] v_r1;
    logic               en_r1;

    // ==========================================
    // Tanh Submodule Output
    // ==========================================
    logic signed [15:0] tanh_w;

    // ==========================================
    // Stage 2: g (gain) calculation
    // ==========================================
    logic signed [31:0] g_full;
    logic signed [15:0] g_q115_w;
    logic signed [15:0] g_r2;
    logic signed [31:0] x_r2;
    logic               en_r2;

    // ==========================================
    // Stage 3: LPF & Output formatting
    // ==========================================
    logic signed [15:0] g_smoothed;
    logic signed [47:0] o_full; 
    logic signed [47:0] o_shifted;
    logic signed [15:0] o_data_w;

    // ==========================================
    // Submodule instantiation
    // ==========================================
    // 傳入 v = (x/L)，獲得 tanh(v)
    tanh u_tanh (
        .i_data (v_r1),
        .i_gain (8'd64),  // i_gain 固定為 1.0 (Q2.6 的 64)，因為增益已經在外部乘過了
        .o_data (tanh_w)
    );

    // 註：因為直接計算出衰減增益 g，不需要原本的 u_recip_tanh 了，已移除以節省資源。

    // ==========================================
    // Pipeline Registers
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            i_data_r <= 16'sd0;
            i_gain_r <= 8'd0;
            i_L_r    <= 16'sd0;
            i_en_r   <= 1'b0;

            x_r1     <= 32'sd0;
            v_r1     <= 16'sd0;
            en_r1    <= 1'b0;

            x_r2     <= 32'sd0;
            g_r2     <= 16'sd0;
            en_r2    <= 1'b0;

            o_data   <= 16'sd0;
            o_en     <= 1'b0;
        end else begin
            // Stage 0: Latch Inputs
            i_data_r <= i_data;
            i_gain_r <= i_gain;
            i_L_r    <= i_L;
            i_en_r   <= i_en;

            // Stage 1: Store x and v
            x_r1  <= x_q15_w;
            v_r1  <= v_q115_w;
            en_r1 <= i_en_r;

            // Stage 2: Store dynamic gain g and propagate x
            x_r2  <= x_r1;
            g_r2  <= g_q115_w;
            en_r2 <= en_r1;

            // Stage 3: Output
            o_en <= en_r2;
            if (en_r2) begin
                o_data <= o_data_w;
            end
        end
    end

    // ==========================================
    // Combinational Logic Block
    // ==========================================
    always_comb begin
        // ---------------------------------
        // Stage 1: x = i_data * i_gain
        // ---------------------------------
        // Q1.15 * Q2.6 = Q3.21 -> 右移 6 轉為 Q17.15 (用 32-bit 保存大動態範圍)
        x_full  = i_data_r * $signed({1'b0, i_gain_r});
        x_q15_w = x_full >>> 6;

        // ---------------------------------
        // Stage 1: v = x / L
        // ---------------------------------
        if (i_L_r <= 16'sd0) begin
            v_full = 32'sd0; // 防止除以零
        end else begin
            v_full = (x_q15_w <<< 15) / i_L_r; // 注意：這裡使用行為級除法 '/'
        end

        // 飽和保護至 Q1.15
        if (v_full > 32'sd32767)       v_q115_w = 16'sd32767;
        else if (v_full < -32'sd32768) v_q115_w = -16'sd32768;
        else                           v_q115_w = v_full[15:0];

        // ---------------------------------
        // Stage 2: g = tanh(v) / v
        // ---------------------------------
        if (v_r1 >= -16'sd5 && v_r1 <= 16'sd5) begin
            // 等同於 C++ 中的 if(abs(v) < 1e-5f) g = 1.0f;
            g_q115_w = 16'sd32767; 
        end else begin
            g_full = (tanh_w <<< 15) / v_r1; // 注意：這裡使用行為級除法 '/'

            // g 是衰減係數，正常應介於 0~1.0 之間
            if (g_full > 32'sd32767)       g_q115_w = 16'sd32767;
            else if (g_full < -32'sd32768) g_q115_w = -16'sd32768;
            else                           g_q115_w = g_full[15:0];
        end

        // ---------------------------------
        // Stage 3: Lowpass Filter (LPF) 插槽
        // ---------------------------------
        // ★★★ 文章後半段的精華 ★★★
        // 在這裡你可以對管線化的 g_r2 加上一階低通濾波器
        // 範例概念：g_smoothed = (g_r2 * alpha) + (g_prev * (1-alpha))
        
        g_smoothed = g_r2; // 目前先 Bypass，直接使用算出來的 g

        // ---------------------------------
        // Stage 3: o_data = x * g_smoothed
        // ---------------------------------
        // Q17.15 * Q1.15 = Q18.30
        o_full = x_r2 * g_smoothed;

        // 轉回 Q1.15 (加上 1<<14 做四捨五入)
        if (o_full >= 0) o_full = o_full + 48'sd16384;
        else             o_full = o_full - 48'sd16384;

        o_shifted = o_full >>> 15;

        // 最終飽和保護
        if (o_shifted > 48'sd32767)       o_data_w = 16'sd32767;
        else if (o_shifted < -48'sd32768) o_data_w = -16'sd32768;
        else                              o_data_w = o_shifted[15:0];
    end

endmodule