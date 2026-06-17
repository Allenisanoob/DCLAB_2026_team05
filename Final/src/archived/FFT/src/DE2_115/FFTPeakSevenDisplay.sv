module FFTPeakSevenDisplay (
    input  logic [1:0]  i_sel_rank,   // 0: top1, 1: top2, 2: top3, 3: top4
    input  logic        i_show_freq,  // 0: show bin, 1: show frequency

    input  logic [11:0] i_bin_1,
    input  logic [11:0] i_bin_2,
    input  logic [11:0] i_bin_3,
    input  logic [11:0] i_bin_4,

    input  logic [16:0] i_freq_1,
    input  logic [16:0] i_freq_2,
    input  logic [16:0] i_freq_3,
    input  logic [16:0] i_freq_4,

    output logic [6:0]  o_HEX0,
    output logic [6:0]  o_HEX1,
    output logic [6:0]  o_HEX2,
    output logic [6:0]  o_HEX3,
    output logic [6:0]  o_HEX4,
    output logic [6:0]  o_HEX5,
    output logic [6:0]  o_HEX6,
    output logic [6:0]  o_HEX7
);

    localparam logic [6:0] BLANK = 7'b1111111;

    logic [11:0] selected_bin_w;
    logic [16:0] selected_freq_w;
    logic [16:0] display_value_w;

    logic [3:0] digit0_w;
    logic [3:0] digit1_w;
    logic [3:0] digit2_w;
    logic [3:0] digit3_w;
    logic [3:0] digit4_w;

    logic [6:0] seg0_w;
    logic [6:0] seg1_w;
    logic [6:0] seg2_w;
    logic [6:0] seg3_w;
    logic [6:0] seg4_w;

    logic [3:0] rank_digit_w;
    logic [3:0] mode_digit_w;

    // ------------------------------------------------------------
    // Select top1 / top2 / top3 / top4
    // ------------------------------------------------------------
    always_comb begin
        case (i_sel_rank)
            2'd0: begin
                selected_bin_w  = i_bin_1;
                selected_freq_w = i_freq_1;
            end

            2'd1: begin
                selected_bin_w  = i_bin_2;
                selected_freq_w = i_freq_2;
            end

            2'd2: begin
                selected_bin_w  = i_bin_3;
                selected_freq_w = i_freq_3;
            end

            2'd3: begin
                selected_bin_w  = i_bin_4;
                selected_freq_w = i_freq_4;
            end

            default: begin
                selected_bin_w  = i_bin_1;
                selected_freq_w = i_freq_1;
            end
        endcase
    end

    // ------------------------------------------------------------
    // Select bin or frequency
    // i_show_freq = 0: display bin
    // i_show_freq = 1: display frequency in Hz
    // ------------------------------------------------------------
    always_comb begin
        if (i_show_freq)
            display_value_w = selected_freq_w;
        else
            display_value_w = {5'd0, selected_bin_w};
    end

    // ------------------------------------------------------------
    // Binary number to decimal digits
    // ------------------------------------------------------------
    BinToBCD5 #(
        .BIN_W (17)
    ) u_bin_to_bcd5 (
        .i_bin    (display_value_w),

        .o_digit0 (digit0_w),
        .o_digit1 (digit1_w),
        .o_digit2 (digit2_w),
        .o_digit3 (digit3_w),
        .o_digit4 (digit4_w)
    );

    // ------------------------------------------------------------
    // Decode each decimal digit to seven-segment
    // HEX0 is the rightmost digit
    // ------------------------------------------------------------
    SevenHexDecoder u_hex0 (
        .i_hex   (digit0_w),
        .o_seven (seg0_w)
    );

    SevenHexDecoder u_hex1 (
        .i_hex   (digit1_w),
        .o_seven (seg1_w)
    );

    SevenHexDecoder u_hex2 (
        .i_hex   (digit2_w),
        .o_seven (seg2_w)
    );

    SevenHexDecoder u_hex3 (
        .i_hex   (digit3_w),
        .o_seven (seg3_w)
    );

    SevenHexDecoder u_hex4 (
        .i_hex   (digit4_w),
        .o_seven (seg4_w)
    );

    // ------------------------------------------------------------
    // HEX0~HEX4 show the selected value
    // Leading zero blanking:
    // 00085 becomes __085 or ___85 depending on value
    // ------------------------------------------------------------
    assign o_HEX0 = seg0_w;
    assign o_HEX1 = (display_value_w < 17'd10)    ? BLANK : seg1_w;
    assign o_HEX2 = (display_value_w < 17'd100)   ? BLANK : seg2_w;
    assign o_HEX3 = (display_value_w < 17'd1000)  ? BLANK : seg3_w;
    assign o_HEX4 = (display_value_w < 17'd10000) ? BLANK : seg4_w;

    // ------------------------------------------------------------
    // HEX5 shows selected rank: 1, 2, 3, 4
    // HEX6 shows mode: 0 = bin, 1 = frequency
    // HEX7 blank
    // ------------------------------------------------------------
    assign rank_digit_w = {2'b00, i_sel_rank} + 4'd1;
    assign mode_digit_w = {3'b000, i_show_freq};

    SevenHexDecoder u_hex5_rank (
        .i_hex   (rank_digit_w),
        .o_seven (o_HEX5)
    );

    SevenHexDecoder u_hex6_mode (
        .i_hex   (mode_digit_w),
        .o_seven (o_HEX6)
    );

    assign o_HEX7 = BLANK;

endmodule