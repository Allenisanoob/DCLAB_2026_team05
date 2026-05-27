module fuzz (
    input                      i_clk,
    input                      i_rst,
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [7:0]  i_gain,     // Q2.6 (Unsigned)
    input                      i_en,
    output       logic signed [15:0] o_data,
    output       logic         o_en
);

    // ==========================================
    // 定義 Fuzz 運算 Function (純組合邏輯)
    // ==========================================
    function automatic logic signed [15:0] fuzz_func(
        input logic signed [15:0] f_data,
        input logic        [7:0]  f_gain
    );
        // 變數宣告
        logic signed [23:0] z_full;
        logic               z_sign;
        logic signed [23:0] z_trans;
        logic        [22:0] z_abs;
        
        // 運算暫存用變數 (使用 32-bit 防止運算過程溢位)
        logic        [31:0] x_val; // Q1.15 無號絕對值
        logic        [31:0] x_sq;  // x 的平方 (Q3.15 格式)
        logic        [31:0] y_val; // 運算暫存結果

        // 1. 套用 Gain: Q1.15 * Q2.6 = Q3.21 (總共 24 bits)
        z_full = f_data * $signed({1'b0, f_gain});

        // 2. 提取符號與絕對值
        z_sign  = z_full[23];
        z_trans = z_sign ? -z_full : z_full;
        z_abs   = z_trans[22:0];

        // 3. 將絕對值轉回 Q1.15 格式 (向右平移 6 bits 抵銷 Gain 的小數位)
        x_val = z_abs >> 6; 

        // 4. 計算 Fuzz 曲線 (一律使用正數公式)
        if (x_val <= 32'd10923) begin 
            // 區間一： x <= 1/3
            // y = 2x
            y_val = x_val << 1;
            
        end else if (x_val <= 32'd21845) begin 
            // 區間二： 1/3 < x <= 2/3
            // 數學式： y = -3x^2 + 4x - 1/3
            // 轉換為整數運算： y = 4x - 3x^2 - 1/3 (1/3 在 Q1.15 為 10923)
            
            // 計算 x^2: Q1.15 * Q1.15 = Q2.30 -> 向右平移 15 bits -> 變回 Q3.15
            x_sq = (x_val * x_val) >> 15;
            
            // 執行多項式加減 (利用位元平移取代乘以 4)
            y_val = (x_val << 2) - (x_sq * 3) - 32'd10923;
            
            // 防溢位保護：理論上 x=2/3 時會剛好算出 32768，會造成 signed 16-bit 負數溢位
            if (y_val > 32'd32767) begin
                y_val = 32'd32767;
            end
            
        end else begin 
            // 區間三： x > 2/3
            // y = 1 (Q1.15 的最大值)
            y_val = 32'd32767;
        end

        // 5. 恢復原本的符號位並輸出
        fuzz_func = z_sign ? -$signed(y_val[15:0]) : $signed(y_val[15:0]);
        
    endfunction

    // ==========================================
    // 主時序邏輯
    // ==========================================
    logic signed [15:0] fuzz_out;

    always_comb begin
        if (i_gain == 8'd0) begin
            fuzz_out = i_data; // Gain 為 0 時 Bypass 原音
        end else begin
            fuzz_out = fuzz_func(i_data, i_gain);
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_data <= 16'sd0;
            o_en   <= 1'b0;
        end else begin
            o_en <= i_en;
            if (i_en) begin
                o_data <= fuzz_out;
            end
        end
    end

endmodule