module overdrive (
    input                      i_clk,
    input                      i_rst,      // 同步或非同步高電位重置
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [7:0]  i_gain,     // Q2.6 (Unsigned)
    input                      i_en,
    output       logic signed [15:0] o_data,    // Q1.15 (Signed)
    output       logic         o_en
);

    // ==========================================
    // 內部連線訊號宣告
    // ==========================================
    logic signed [15:0] tanh_unnorm;
    logic        [15:0] inv_tanh_val;
    logic signed [32:0] y_norm_full;
    logic signed [15:0] overdrive_out;

    logic signed [15:0] i_data_r;

    // ==========================================
    // 實例化 (Instantiation) 子模組
    // ==========================================
    tanh u_tanh (
        .i_data (i_data_r),
        .i_gain (i_gain),
        .o_data (tanh_unnorm)
    );

    inv_tanh u_inv_tanh (
        .i_gain         (i_gain),
        .o_inv_tanh_val (inv_tanh_val)
    );

    // ==========================================
    // 組合邏輯：正規化與飽和保護
    // ==========================================
    always_comb begin
        overdrive_out = 16'sd0; // 預設輸出為 0
        y_norm_full = 33'sd0; // 預設未正規化的結果為 0 (使用 33 bits 以防止溢位)
        if (i_gain <= 8'd4) begin
            // 當 gain 為 4 時 bypass 原始音訊
            overdrive_out = i_data_r; 
        end else begin
            // 1. Make-up Gain 正規化乘法: Q1.15 (有號) * Q7.9 (無號) = Q8.24 (有號)
            y_norm_full = tanh_unnorm * $signed({1'b0, inv_tanh_val});

            // 2. 將 Q8.24 轉回 Q1.15：加上 256 = 2^8 進行 rounding，然後 arithmetic right shift 9 bits
            // 並加入 saturation，避免超過 Q1.15 範圍造成 wrap-around / pop sound
            if (y_norm_full > 33'sd16776447) begin             // 32767 << 9, max Q1.15 in Q8.24 scale
                overdrive_out = 16'sd32767;
            end else if (y_norm_full < -33'sd16777216) begin   // -32768 << 9, min Q1.15 in Q8.24 scale
                        overdrive_out = -16'sd32768;
            end else begin
                        if (y_norm_full >= 0)
                            overdrive_out = (y_norm_full + 33'sd256) >>> 9;
                        else
                            overdrive_out = (y_norm_full - 33'sd256) >>> 9;
                        
                        end
        end
    end

    // ==========================================
    // 輸出時序邏輯 (Register)
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            o_data <= 16'sd0;
            o_en   <= 1'b0;
        end else begin
            o_en <= i_en;
            if (i_en) begin
                o_data <= overdrive_out;
                i_data_r <= i_data;
            end
        end
    end

endmodule