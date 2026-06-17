`timescale 1ns/1ps
module Overdrive (
    input                      i_clk,
    input                      i_rst,      // active-low reset
    input        signed [15:0] i_data,     // Q1.15 (Signed)
    input               [15:0] i_L,        // Q0.16 (Unsigned)
    input               [9:0]  i_gain,     // Q4.6 (Unsigned)
    input                      i_en,
    output       logic signed [15:0] o_data,    // Q1.15 (Signed)
    output       logic               o_en
);

    // ==========================================
    // Stage 0: input register
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [9:0]  i_gain_r;
    logic               i_en_r;
    logic        [15:0] i_L_r;       // [新增] i_L 的 Stage 0 暫存器

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
    logic        [15:0] i_L_r2;      // [新增] i_L 的 Stage 1 暫存器

    // ==========================================
    // Output selection signal
    // ==========================================
    logic signed [15:0] overdrive_out;
    logic signed [32:0] mult_res;    // [新增] 儲存 33-bit 的乘法結果

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
            i_L_r         <= 16'd0;  // [新增] Reset i_L_r

            tanh_unnorm_r <= 16'sd0;
            i_data_r2     <= 16'sd0;
            i_gain_r2     <= 10'd0;
            i_en_r2       <= 1'b0;
            i_L_r2        <= 16'd0;  // [新增] Reset i_L_r2
        end else begin
            // Stage 0: capture input sample/gain/valid/L
            i_data_r <= i_data;
            i_gain_r <= i_gain;
            i_en_r   <= i_en;
            i_L_r    <= i_L;         // [新增] 擷取 i_L

            // Stage 1: register output from tanh.
            // Also delay data/gain/en/L by the same one cycle for alignment.
            tanh_unnorm_r <= tanh_unnorm_w;
            i_data_r2     <= i_data_r;
            i_gain_r2     <= i_gain_r;
            i_en_r2       <= i_en_r;
            i_L_r2        <= i_L_r;  // [新增] 延遲 i_L
        end
    end

    // ==========================================
    // Combinational logic: Volume control / Normalization
    // Uses pipelined tanh_unnorm_r and i_L_r2.
    // ==========================================
    always_comb begin
        // [新增] 乘法運算
        // 16-bit Q1.15 (有號) * 17-bit Q1.16 (將 i_L 強制補 0 轉為有號) = 33-bit Q2.31 
        mult_res = $signed(tanh_unnorm_r) * $signed({1'b0, i_L_r2});

        if (i_gain_r2 <= 10'd4) begin
            // Bypass path must use the data delayed to the same stage.
            overdrive_out = i_data_r2;
        end else begin
            // 取出 [31:16] 相當於將 33-bit 的結果向右移 16 bits，
            // 抵銷掉 i_L_r2 的 Q0.16 小數點，完美轉回 Q1.15 格式。
            overdrive_out = mult_res[31:16]; 
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

// `timescale 1ns/1ps
// module Overdrive (
//     input                      i_clk,
//     input                      i_rst,      // active-low reset
//     input        signed [15:0] i_data,     // Q1.15 (Signed)
//     input               [9:0]  i_gain,     // Q4.6 (Unsigned)
//     input                      i_en,
//     output       logic signed [15:0] o_data,    // Q1.15 (Signed)
//     output       logic         o_en
// );

//     // ==========================================
//     // Stage 0: input register
//     // ==========================================
//     logic signed [15:0] i_data_r;
//     logic        [9:0]  i_gain_r;
//     logic               i_en_r;

//     // ==========================================
//     // Submodule raw output
//     // ==========================================
//     logic signed [15:0] tanh_unnorm_w;

//     // ==========================================
//     // Stage 1: pipeline registers after tanh
//     // ==========================================
//     logic signed [15:0] tanh_unnorm_r;
//     logic signed [15:0] i_data_r2;
//     logic        [9:0]  i_gain_r2;
//     logic               i_en_r2;

//     // ==========================================
//     // Output selection signal
//     // ==========================================
//     logic signed [15:0] overdrive_out;

//     // ==========================================
//     // Submodule instantiation
//     // No recip_tanh normalization is used here.
//     // Output = tanh(gain * input), except small-gain bypass.
//     // ==========================================
//     tanh u_tanh (
//         .i_data (i_data_r),
//         .i_gain (i_gain_r),
//         .o_data (tanh_unnorm_w)
//     );

//     // ==========================================
//     // Pipeline registers
//     // ==========================================
//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             i_data_r      <= 16'sd0;
//             i_gain_r      <= 10'd0;
//             i_en_r        <= 1'b0;

//             tanh_unnorm_r <= 16'sd0;
//             i_data_r2     <= 16'sd0;
//             i_gain_r2     <= 10'd0;
//             i_en_r2       <= 1'b0;
//         end else begin
//             // Stage 0: capture input sample/gain/valid
//             i_data_r <= i_data;
//             i_gain_r <= i_gain;
//             i_en_r   <= i_en;

//             // Stage 1: register output from tanh.
//             // Also delay data/gain/en by the same one cycle for alignment.
//             tanh_unnorm_r <= tanh_unnorm_w;
//             i_data_r2     <= i_data_r;
//             i_gain_r2     <= i_gain_r;
//             i_en_r2       <= i_en_r;
//         end
//     end

//     // ==========================================
//     // Combinational logic: no normalization
//     // Uses pipelined tanh_unnorm_r.
//     // ==========================================
//     always_comb begin
//         if (i_gain_r2 <= 10'd4) begin
//             // Bypass path must use the data delayed to the same stage.
//             overdrive_out = i_data_r2;
//         end else begin
//             // No recip_tanh normalization:
//             // directly use tanh output, already Q1.15 signed.
//             overdrive_out = tanh_unnorm_r ;
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
//                 o_data <= overdrive_out;
//             end
//         end
//     end

// endmodule
