module Volume (
    input  i_prev_valid,
    input  signed [15:0] i_data,
    input  [6:0] i_volume_control, // 0 - Muted, 127 - Full Volume
    output o_next_valid,
    output signed [15:0] o_data
);
    // out = in * (i_volume_control / 128)
    logic signed [23:0] mult_result;
    assign mult_result = i_data * $signed({1'b0, i_volume_control});

    assign o_next_valid = i_prev_valid;
    assign o_data = (i_volume_control == 7'b0000000) ? 16'b0 :
                    (i_volume_control == 7'b1111111) ? i_data :
                    (mult_result >>> 7);

endmodule

module Data_Catcher (
    input  i_clk,
    input  i_rst,
    input  i_raw_valid,
    input  signed [15:0] i_data,
    output o_next_valid,
    output signed [15:0] o_data
);
    reg now_valid, old_valid;
    reg signed [15:0] data_reg;

    assign o_next_valid = (i_raw_valid && !old_valid);
    assign o_data = data_reg;

    always @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            now_valid <= 1'b0;
            old_valid <= 1'b0;
            data_reg <= 16'b0;
        end else begin
            now_valid <= i_raw_valid;
            old_valid <= now_valid;
            if (i_raw_valid && !old_valid) begin
                data_reg <= i_data;
            end
        end
    end

endmodule

module Reverb_basic(
    input i_clk,
    input i_rst,
    input i_valid,
    input [7:0] r, // Q0.8
    input [7:0] i_cosw, // Q1.7
    input [7:0] w_rate, // Q0.8
    input signed [15:0] i_data,
    output o_valid,
    output signed [15:0] o_data

    logic        [7:0]  w_rate_r; // Q0.8
    logic signed [15:0] y0, y1, y2; // y0 -> y[n], y1 -> y[n-1], y2 -> y[n-2]
    logic signed [15:0] x0, x1; // x0 -> x[n], x1 -> x[n-1]
    logic signed [16:0] A; // Q1.16
    logic        [15:0] B; // Q0.16
    logic signed [33:0] C; // Q18.16
    logic signed [31:0] D; // Q16.16
    logic signed [32:0] E; // Q17.16
    logic signed [35:0] F; // Q20.16
    logic signed [43:0] G; // Q20.24
    logic signed [19:0] H; // Q20.0
    logic signed [15:0] I; // Q16.0
    logic signed [16:0] J; // Q17.0
    logic signed [15:0] y0_next; // Q16.0
    logic               valid_reg_1, valid_reg_2;

    assign o_data = y0;
    assign o_valid = valid_reg_2;
    
    always_comb begin
        A = $signed({$signed(r * i_cosw), 1'b0}); // Q1.16
        B = r * r; // Q0.16
        C = $signed(2 * A * y1); // Q18.16
        D = $signed(B * y2); // Q16.16
        E = $signed(A * x1); // Q17.16
        F = $signed(C - D - E); // Q20.16
        G = $signed(F * w_rate_r); // Q20.24
        H = $signed($signed(G >>> 24) + G[23]); // Q20.0
        if (H > 20'sd32767) begin
            I = 16'sd32767;
        end else if (H < -20'sd32768) begin
            I = -16'sd32768;
        end else begin
            I = H[15:0]; // Q16.0
        end
        J = $signed(I + x0); // Q17.0
        if (J > 17'sd32767) begin
            y0_next = 16'sd32767;
        end else if (J < -17'sd32768) begin
            y0_next = -16'sd32768;
        end else begin
            y0_next = J[15:0]; // Q16.0
        end
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            w_rate_r <= 8'b0;
            y0 <= 16'b0;
            y1 <= 16'b0;
            y2 <= 16'b0;
            x0 <= 16'b0;
            x1 <= 16'b0;
            valid_reg_1 <= 1'b0;
            valid_reg_2 <= 1'b0;
        end else if (i_valid) begin
            w_rate_r <= w_rate;
            y0 <= y0_next;
            y1 <= y0;
            y2 <= y1;
            if (i_valid) begin
                x0 <= i_data;
            end else begin
                x0 <= 16'b0;
            end
            x1 <= x0;
            valid_reg_1 <= i_valid;
            valid_reg_2 <= valid_reg_1;
        end
    end
);

endmodule

// koreha gomi nanodesu

/*
module cosine(
    input         [7:0] f, // Q0.8
    output signed [7:0] cos_2pif // Q2.6
);
    logic        [5:0] tran_f;
    logic signed [7:0] cos_LUT;

    assign cos_2pif = (f[7] == f[6]) ? cos_LUT : -cos_LUT;

    always_comb begin
        if (f[5:0] == 6'b000000) begin
            case (f[7:6])
                2'b00: cos_LUT = 8'b01000000; // 1.0
                2'b01: cos_LUT = 8'b00000000; // 0.0
                2'b10: cos_LUT = 8'b11000000; // -1.0
                2'b11: cos_LUT = 8'b00000000; // 0.0
            endcase
        end else begin
            case (f[7:6])
                2'b00: tran_f = f[5:0];
                2'b01: tran_f = (~f[5:0]) + 1'b1;
                2'b10: tran_f = f[5:0];
                2'b11: tran_f = (~f[5:0]) + 1'b1;
            endcase
            case (tran_f)
                6'b000001: cos_LUT = 8'b01000000;
                6'b000010: cos_LUT = 8'b01000000;
                6'b000011: cos_LUT = 8'b01000000;
                6'b000100: cos_LUT = 8'b01000000;
                6'b000101: cos_LUT = 8'b01000000;
                6'b000110: cos_LUT = 8'b00111111;
                6'b000111: cos_LUT = 8'b00111111;
                6'b001000: cos_LUT = 8'b00111111;
                6'b001001: cos_LUT = 8'b00111110;
                6'b001010: cos_LUT = 8'b00111110;
                6'b001011: cos_LUT = 8'b00111110;
                6'b001100: cos_LUT = 8'b00111101;
                6'b001101: cos_LUT = 8'b00111101;
                6'b001110: cos_LUT = 8'b00111100;
                6'b001111: cos_LUT = 8'b00111100;
                6'b010000: cos_LUT = 8'b00111011;
                6'b010001: cos_LUT = 8'b00111011;
                6'b010010: cos_LUT = 8'b00111010;
                6'b010011: cos_LUT = 8'b00111001;
                6'b010100: cos_LUT = 8'b00111000;
                6'b010101: cos_LUT = 8'b00111000;
                6'b010110: cos_LUT = 8'b00110111;
                6'b010111: cos_LUT = 8'b00110110;
                6'b011000: cos_LUT = 8'b00110101;
                6'b011001: cos_LUT = 8'b00110100;
                6'b011010: cos_LUT = 8'b00110011;
                6'b011011: cos_LUT = 8'b00110010;
                6'b011100: cos_LUT = 8'b00110001;
                6'b011101: cos_LUT = 8'b00110000;
                6'b011110: cos_LUT = 8'b00101111;
                6'b011111: cos_LUT = 8'b00101110;
                6'b100000: cos_LUT = 8'b00101101;
                6'b100001: cos_LUT = 8'b00101100;
                6'b100010: cos_LUT = 8'b00101011;
                6'b100011: cos_LUT = 8'b00101010;
                6'b100100: cos_LUT = 8'b00101001;
                6'b100101: cos_LUT = 8'b00100111;
                6'b100110: cos_LUT = 8'b00100110;
                6'b100111: cos_LUT = 8'b00100101;
                6'b101000: cos_LUT = 8'b00100100;
                6'b101001: cos_LUT = 8'b00100010;
                6'b101010: cos_LUT = 8'b00100001;
                6'b101011: cos_LUT = 8'b00100000;
                6'b101100: cos_LUT = 8'b00011110;
                6'b101101: cos_LUT = 8'b00011101;
                6'b101110: cos_LUT = 8'b00011011;
                6'b101111: cos_LUT = 8'b00011010;
                6'b110000: cos_LUT = 8'b00011000;
                6'b110001: cos_LUT = 8'b00010111;
                6'b110010: cos_LUT = 8'b00010110;
                6'b110011: cos_LUT = 8'b00010100;
                6'b110100: cos_LUT = 8'b00010011;
                6'b110101: cos_LUT = 8'b00010001;
                6'b110110: cos_LUT = 8'b00010000;
                6'b110111: cos_LUT = 8'b00001110;
                6'b111000: cos_LUT = 8'b00001100;
                6'b111001: cos_LUT = 8'b00001011;
                6'b111010: cos_LUT = 8'b00001001;
                6'b111011: cos_LUT = 8'b00001000;
                6'b111100: cos_LUT = 8'b00000110;
                6'b111101: cos_LUT = 8'b00000101;
                6'b111110: cos_LUT = 8'b00000011;
                6'b111111: cos_LUT = 8'b00000010;
                default: cos_LUT = 8'b00000000;
            endcase
        end
    end
endmodule
*/