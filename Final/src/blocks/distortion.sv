module distortion (
    input                      i_clk,
    input                      i_rst,      
    input        signed [15:0] i_data,     
    input               [7:0]  i_gain,     
    input                      i_valid,
    output       logic signed [15:0] o_data,    
    output       logic         o_valid
);

    // Hard Clipping 門檻 (極值的 90%)
    localparam signed [31:0] CLIP_MAX = 32'sd29491;
    localparam signed [31:0] CLIP_MIN = -32'sd29491;

    // ==========================================
    // 內部連線訊號宣告
    // ==========================================
    logic signed [15:0] tanh_unnorm;
    logic        [15:0] inv_tanh_val;
    
    logic signed [31:0] y_norm_full;
    logic signed [31:0] y_1x;
    logic signed [31:0] y_boosted;
    logic signed [15:0] dist_out;

    // ==========================================
    // 實例化 (Instantiation)
    // ==========================================
    tanh u_tanh (
        .i_data (i_data),
        .i_gain (i_gain),
        .o_data (tanh_unnorm)
    );

    inv_tanh u_inv_tanh (
        .i_gain         (i_gain),
        .o_inv_tanh_val (inv_tanh_val)
    );

    // ==========================================
    // 組合邏輯：正規化、放大與 Hard Clipping
    // ==========================================
    always_comb begin
        if (i_gain == 8'd0) begin
            // Gain 為 0 時 bypass
            dist_out = i_data; 
        end else begin
            // 1. Make-up Gain 正規化乘法: Q1.15 * Q7.9 = Q8.24
            y_norm_full = tanh_unnorm * $signed({1'b0, inv_tanh_val});

            // 2. 轉回 Q1.15 並擴展至 32-bit (防溢位)
            y_1x = (y_norm_full + 32'sd256) >>> 9;

            // 3. Distortion Boost (這裡使用 2 倍放大)
            y_boosted = y_1x <<< 1; 

            // 4. Hard Clipping
            if (y_boosted > CLIP_MAX) begin
                dist_out = CLIP_MAX[15:0];
            end else if (y_boosted < CLIP_MIN) begin
                dist_out = CLIP_MIN[15:0];
            end else begin
                dist_out = y_boosted[15:0];
            end
        end
    end

    // ==========================================
    // 輸出時序邏輯 (Register)
    // ==========================================
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_data <= 16'sd0;
            o_valid   <= 1'b0;
        end else begin
            o_valid <= i_valid;
            if (i_valid) begin
                o_data <= dist_out;
            end
        end
    end

endmodule