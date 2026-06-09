`timescale 1ns/1ps

// =========================================================================
// Module: Overdrive_opt
// Description:
//   這是一個基於 Signalsmith Audio "Warm Distortion" 演算法的破音效果器模組。
//   為了達到平滑的真空管破音音色，並避免數位硬切 (Hard-clipping) 產生的刺耳雜訊，
//   本模組將傳統的 Waveshaper 公式拆解為「增益訊號 (g)」並乘回原訊號。
//
// Algorithm:
//   1. x = i_data * i_gain        (輸入前級放大)
//   2. v = x * i_recip_L          (將除法 L 改為乘上 1/L，計算撞擊天花板的比例)
//   3. g = tanh(v)/v              (透過查表計算動態衰減增益)
//   4. y = x * g                  (套用增益，得最終溫暖破音輸出)
//
// Pipeline Architecture (4-Stage):
//   - Stage 0: 鎖存輸入訊號 (Latch Inputs)
//   - Stage 1: 計算 x 與 v，並對 v 進行捨入與對稱絕對值處理
//   - Stage 2: 查表 (LUT) 執行，硬體延遲 1 Cycle
//   - Stage 3: 將 x 與查表得到的 g 相乘，並捨入/飽和回 Q1.15 輸出
// =========================================================================

module Overdrive_opt (
    input                      i_clk,
    input                      i_rst,
    input        signed [15:0] i_data,     // 輸入音訊：Signed Q1.15 (範圍 -1.0 ~ 0.999)
    input               [7:0]  i_gain,     // 破音推力：Unsigned Q2.6 (範圍 0 ~ 3.98)
    input               [15:0] i_recip_L,  // 倒數天花板：Unsigned Q8.8 (由外部 MCU 算好 1/L 傳入)
    input                      i_en,       // 輸入有效訊號 (Valid)
    output       logic signed [15:0] o_data, // 輸出音訊：Signed Q1.15
    output       logic         o_en        // 輸出有效訊號 (與 o_data 對齊)
);

    // ==========================================
    // Stage 0: 鎖存輸入 (Latch Inputs)
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [7:0]  i_gain_r;
    logic               [15:0] i_recip_L_r;
    logic               i_en_r1;
    logic               i_en_r2;

    // ==========================================
    // Pipeline Data Registers (跨 Stage 傳遞的資料)
    // ==========================================
    // x 需要保留極大的動態範圍，以防止過早截斷導致硬破音 (Hard-clipping)
    logic signed [31:0] x_r2, x_r3;        // 放大後的輸入：Signed Q17.15
    logic        [15:0] abs_v_r2;          // 撞擊比例的絕對值：Unsigned Q5.11

    // ==========================================
    // LUT Instantiation (h(v) = tanh(v)/v)
    // 假設這是一個 1-cycle latency 的 Base+Delta 插值 ROM
    // ==========================================
    // 必須明確宣告為 signed，否則後續 Stage 3 乘法會把 x_r3 也誤判為 unsigned
    logic signed [15:0] lut_g_out_w;       // 查表輸出的增益 g：Signed Q1.15
    logic               lut_en_out_w;      // 查表模組吐出的 Enable 訊號 (已 Delay 1 cycle)
    
    lut_h_tanh_div_v u_lut_h (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        // 只傳遞低 15 bits 給 LUT (因為絕對值最大被我們鎖死在 32767)
        .i_abs_v (abs_v_r2[14:0]),         // Input: Unsigned Q4.11
        .i_en    (i_en_r2),                // Input Enable (Stage 2)
        .o_g     (lut_g_out_w),            // Output: Signed Q1.15 (Stage 3)
        .o_en    (lut_en_out_w)            // Output Enable (Stage 3)
    );

    // ==========================================
    // Symmetric Rounding Function (對稱捨入函數)
    // 解決標準 Arithmetic Shift (>>>) 對負數偏向負無限大的 DC Offset 問題。
    // ==========================================
    // 寬度加大到 64-bit，這是為了包容 49-bit 的 v_full，避免呼叫時被截斷正負號反轉
    function automatic logic signed [63:0] sym_round(
        input logic signed [63:0] val,         // 原始高精度數值
        input logic signed [63:0] half_lsb,    // 用於四捨五入的 0.5 (Half LSB)
        input int shift_bits                   // 需要右移的小數位數
    );
        logic signed [63:0] abs_val, rounded_abs;
        begin
            if (val >= 0) begin
                sym_round = (val + half_lsb) >>> shift_bits;
            end else begin
                abs_val = -val;
                rounded_abs = (abs_val + half_lsb) >>> shift_bits;
                sym_round = -rounded_abs;
            end
        end
    endfunction

    // ==========================================
    // Pipeline Registers 控制區塊
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            // Reset logic
            i_data_r    <= 16'sd0;
            i_gain_r    <= 8'd0;
            i_recip_L_r <= 16'd0;
            i_en_r1     <= 1'b0; 
            i_en_r2     <= 1'b0; 
            
            x_r2        <= 32'sd0; 
            x_r3        <= 32'sd0;
            abs_v_r2    <= 16'd0;
            
            o_data      <= 16'sd0;
            o_en        <= 1'b0;
        end else begin
            // ----------------------------------
            // Stage 0 -> Stage 1: 鎖存外部輸入
            // ----------------------------------
            i_data_r    <= i_data;
            i_gain_r    <= i_gain;
            i_recip_L_r <= i_recip_L;
            i_en_r1     <= i_en;

            // ----------------------------------
            // Stage 1 -> Stage 2: 儲存算好的 x 與 v
            // ----------------------------------
            x_r2        <= x_q15_w;
            abs_v_r2    <= abs_v_q511_w;
            i_en_r2     <= i_en_r1;

            // ----------------------------------
            // Stage 2 -> Stage 3: x 繼續跟著 Pipeline 走
            // (註: g 與 en 已經交由 LUT 內部做 1 Cycle delay)
            // ----------------------------------
            x_r3        <= x_r2;

            // ----------------------------------
            // Stage 3 -> Output: 最終輸出
            // ----------------------------------
            // 接住 LUT 吐出來的 Valid 訊號，若有效則更新輸出
            if (lut_en_out_w) begin
                o_data <= o_data_w;
            end
            o_en <= lut_en_out_w;
        end
    end

    // ==========================================
    // Combinational Logic 運算區塊
    // ==========================================
    
    // --- Stage 1: 計算 x 與 v ---
    logic signed [31:0] x_mult;
    logic signed [31:0] x_q15_w;
    logic signed [48:0] v_full;
    logic signed [48:0] v_rounded;
    logic        [15:0] abs_v_q511_w;

    always_comb begin
        // 1. 計算 x = i_data * i_gain
        // 格式對應：Q1.15 * UQ2.6 = Q3.21 -> 右移 6 位 -> Q17.15 (利用 32-bit 保留大動態)
        // 擴展 {1'b0, i_gain_r} 是為了確保 Verilog 將 i_gain 當作正的有號數參與 signed 乘法
        x_mult = i_data_r * $signed({1'b0, i_gain_r});
        x_q15_w = x_mult >>> 6; 

        // 2. 計算 v = x * (1/L)
        // 格式對應：Q17.15 * UQ8.8 = Signed Q26.23 (總共需要 49 bits)
        v_full = x_q15_w * $signed({1'b0, i_recip_L_r});

        // 3. 將 v 捨入至 Q5.11 格式 (Shift right by 12)
        // Half LSB = 2^11 = 2048
        // sym_round 參數會被自動擴展成 64-bit 進行安全運算
        v_rounded = sym_round(v_full, 49'sd2048, 12);

        // 4. 飽和保護 (Saturate) 並取絕對值 (Absolute)
        // 目標：鎖定在 Signed Q5.11 範圍內 [-16.0, 15.999]
        //  必須鎖定在正負 32767，確保絕對值轉換後完美符合 [14:0] 15 bits 的空間，防止變為 0
        if (v_rounded > 49'sd32767) begin
            abs_v_q511_w = 16'd32767;
        end else if (v_rounded < -49'sd32767) begin
            abs_v_q511_w = 16'd32767; 
        end else begin
            // 轉為絕對值，準備在 Stage 2 餵給 LUT 查表
            abs_v_q511_w = (v_rounded < 0) ? -v_rounded[15:0] : v_rounded[15:0];
        end
    end

    // --- Stage 3: 計算 y = x * g ---
    logic signed [47:0] o_full;
    logic signed [47:0] o_rounded;
    logic signed [15:0] o_data_w;

    always_comb begin
        // 1. 執行相乘 y = x * g
        // 格式對應：Q17.15 * Signed Q1.15 = Signed Q19.30 (48 bits)
        // 因 lut_g_out_w 已修正為 signed，此處為安全的有號數乘法
        o_full = x_r3 * lut_g_out_w;

        // 2. 捨入回最終輸出格式 Q1.15 (Shift right by 15)
        // Half LSB = 2^14 = 16384
        o_rounded = sym_round(o_full, 48'sd16384, 15);

        // 3. 最終飽和保護 (防止極端推波情況下溢出 Q1.15)
        if (o_rounded > 48'sd32767)       
            o_data_w = 16'sd32767;
        else if (o_rounded < -48'sd32768) 
            o_data_w = -16'sd32768;
        else                              
            o_data_w = o_rounded[15:0];
    end

endmodule