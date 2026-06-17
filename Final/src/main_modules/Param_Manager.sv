module Param_Manager(
    input i_clk,
    input i_rst,

    input [255:0] i_command,
    input i_valid,
    
    // Overdrive
    output reg [9:0] o_od_gain,

    // Fuzz
    output reg [9:0] o_fz_gain,

    // Distortion
    output reg [9:0] o_dt_gain,

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
    output reg [ 7:0] o_aw_rate
);


endmodule