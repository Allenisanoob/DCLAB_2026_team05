`timescale 1ns/1ps
module fuzz (
    input                      i_clk,
    input                      i_rst,
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [7:0]  i_gain,     // Q2.6 (Unsigned)
    input               [15:0] i_L,        // [新增] Q0.16 (Unsigned)
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
        logic signed [23:0] data_ext;
        logic signed [23:0] gain_ext;
        logic signed [47:0] mult_full;
        logic signed [23:0] z_full;
        logic               z_sign;
        logic signed [23:0] z_trans;
        logic        [22:0] z_abs;

        // 運算暫存用變數 (使用 32-bit 防止運算過程溢位)
        logic        [31:0] x_val;        // unsigned magnitude, scaled with 15 fractional bits; may exceed 1.0 after gain
        logic        [31:0] x_sq;         // x 的平方，仍保留 15 fractional bits
        logic        [31:0] y_val;        // 最終正半波結果，Q1.15 unsigned magnitude
        logic signed [32:0] y_poly;       // signed polynomial 暫存，避免 unsigned subtraction underflow

        // 1. 套用 Gain: Q1.15 * Q2.6 = Q3.21 (總共 24 bits)
        //    明確展寬後再乘，避免不同工具對乘法結果寬度推導不一致。
        data_ext = {{8{f_data[15]}}, f_data};
        gain_ext = {16'd0, f_gain};
        mult_full = data_ext * gain_ext;
        z_full    = mult_full[23:0];

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
            // 用 signed 暫存，避免 unsigned subtraction 在邊界或截位誤差時 underflow。
            y_poly = $signed({1'b0, (x_val << 2)})
                   - $signed({1'b0, (x_sq * 32'd3)})
                   - 33'sd10923;

            // 防溢位/防 underflow 保護：限制在 Q1.15 正半波範圍 0 ~ 32767。
            if (y_poly > 33'sd32767) begin
                y_val = 32'd32767;
            end else if (y_poly < 33'sd0) begin
                y_val = 32'd0;
            end else begin
                y_val = y_poly[31:0];
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
    // Stage 0: input register
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [7:0]  i_gain_r;
    logic               i_en_r;
    logic        [15:0] i_L_r;       // [新增] Stage 0 的 i_L 暫存器

    // ==========================================
    // Combinational fuzz raw output
    // ==========================================
    logic signed [15:0] fuzz_raw_w;

    // ==========================================
    // Stage 1: pipeline registers after fuzz curve
    // ==========================================
    logic signed [15:0] fuzz_raw_r;
    logic signed [15:0] i_data_r2;
    logic        [7:0]  i_gain_r2;
    logic               i_en_r2;
    logic        [15:0] i_L_r2;      // [新增] Stage 1 的 i_L 暫存器

    // ==========================================
    // Output selection signal
    // ==========================================
    logic signed [15:0] fuzz_out;
    logic signed [32:0] mult_res;    // [新增] 儲存 33-bit 的乘法結果

    always_comb begin
        fuzz_raw_w = fuzz_func(i_data_r, i_gain_r);
    end

    // ==========================================
    // Pipeline registers
    // ==========================================
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            i_data_r   <= 16'sd0;
            i_gain_r   <= 8'd0;
            i_en_r     <= 1'b0;
            i_L_r      <= 16'd0;     // [新增] Reset i_L_r

            fuzz_raw_r <= 16'sd0;
            i_data_r2  <= 16'sd0;
            i_gain_r2  <= 8'd0;
            i_en_r2    <= 1'b0;
            i_L_r2     <= 16'd0;     // [新增] Reset i_L_r2
        end else begin
            // Stage 0: capture input sample/gain/valid
            i_data_r <= i_data;
            i_gain_r <= i_gain;
            i_en_r   <= i_en;
            i_L_r    <= i_L;         // [新增] 擷取 i_L

            // Stage 1: register output from fuzz curve.
            // Also delay data/gain/en by the same one cycle for alignment.
            fuzz_raw_r <= fuzz_raw_w;
            i_data_r2  <= i_data_r;
            i_gain_r2  <= i_gain_r;
            i_en_r2    <= i_en_r;
            i_L_r2     <= i_L_r;     // [新增] 延遲 i_L
        end
    end

    // ==========================================
    // Combinational logic: bypass or fuzz curve + i_L volume control
    // Uses pipelined fuzz_raw_r and i_L_r2.
    // ==========================================
    always_comb begin
        // [新增] 乘法運算
        // 16-bit Q1.15 (有號) * 17-bit Q0.16 (強制補 0 轉為有號) = 33-bit
        mult_res = $signed(fuzz_raw_r) * $signed({1'b0, i_L_r2});

        if (i_gain_r2 == 8'd0) begin
            // Bypass path must use the data delayed to the same stage.
            fuzz_out = i_data_r2;
        end else begin
            // [修改] 取出 [31:16] 抵銷 Q0.16 小數點，轉回 Q1.15
            fuzz_out = mult_res[31:16];
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
                o_data <= fuzz_out;
            end
        end
    end

endmodule
// `timescale 1ns/1ps
// module fuzz (
//     input                      i_clk,
//     input                      i_rst,
//     input        signed [15:0] i_data,     // Q1.15 (Signed)
//     input               [7:0]  i_gain,     // Q2.6 (Unsigned)
//     //input               [15:0] i_L,        // [新增] Q0.16 (Unsigned)
//     input                      i_en,
//     output       logic signed [15:0] o_data,
//     output       logic         o_en
// );

//     // ==========================================
//     // 定義 Fuzz 運算 Function (純組合邏輯)
//     // ==========================================
//     function automatic logic signed [15:0] fuzz_func(
//         input logic signed [15:0] f_data,
//         input logic        [7:0]  f_gain
//     );
//         // 變數宣告
//         logic signed [23:0] data_ext;
//         logic signed [23:0] gain_ext;
//         logic signed [47:0] mult_full;
//         logic signed [23:0] z_full;
//         logic               z_sign;
//         logic signed [23:0] z_trans;
//         logic        [22:0] z_abs;
        
//         // 運算暫存用變數 (使用 32-bit 防止運算過程溢位)
//         logic        [31:0] x_val;  // unsigned magnitude, scaled with 15 fractional bits; may exceed 1.0 after gain
//         logic        [31:0] x_sq;   // x 的平方，仍保留 15 fractional bits
//         logic        [31:0] y_val;  // 最終正半波結果，Q1.15 unsigned magnitude
//         logic signed [32:0] y_poly; // signed polynomial 暫存，避免 unsigned subtraction underflow

//         // 1. 套用 Gain: Q1.15 * Q2.6 = Q3.21 (總共 24 bits)
//         //    明確展寬後再乘，避免不同工具對乘法結果寬度推導不一致。
//         data_ext = {{8{f_data[15]}}, f_data};
//         gain_ext = {16'd0, f_gain};
//         mult_full = data_ext * gain_ext;
//         z_full    = mult_full[23:0];

//         // 2. 提取符號與絕對值
//         z_sign  = z_full[23];
//         z_trans = z_sign ? -z_full : z_full;
//         z_abs   = z_trans[22:0];

//         // 3. 將絕對值轉回 Q1.15 格式 (向右平移 6 bits 抵銷 Gain 的小數位)
//         x_val = z_abs >> 6; 

//         // 4. 計算 Fuzz 曲線 (一律使用正數公式)
//         if (x_val <= 32'd10923) begin 
//             // 區間一： x <= 1/3
//             // y = 2x
//             y_val = x_val << 1;
            
//         end else if (x_val <= 32'd21845) begin 
//             // 區間二： 1/3 < x <= 2/3
//             // 數學式： y = -3x^2 + 4x - 1/3
//             // 轉換為整數運算： y = 4x - 3x^2 - 1/3 (1/3 在 Q1.15 為 10923)
            
//             // 計算 x^2: Q1.15 * Q1.15 = Q2.30 -> 向右平移 15 bits -> 變回 Q3.15
//             x_sq = (x_val * x_val) >> 15;
            
//             // 執行多項式加減 (利用位元平移取代乘以 4)
//             // 用 signed 暫存，避免 unsigned subtraction 在邊界或截位誤差時 underflow。
//             y_poly = $signed({1'b0, (x_val << 2)})
//                    - $signed({1'b0, (x_sq * 32'd3)})
//                    - 33'sd10923;
            
//             // 防溢位/防 underflow 保護：限制在 Q1.15 正半波範圍 0 ~ 32767。
//             if (y_poly > 33'sd32767) begin
//                 y_val = 32'd32767;
//             end else if (y_poly < 33'sd0) begin
//                 y_val = 32'd0;
//             end else begin
//                 y_val = y_poly[31:0];
//             end
            
//         end else begin 
//             // 區間三： x > 2/3
//             // y = 1 (Q1.15 的最大值)
//             y_val = 32'd32767;
//         end

//         // 5. 恢復原本的符號位並輸出
//         fuzz_func = z_sign ? -$signed(y_val[15:0]) : $signed(y_val[15:0]);
        
//     endfunction

//     // ==========================================
//     // Stage 0: input register
//     // ==========================================
//     logic signed [15:0] i_data_r;
//     logic        [7:0]  i_gain_r;
//     logic               i_en_r;

//     // ==========================================
//     // Combinational fuzz raw output
//     // ==========================================
//     logic signed [15:0] fuzz_raw_w;

//     // ==========================================
//     // Stage 1: pipeline registers after fuzz curve
//     // ==========================================
//     logic signed [15:0] fuzz_raw_r;
//     logic signed [15:0] i_data_r2;
//     logic        [7:0]  i_gain_r2;
//     logic               i_en_r2;

//     // ==========================================
//     // Output selection signal
//     // ==========================================
//     logic signed [15:0] fuzz_out;

//     always_comb begin
//         fuzz_raw_w = fuzz_func(i_data_r, i_gain_r);
//     end

//     // ==========================================
//     // Pipeline registers
//     // ==========================================
//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             i_data_r   <= 16'sd0;
//             i_gain_r   <= 8'd0;
//             i_en_r     <= 1'b0;

//             fuzz_raw_r <= 16'sd0;
//             i_data_r2  <= 16'sd0;
//             i_gain_r2  <= 8'd0;
//             i_en_r2    <= 1'b0;
//         end else begin
//             // Stage 0: capture input sample/gain/valid
//             i_data_r <= i_data;
//             i_gain_r <= i_gain;
//             i_en_r   <= i_en;

//             // Stage 1: register output from fuzz curve.
//             // Also delay data/gain/en by the same one cycle for alignment.
//             fuzz_raw_r <= fuzz_raw_w;
//             i_data_r2  <= i_data_r;
//             i_gain_r2  <= i_gain_r;
//             i_en_r2    <= i_en_r;
//         end
//     end

//     // ==========================================
//     // Combinational logic: bypass or fuzz curve
//     // Uses pipelined fuzz_raw_r.
//     // ==========================================
//     always_comb begin
//         if (i_gain_r2 == 8'd0) begin
//             // Bypass path must use the data delayed to the same stage.
//             fuzz_out = i_data_r2;
//         end else begin
//             fuzz_out = fuzz_raw_r;
//         end
//     end

//     // ==========================================
//     // Output register
//     // ==========================================
//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             o_data <= 16'sd0;
//             o_en   <= 1'b0;
//         end else begin
//             o_en <= i_en_r2;
//             if (i_en_r2) begin
//                 o_data <= fuzz_out;
//             end
//         end
//     end

// endmodule
