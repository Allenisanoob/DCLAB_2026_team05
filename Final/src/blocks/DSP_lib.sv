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

module cosine (
    input         [15:0] f, // Q0.16
    output signed [15:0] cos_2pif // Q1.15
);
    logic        [13:0] tran_f;
    logic        [5:0]  seg_f;
    logic        [7:0]  frac_f; // Q0.16
    logic        [18:0] neg_slope_LUT; // Q3.16
    logic        [15:0] base_LUT; // Q0.16
    logic        [26:0] diff; // Q0.32
    logic        [32:0] cos_LUT_temp; // Q1.32
    logic signed [15:0] cos_LUT; // Q1.15

    assign seg_f  = tran_f[13:8];
    assign frac_f = tran_f[7:0];
    assign cos_2pif = (f[13:0] == 14'd0 || f[15] == f[14]) ? $signed(cos_LUT) : $signed(-cos_LUT);

    always_comb begin
        case (f[15:14])
            2'b00: tran_f = f[13:0];
            2'b01: tran_f = (~f[13:0]) + 1'b1;
            2'b10: tran_f = f[13:0];
            2'b11: tran_f = (~f[13:0]) + 1'b1;
        endcase
        case (seg_f)
            6'b000000: begin neg_slope_LUT = 19'd5053; base_LUT = 16'd65535; end
            6'b000001: begin neg_slope_LUT = 19'd15156; base_LUT = 16'd65516; end
            6'b000010: begin neg_slope_LUT = 19'd25250; base_LUT = 16'd65457; end
            6'b000011: begin neg_slope_LUT = 19'd35328; base_LUT = 16'd65358; end
            6'b000100: begin neg_slope_LUT = 19'd45386; base_LUT = 16'd65220; end
            6'b000101: begin neg_slope_LUT = 19'd55416; base_LUT = 16'd65043; end
            6'b000110: begin neg_slope_LUT = 19'd65412; base_LUT = 16'd64827; end
            6'b000111: begin neg_slope_LUT = 19'd75369; base_LUT = 16'd64571; end
            6'b001000: begin neg_slope_LUT = 19'd85281; base_LUT = 16'd64277; end
            6'b001001: begin neg_slope_LUT = 19'd95142; base_LUT = 16'd63944; end
            6'b001010: begin neg_slope_LUT = 19'd104945; base_LUT = 16'd63572; end
            6'b001011: begin neg_slope_LUT = 19'd114685; base_LUT = 16'd63162; end
            6'b001100: begin neg_slope_LUT = 19'd124355; base_LUT = 16'd62714; end
            6'b001101: begin neg_slope_LUT = 19'd133951; base_LUT = 16'd62228; end
            6'b001110: begin neg_slope_LUT = 19'd143466; base_LUT = 16'd61705; end
            6'b001111: begin neg_slope_LUT = 19'd152895; base_LUT = 16'd61145; end
            6'b010000: begin neg_slope_LUT = 19'd162232; base_LUT = 16'd60547; end
            6'b010001: begin neg_slope_LUT = 19'd171471; base_LUT = 16'd59914; end
            6'b010010: begin neg_slope_LUT = 19'd180607; base_LUT = 16'd59244; end
            6'b010011: begin neg_slope_LUT = 19'd189633; base_LUT = 16'd58538; end
            6'b010100: begin neg_slope_LUT = 19'd198546; base_LUT = 16'd57798; end
            6'b010101: begin neg_slope_LUT = 19'd207339; base_LUT = 16'd57022; end
            6'b010110: begin neg_slope_LUT = 19'd216007; base_LUT = 16'd56212; end
            6'b010111: begin neg_slope_LUT = 19'd224545; base_LUT = 16'd55368; end
            6'b011000: begin neg_slope_LUT = 19'd232948; base_LUT = 16'd54491; end
            6'b011001: begin neg_slope_LUT = 19'd241211; base_LUT = 16'd53581; end
            6'b011010: begin neg_slope_LUT = 19'd249328; base_LUT = 16'd52639; end
            6'b011011: begin neg_slope_LUT = 19'd257295; base_LUT = 16'd51665; end
            6'b011100: begin neg_slope_LUT = 19'd265107; base_LUT = 16'd50660; end
            6'b011101: begin neg_slope_LUT = 19'd272759; base_LUT = 16'd49624; end
            6'b011110: begin neg_slope_LUT = 19'd280247; base_LUT = 16'd48559; end
            6'b011111: begin neg_slope_LUT = 19'd287567; base_LUT = 16'd47464; end
            6'b100000: begin neg_slope_LUT = 19'd294713; base_LUT = 16'd46341; end
            6'b100001: begin neg_slope_LUT = 19'd301681; base_LUT = 16'd45190; end
            6'b100010: begin neg_slope_LUT = 19'd308468; base_LUT = 16'd44011; end
            6'b100011: begin neg_slope_LUT = 19'd315069; base_LUT = 16'd42806; end
            6'b100100: begin neg_slope_LUT = 19'd321480; base_LUT = 16'd41576; end
            6'b100101: begin neg_slope_LUT = 19'd327697; base_LUT = 16'd40320; end
            6'b100110: begin neg_slope_LUT = 19'd333718; base_LUT = 16'd39040; end
            6'b100111: begin neg_slope_LUT = 19'd339537; base_LUT = 16'd37736; end
            6'b101000: begin neg_slope_LUT = 19'd345151; base_LUT = 16'd36410; end
            6'b101001: begin neg_slope_LUT = 19'd350558; base_LUT = 16'd35062; end
            6'b101010: begin neg_slope_LUT = 19'd355753; base_LUT = 16'd33692; end
            6'b101011: begin neg_slope_LUT = 19'd360735; base_LUT = 16'd32303; end
            6'b101100: begin neg_slope_LUT = 19'd365498; base_LUT = 16'd30893; end
            6'b101101: begin neg_slope_LUT = 19'd370042; base_LUT = 16'd29466; end
            6'b101110: begin neg_slope_LUT = 19'd374363; base_LUT = 16'd28020; end
            6'b101111: begin neg_slope_LUT = 19'd378458; base_LUT = 16'd26558; end
            6'b110000: begin neg_slope_LUT = 19'd382326; base_LUT = 16'd25080; end
            6'b110001: begin neg_slope_LUT = 19'd385963; base_LUT = 16'd23586; end
            6'b110010: begin neg_slope_LUT = 19'd389368; base_LUT = 16'd22078; end
            6'b110011: begin neg_slope_LUT = 19'd392538; base_LUT = 16'd20557; end
            6'b110100: begin neg_slope_LUT = 19'd395471; base_LUT = 16'd19024; end
            6'b110101: begin neg_slope_LUT = 19'd398167; base_LUT = 16'd17479; end
            6'b110110: begin neg_slope_LUT = 19'd400622; base_LUT = 16'd15924; end
            6'b110111: begin neg_slope_LUT = 19'd402836; base_LUT = 16'd14359; end
            6'b111000: begin neg_slope_LUT = 19'd404808; base_LUT = 16'd12785; end
            6'b111001: begin neg_slope_LUT = 19'd406536; base_LUT = 16'd11204; end
            6'b111010: begin neg_slope_LUT = 19'd408019; base_LUT = 16'd9616; end
            6'b111011: begin neg_slope_LUT = 19'd409256; base_LUT = 16'd8022; end
            6'b111100: begin neg_slope_LUT = 19'd410246; base_LUT = 16'd6424; end
            6'b111101: begin neg_slope_LUT = 19'd410990; base_LUT = 16'd4821; end
            6'b111110: begin neg_slope_LUT = 19'd411485; base_LUT = 16'd3216; end
            6'b111111: begin neg_slope_LUT = 19'd411733; base_LUT = 16'd1608; end
        endcase
        diff = neg_slope_LUT * frac_f;
        cos_LUT_temp = {1'b0, base_LUT, 16'b0} - {6'b0, diff};
        if (f[13:0] == 14'd0) begin
            cos_LUT = base_LUT;
            case (f[15:14])
                2'b00: cos_LUT = 16'h7FFF; // 1.0
                2'b01: cos_LUT = 16'h0000; // 0.0
                2'b10: cos_LUT = 16'h8000; // -1.0
                2'b11: cos_LUT = 16'h0000; // 0.0
            endcase
        end else begin
            cos_LUT = cos_LUT_temp[32:17] + cos_LUT_temp[16]; // Q1.15
        end
    end
endmodule