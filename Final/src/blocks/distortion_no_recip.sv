`timescale 1ns/1ps
module distortion (
    input                      i_clk,
    input                      i_rst,      // active-low reset
    input        signed [15:0] i_data,     // Q1.15 signed
    input               [15:0] i_L,        // [新增] Q0.16 (Unsigned)
    input               [7:0]  i_gain,     // Q2.6 unsigned
    input                      i_en,
    output       logic signed [15:0] o_data,
    output       logic         o_en
);
    // Hard clipping threshold: about 90% of Q1.15 full scale
    localparam signed [31:0] CLIP_MAX = 32'sd29491;
    localparam signed [31:0] CLIP_MIN = -32'sd29491;

    // ==========================================
    // Stage 0: input register
    // ==========================================
    logic signed [15:0] i_data_r;
    logic        [7:0]  i_gain_r;
    logic               i_en_r;
    logic        [15:0] i_L_r;       // [新增] Stage 0 暫存器

    // ==========================================
    // Submodule raw output
    // ==========================================
    logic signed [15:0] tanh_unnorm_w;

    // ==========================================
    // Stage 1: pipeline registers after tanh
    // ==========================================
    logic signed [15:0] tanh_unnorm_r;
    logic signed [15:0] i_data_r2;
    logic        [7:0]  i_gain_r2;
    logic               i_en_r2;
    logic        [15:0] i_L_r2;      // [新增] Stage 1 暫存器

    logic signed [31:0] tanh_unnorm_ext;
    logic signed [31:0] y_boosted;
    logic signed [15:0] dist_out;
    logic signed [48:0] mult_res;    // [新增] 儲存 49-bit 的乘法結果

    // No recip_tanh normalization is used here.
    // tanh_unnorm is directly boosted and hard-clipped.
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
            i_gain_r      <= 8'd0;
            i_en_r        <= 1'b0;
            i_L_r         <= 16'd0;  // [新增] Reset i_L_r

            tanh_unnorm_r <= 16'sd0;
            i_data_r2     <= 16'sd0;
            i_gain_r2     <= 8'd0;
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
    // Combinational logic: boost + hard clipping
    // Uses pipelined tanh_unnorm_r.
    // ==========================================
    always_comb begin
        tanh_unnorm_ext = 32'sd0;
        y_boosted       = 32'sd0;
        dist_out        = 16'sd0;
        mult_res        = 49'sd0;

        if (i_gain_r2 <= 8'd4) begin
            // Bypass path must use the data delayed to the same stage.
            dist_out = i_data_r2;
        end else begin
            // 1. No recip_tanh normalization.
            // Sign-extend Q1.15 tanh output to 32-bit.
            tanh_unnorm_ext = $signed({{16{tanh_unnorm_r[15]}}, tanh_unnorm_r});

            // [修改] 先 boost 2x，再乘上 i_L_r2
            // 32-bit (tanh_unnorm_ext <<< 1) * 17-bit (i_L 補 0 轉有號) = 49-bit
            mult_res = $signed(tanh_unnorm_ext <<< 1) * $signed({1'b0, i_L_r2});
            
            // 取出 [47:16]，相當於向右移 16 bits 抵銷 Q0.16 的小數點，並存回 32-bit 變數
            y_boosted = mult_res[47:16];

            // 2. Hard clipping
            if (y_boosted > CLIP_MAX) begin
                dist_out = 16'sd29491;
            end else if (y_boosted < CLIP_MIN) begin
                dist_out = -16'sd29491;
            end else begin
                dist_out = y_boosted[15:0];
            end
        end
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            o_data <= 16'sd0;
            o_en   <= 1'b0;
        end else begin
            o_en <= i_en_r2;
            if (i_en_r2) begin
                o_data <= dist_out;
            end
        end
    end

endmodule

// `timescale 1ns/1ps
// module distortion (
//     input                      i_clk,
//     input                      i_rst,      // active-low reset
//     input        signed [15:0] i_data,     // Q1.15 signed
//     input               [7:0]  i_gain,     // Q2.6 unsigned
//     input                      i_en,
//     output       logic signed [15:0] o_data,
//     output       logic         o_en
// );

//     // Hard clipping threshold: about 90% of Q1.15 full scale
//     localparam signed [31:0] CLIP_MAX = 32'sd29491;
//     localparam signed [31:0] CLIP_MIN = -32'sd29491;

//     // ==========================================
//     // Stage 0: input register
//     // ==========================================
//     logic signed [15:0] i_data_r;
//     logic        [7:0]  i_gain_r;
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
//     logic        [7:0]  i_gain_r2;
//     logic               i_en_r2;

//     logic signed [31:0] tanh_unnorm_ext;
//     logic signed [31:0] y_boosted;
//     logic signed [15:0] dist_out;

//     // No recip_tanh normalization is used here.
//     // tanh_unnorm is directly boosted and hard-clipped.
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
//             i_gain_r      <= 8'd0;
//             i_en_r        <= 1'b0;

//             tanh_unnorm_r <= 16'sd0;
//             i_data_r2     <= 16'sd0;
//             i_gain_r2     <= 8'd0;
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
//     // Combinational logic: boost + hard clipping
//     // Uses pipelined tanh_unnorm_r.
//     // ==========================================
//     always_comb begin
//         tanh_unnorm_ext = 32'sd0;
//         y_boosted       = 32'sd0;
//         dist_out        = 16'sd0;

//         if (i_gain_r2 <= 8'd4) begin
//             // Bypass path must use the data delayed to the same stage.
//             dist_out = i_data_r2;
//         end else begin
//             // 1. No recip_tanh normalization.
//             // Sign-extend Q1.15 tanh output to 32-bit, then boost by 2x.
//             tanh_unnorm_ext = $signed({{16{tanh_unnorm_r[15]}}, tanh_unnorm_r});
//             y_boosted       = tanh_unnorm_ext <<< 1;

//             // 2. Hard clipping
//             if (y_boosted > CLIP_MAX) begin
//                 dist_out = 16'sd29491;
//             end else if (y_boosted < CLIP_MIN) begin
//                 dist_out = -16'sd29491;
//             end else begin
//                 dist_out = y_boosted[15:0];
//             end
//         end
//     end

//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             o_data <= 16'sd0;
//             o_en   <= 1'b0;
//         end else begin
//             o_en <= i_en_r2;
//             if (i_en_r2) begin
//                 o_data <= dist_out;
//             end
//         end
//     end

// endmodule
