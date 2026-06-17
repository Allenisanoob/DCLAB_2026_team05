`timescale 1ns/1ps

// =========================================================================
// Module: lut_h_tanh_div_v
// Description:
//   計算 h(v) = tanh(v)/v 的硬體查表模組。
//   採用 128-entry 的 Base + Delta 架構，搭配 8-bit 線性插值。
//
// Latency: 1 cycle 
//   - 輸入 (i_abs_v) 在 Cycle N
//   - 輸出 (o_g) 在 Cycle N+1 組合邏輯算出
// =========================================================================

module lut_h_tanh_div_v (
    input  logic               i_clk,
    input  logic               i_rst,
    input  logic        [14:0] i_abs_v,  // 輸入：Unsigned Q4.11 (0 ~ 15.999，最大值 32767)
    input  logic               i_en,     // 輸入：Valid / Enable
    output logic signed [15:0] o_g,      // 輸出：Signed Q1.15 (0 ~ 1.0)
    output logic               o_en      // 輸出：對齊好的 Enable
);

    // ==========================================
    // 1. 分拆 Input Address (15 bits 對半切)
    // ==========================================
    logic [6:0] lut_idx;  // 高 7 位元：用作 ROM 的 Address (0 ~ 127)
    logic [7:0] lut_frac; // 低 8 位元：用作兩點之間的比例尺 Fraction (0 ~ 255)
    
    assign lut_idx  = i_abs_v[14:8]; 
    assign lut_frac = i_abs_v[7:0];

    // ==========================================
    // 2. ROM 宣告與初始化
    // ==========================================
    // 128 筆 32-bit 資料
    //   - [31:16] : 基準點 Base (Signed Q1.15)
    //   - [15:0]  : 差值 Delta = Y_next - Base (Signed Q1.15)
    (* rom_style = "block" *) // 提示合成工具使用 BRAM / ROM 資源
    logic [31:0] rom_data [0:127]; 

    initial begin
        // 合成工具會尋找這個 hex 檔案來燒錄初始值
        $readmemh("lut_base_delta.hex", rom_data);
    end

    // ==========================================
    // 3. Pipeline Register: 讀取 ROM (Delay 1 Cycle)
    // ==========================================
    logic signed [15:0] base_r;
    logic signed [15:0] delta_r;
    logic        [7:0]  frac_r;
    logic               en_r;

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            base_r  <= 16'sd0;
            delta_r <= 16'sd0;
            frac_r  <= 8'd0;
            en_r    <= 1'b0;
        end else begin
            // 讀取位址上的 32-bit 數據，並拆分成 Base 與 Delta
            base_r  <= rom_data[lut_idx][31:16];
            delta_r <= rom_data[lut_idx][15:0];
            
            // 同時將 Fraction 與 Enable 延遲 1 Cycle
            frac_r  <= lut_frac;
            en_r    <= i_en;
        end
    end

    // ==========================================
    // 4. Combinational Logic: 線性插值 (Linear Interpolation)
    // ==========================================
    // 數學公式: y = Base + (Delta * Fraction) / 256
    
    logic signed [24:0] delta_scaled; 
    logic signed [15:0] g_out_w;

    always_comb begin
        // 乘法：Signed 16-bit (Delta) * Unsigned 8-bit (Fraction) = Signed 25-bit
        // 注意：必須擴展 Fraction 為有號正數，才能安全相乘
        delta_scaled = delta_r * $signed({1'b0, frac_r});
        
        // 插值計算：
        // 加上 25'sd128 是為了做四捨五入 (Rounding to nearest) -> 256 的一半是 128
        // >>> 8 是除以 256
        g_out_w = base_r + ((delta_scaled + 25'sd128) >>> 8);
    end

    // ==========================================
    // 5. Output Assignment
    // ==========================================
    assign o_g  = g_out_w;
    assign o_en = en_r;

endmodule