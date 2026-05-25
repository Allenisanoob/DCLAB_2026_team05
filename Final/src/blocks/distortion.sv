module distortion (
    input                      i_clk,
    input                      i_rst,      
    input        signed [15:0] i_data,     
    input               [7:0]  i_gain,     
    input                      i_valid,
    output       logic signed [15:0] o_data,    
    output       logic         o_valid
);

    // Hard clipping threshold: about 90% of Q1.15 full scale
    localparam signed [31:0] CLIP_MAX = 32'sd29491;
    localparam signed [31:0] CLIP_MIN = -32'sd29491;

    logic signed [15:0] tanh_unnorm;
    logic        [15:0] inv_tanh_val;
    
    logic signed [32:0] y_norm_full;   // 16-bit * 17-bit = 33-bit
    logic signed [31:0] y_1x;
    logic signed [31:0] y_boosted;
    logic signed [15:0] dist_out;

    tanh u_tanh (
        .i_data (i_data),
        .i_gain (i_gain),
        .o_data (tanh_unnorm)
    );

    inv_tanh u_inv_tanh (
        .i_gain         (i_gain),
        .o_inv_tanh_val (inv_tanh_val)
    );

    always_comb begin
        y_norm_full = 33'sd0;
        y_1x        = 32'sd0;
        y_boosted   = 32'sd0;
        dist_out    = 16'sd0;

        if (i_gain <= 8'd4) begin
            // Very small gain: bypass
            dist_out = i_data; 
        end else begin
            // 1. Normalize:
            // Q1.15 * Q7.9 = Q8.24
            y_norm_full = tanh_unnorm * $signed({1'b0, inv_tanh_val});

            // 2. Q8.24 -> Q8.15 / Q1.15 scale
            // rounding by adding 2^(9-1) = 256, then arithmetic shift right by 9
            y_1x = (y_norm_full + 33'sd256) >>> 9;

            // 3. Distortion boost: 2x
            y_boosted = y_1x <<< 1; 

            // 4. Hard clipping
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
            o_data  <= 16'sd0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= i_valid;
            if (i_valid) begin
                o_data <= dist_out;
            end
        end
    end

endmodule