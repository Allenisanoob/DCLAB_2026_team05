module Param_Manager(
    input i_clk,
    input i_rst,

    input [255:0] i_command,
    input i_valid,
    
    // Overdrive
    output reg [ 9:0] o_od_gain,
    output reg [15:0] o_od_level,

    // Fuzz
    output reg [ 9:0] o_fz_gain,
    output reg [15:0] o_fz_level,

    // Distortion
    output reg [ 9:0] o_dt_gain,
    output reg [15:0] o_dt_level,

    // Reverb
    output reg [7:0] o_rv_w_rate,
    output reg [7:0] o_rv_ap_gain,

    // Noise Gate
    output reg [ 7:0] o_ng_rise_rate,
    output reg [ 7:0] o_ng_decay_rate,
    output reg [15:0] o_ng_hold,
    output reg [14:0] o_ng_thres_lo,
    output reg [14:0] o_ng_thres_hi,

    // Delay Effect
    output reg [15:0] o_de_time,
    output reg [ 7:0] o_de_feedback,
    output reg [ 7:0] o_de_mix,

    // Flanger
    output reg [6:0] o_fg_inc,
    output reg [9:0] o_fg_base,
    output reg [9:0] o_fg_amp,
    output reg [7:0] o_fg_gain,
    output reg [7:0] o_fg_rate,

    // Chorus
    output reg [ 6:0] o_ch_inc,
    output reg [11:0] o_ch_base,
    output reg [11:0] o_ch_amp,
    output reg [ 7:0] o_ch_rate,

    // Auto-Wah
    output reg [ 6:0] o_aw_inc,
    output reg [11:0] o_aw_base,
    output reg [11:0] o_aw_amp,
    output reg [ 7:0] o_aw_rate,

    // Stager
    output reg [31:0] o_staging_control,

    // Volume
    output reg [6:0] o_volume_control
);

    localparam ADDR_OD = 8'd1;
    localparam ADDR_FZ = 8'd2;
    localparam ADDR_DT = 8'd3;
    localparam ADDR_RV = 8'd4;
    localparam ADDR_NG = 8'd5;
    localparam ADDR_DE = 8'd6;
    localparam ADDR_FG = 8'd7;
    localparam ADDR_CH = 8'd8;
    localparam ADDR_AW = 8'd9;
    localparam ADDR_ST = 8'd10;
    localparam ADDR_VL = 8'd11;


    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            // Overdrive
            o_od_gain  <= 10'd500;
            o_od_level <= 16'd32768;

            // Fuzz
            o_fz_gain  <= 10'd500;
            o_fz_level <= 16'd32768;

            // Distortion
            o_dt_gain  <= 10'd500;
            o_dt_level <= 16'd32768;

            // Reverb
            o_rv_w_rate  <= 8'd32;
            o_rv_ap_gain <= 8'd24;

            // Noise Gate
            o_ng_rise_rate  <= 8'd10;
            o_ng_decay_rate <= 8'd2;
            o_ng_hold       <= 16'd24000;
            o_ng_thres_lo   <= 15'b000_0010_0000_0000;
            o_ng_thres_hi   <= 15'b000_0100_0000_0000;

            // Delay Effect
            o_de_time     <= 16'd12000;
            o_de_feedback <= 8'b0100_0000;
            o_de_mix      <= 8'b0010_0000;

            // Flanger
            o_fg_inc  <= 7'b0000010;
            o_fg_base <= 10'd512;
            o_fg_amp  <= 10'd128;
            o_fg_gain <= 8'd64;
            o_fg_rate <= 8'd64;

            // Chorus
            o_ch_inc  <= 7'b0000010;
            o_ch_base <= 12'd512;
            o_ch_amp  <= 12'd128;
            o_ch_rate <= 8'd64;

            // Auto-Wah
            o_aw_inc  <= 7'b0000010;
            o_aw_base <= 12'd512;
            o_aw_amp  <= 12'd128;
            o_aw_rate <= 8'd64;

            // Stager
            o_staging_control <= 32'd0;

            // Volume
            o_volume_control <= 7'd127;

        end else begin
            if (i_valid) begin
                case (i_command[255:248])
                    ADDR_OD: begin
                        o_od_gain <= i_command[9:0];
                        o_od_level <= i_command[31:16];
                    end

                    ADDR_FZ: begin
                        o_fz_gain <= i_command[9:0];
                        o_fz_level <= i_command[31:16];
                    end

                    ADDR_DT: begin
                        o_dt_gain <= i_command[9:0];
                        o_dt_level <= i_command[31:16];
                    end

                    ADDR_RV: begin
                        o_rv_w_rate  <= i_command[7:0];
                        o_rv_ap_gain <= i_command[23:16];
                    end

                    ADDR_NG: begin
                        o_ng_rise_rate  <= i_command[7:0];
                        o_ng_decay_rate <= i_command[23:16];
                        o_ng_hold       <= i_command[47:32];
                        o_ng_thres_lo   <= i_command[62:48];
                        o_ng_thres_hi   <= i_command[78:64];
                    end

                    ADDR_DE: begin
                        o_de_time       <= i_command[15:0];
                        o_de_feedback   <= i_command[23:16];
                        o_de_mix        <= i_command[39:32];
                    end

                    ADDR_FG: begin
                        o_fg_inc        <= i_command[6:0];
                        o_fg_base       <= i_command[25:16];
                        o_fg_amp        <= i_command[41:32];
                        o_fg_gain       <= i_command[55:48];
                        o_fg_rate       <= i_command[71:64];
                    end

                    ADDR_CH: begin
                        o_ch_inc        <= i_command[6:0];
                        o_ch_base       <= i_command[27:16];
                        o_ch_amp        <= i_command[43:32];
                        o_ch_rate       <= i_command[55:48];
                    end

                    ADDR_AW: begin
                        o_aw_inc        <= i_command[6:0];
                        o_aw_base       <= i_command[27:16];
                        o_aw_amp        <= i_command[43:32];
                        o_aw_rate       <= i_command[55:48];
                    end

                    ADDR_ST: begin
                        o_staging_control <= i_command[31:0];
                    end

                    ADDR_VL: begin
                        o_volume_control <= i_command[6:0];
                    end

                endcase
            end
        end
    end
endmodule