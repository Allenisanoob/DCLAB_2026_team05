module DSP (
    // Main chain I/O
    input         i_rst,
    input         i_clk,
    input         i_R2D_valid,
    input  signed [15:0] i_raw_data,

    input  [17:0]  i_fx_sw,

    output        o_D2B_valid,
    output signed [15:0] o_buf_data_l,
    output signed [15:0] o_buf_data_r,

    // // SRAM I/O for 4 blocks (B0-B3)
    // output [19:0] o_B0_r_addr,
    // input  [15:0] i_B0_r_data,
    // output        o_B0_read_req,
    // input         i_B0_read_valid,
    // output [19:0] o_B0_w_addr,
    // output [15:0] o_B0_w_data,
    // output        o_B0_write_req,

    // output [19:0] o_B1_r_addr,
    // input  [15:0] i_B1_r_data,
    // output        o_B1_read_req,
    // input         i_B1_read_valid,
    // output [19:0] o_B1_w_addr,
    // output [15:0] o_B1_w_data,
    // output        o_B1_write_req,

    // output [19:0] o_B2_r_addr,
    // input  [15:0] i_B2_r_data,
    // output        o_B2_read_req,
    // input         i_B2_read_valid,
    // output [19:0] o_B2_w_addr,
    // output [15:0] o_B2_w_data,
    // output        o_B2_write_req,

    // output [19:0] o_B3_r_addr,
    // input  [15:0] i_B3_r_data,
    // output        o_B3_read_req,
    // input         i_B3_read_valid,
    // output [19:0] o_B3_w_addr,
    // output [15:0] o_B3_w_data,
    // output        o_B3_write_req,

    // input         i_sram_ready,    // SRAM scheduler is not full
    output [15:0] o_dsp_ledr
);  

    logic [17:0] i_fx_sw_w, i_fx_sw_r;
    assign i_fx_sw_w = i_fx_sw;
//    assign o_dsp_ledr[8:0] = i_fx_sw_r[8:0];

    logic signed [15:0] original_data, final_data;
    logic original_valid, final_valid;
    
    logic signed [15:0] processed_data;
    logic processed_valid;

    assign o_D2B_valid = final_valid;
    assign o_buf_data_l = final_data; // Playing the same data on both channels for now
    assign o_buf_data_r = final_data; // Playing the same data on both channels for now

    // Block I/O
    logic signed [15:0] OD_data_in, OD_data_out;
    logic signed [15:0] FZ_data_in, FZ_data_out;
    logic signed [15:0] DT_data_in, DT_data_out;
    logic signed [15:0] RV_data_in, RV_data_out;
    logic signed [15:0] NG_data_in, NG_data_out;
    logic signed [15:0] DE_data_in, DE_data_out;
    logic signed [15:0] FG_data_in, FG_data_out;
    logic signed [15:0] CH_data_in, CH_data_out;
    logic signed [15:0] AW_data_in, AW_data_out;
    
    logic OD_valid_in, OD_valid_out;
    logic FZ_valid_in, FZ_valid_out;
    logic DT_valid_in, DT_valid_out;
    logic RV_valid_in, RV_valid_out;
    logic NG_valid_in, NG_valid_out;
    logic DE_valid_in, DE_valid_out;
    logic FG_valid_in, FG_valid_out;
    logic CH_valid_in, CH_valid_out;
    logic AW_valid_in, AW_valid_out;

    // Raw Data Catcher
    Data_Catcher raw_data_catcher (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_raw_valid(i_R2D_valid),
        .i_data(i_raw_data),
        .o_next_valid(original_valid),
        .o_data(original_data)
    );

    logic stft_valid;
    logic [31:0] amp_sq_E2;
    logic [31:0] amp_sq_F2;
    logic [31:0] amp_sq_Fs2;
    logic [31:0] amp_sq_G2;
    logic [31:0] amp_sq_Gs2;
    logic [31:0] amp_sq_A2;
    logic [31:0] amp_sq_As2;
    logic [31:0] amp_sq_B2;
    logic [31:0] amp_sq_C3;
    logic [31:0] amp_sq_Cs3;
    logic [31:0] amp_sq_D3;
    logic [31:0] amp_sq_Ds3;
    logic [31:0] amp_sq_E3;
    logic [31:0] amp_sq_F3;
    logic [31:0] amp_sq_Fs3;
    logic [31:0] amp_sq_G3;
    logic [31:0] amp_sq_Gs3;
    logic [31:0] amp_sq_A3;
    logic [31:0] amp_sq_As3;
    logic [31:0] amp_sq_B3;
    logic [31:0] amp_sq_C4;
    logic [31:0] amp_sq_Cs4;
    logic [31:0] amp_sq_D4;
    logic [31:0] amp_sq_Ds4;
    logic [31:0] amp_sq_E4;
    logic [31:0] amp_sq_F4;
    logic [31:0] amp_sq_Fs4;
    logic [31:0] amp_sq_G4;
    logic [31:0] amp_sq_Gs4;
    logic [31:0] amp_sq_A4;
    logic [31:0] amp_sq_As4;
    logic [31:0] amp_sq_B4;
    logic [31:0] amp_sq_C5;
    logic [31:0] amp_sq_Cs5;
    logic [31:0] amp_sq_D5;
    logic [31:0] amp_sq_Ds5;

    STFT stft (
        .clk(i_clk),
        .rst(i_rst),
        .in_valid(original_valid),
        .in(original_data),
        .out_valid(stft_valid),
        .amp_sq_E2(amp_sq_E2),
        .amp_sq_F2(amp_sq_F2),
        .amp_sq_Fs2(amp_sq_Fs2),
        .amp_sq_G2(amp_sq_G2),
        .amp_sq_Gs2(amp_sq_Gs2),
        .amp_sq_A2(amp_sq_A2),
        .amp_sq_As2(amp_sq_As2),
        .amp_sq_B2(amp_sq_B2),
        .amp_sq_C3(amp_sq_C3),
        .amp_sq_Cs3(amp_sq_Cs3),
        .amp_sq_D3(amp_sq_D3),
        .amp_sq_Ds3(amp_sq_Ds3),
        .amp_sq_E3(amp_sq_E3),
        .amp_sq_F3(amp_sq_F3),
        .amp_sq_Fs3(amp_sq_Fs3),
        .amp_sq_G3(amp_sq_G3),
        .amp_sq_Gs3(amp_sq_Gs3),
        .amp_sq_A3(amp_sq_A3),
        .amp_sq_As3(amp_sq_As3),
        .amp_sq_B3(amp_sq_B3),
        .amp_sq_C4(amp_sq_C4),
        .amp_sq_Cs4(amp_sq_Cs4),
        .amp_sq_D4(amp_sq_D4),
        .amp_sq_Ds4(amp_sq_Ds4),
        .amp_sq_E4(amp_sq_E4),
        .amp_sq_F4(amp_sq_F4),
        .amp_sq_Fs4(amp_sq_Fs4),
        .amp_sq_G4(amp_sq_G4),
        .amp_sq_Gs4(amp_sq_Gs4),
        .amp_sq_A4(amp_sq_A4),
        .amp_sq_As4(amp_sq_As4),
        .amp_sq_B4(amp_sq_B4),
        .amp_sq_C5(amp_sq_C5),
        .amp_sq_Cs5(amp_sq_Cs5),
        .amp_sq_D5(amp_sq_D5),
        .amp_sq_Ds5(amp_sq_Ds5)
    );

    logic find_4_in_36_valid;
    logic [35:0] notes;

    Find_4_in_36 find_4_in_36 (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(stft_valid),
        .amp_sq_E2(amp_sq_E2),
        .amp_sq_F2(amp_sq_F2),
        .amp_sq_Fs2(amp_sq_Fs2),
        .amp_sq_G2(amp_sq_G2),
        .amp_sq_Gs2(amp_sq_Gs2),
        .amp_sq_A2(amp_sq_A2),
        .amp_sq_As2(amp_sq_As2),
        .amp_sq_B2(amp_sq_B2),
        .amp_sq_C3(amp_sq_C3),
        .amp_sq_Cs3(amp_sq_Cs3),
        .amp_sq_D3(amp_sq_D3),
        .amp_sq_Ds3(amp_sq_Ds3),
        .amp_sq_E3(amp_sq_E3),
        .amp_sq_F3(amp_sq_F3),
        .amp_sq_Fs3(amp_sq_Fs3),
        .amp_sq_G3(amp_sq_G3),
        .amp_sq_Gs3(amp_sq_Gs3),
        .amp_sq_A3(amp_sq_A3),
        .amp_sq_As3(amp_sq_As3),
        .amp_sq_B3(amp_sq_B3),
        .amp_sq_C4(amp_sq_C4),
        .amp_sq_Cs4(amp_sq_Cs4),
        .amp_sq_D4(amp_sq_D4),
        .amp_sq_Ds4(amp_sq_Ds4),
        .amp_sq_E4(amp_sq_E4),
        .amp_sq_F4(amp_sq_F4),
        .amp_sq_Fs4(amp_sq_Fs4),
        .amp_sq_G4(amp_sq_G4),
        .amp_sq_Gs4(amp_sq_Gs4),
        .amp_sq_A4(amp_sq_A4),
        .amp_sq_As4(amp_sq_As4),
        .amp_sq_B4(amp_sq_B4),
        .amp_sq_C5(amp_sq_C5),
        .amp_sq_Cs5(amp_sq_Cs5),
        .amp_sq_D5(amp_sq_D5),
        .amp_sq_Ds5(amp_sq_Ds5),
        .o_valid(find_4_in_36_valid),
        .notes(notes)
    );

    logic [14:0] o_dsp_ledr_r;

    always_ff @(posedge i_clk) begin
        if (find_4_in_36_valid) begin
            o_dsp_ledr_r[0] <= notes[12];
            o_dsp_ledr_r[1] <= notes[13];
            o_dsp_ledr_r[2] <= notes[14];
            o_dsp_ledr_r[3] <= notes[15];
            o_dsp_ledr_r[4] <= notes[16];
            o_dsp_ledr_r[5] <= notes[17];
            o_dsp_ledr_r[6] <= notes[18];
            o_dsp_ledr_r[7] <= notes[19];
            o_dsp_ledr_r[8] <= notes[20];
            o_dsp_ledr_r[9] <= notes[21];
            o_dsp_ledr_r[10] <= notes[22];
            o_dsp_ledr_r[11] <= notes[23];
            o_dsp_ledr_r[12] <= (notes[0] || notes[1] || notes[2] || notes[3] || notes[4] || notes[5] || notes[6] || notes[7] || notes[8] || notes[9] || notes[10] || notes[11]);
            o_dsp_ledr_r[13] <= (notes[12] || notes[13] || notes[14] || notes[15] || notes[16] || notes[17] || notes[18] || notes[19] || notes[20] || notes[21] || notes[22] || notes[23]);
            o_dsp_ledr_r[14] <= (notes[24] || notes[25] || notes[26] || notes[27] || notes[28] || notes[29] || notes[30] || notes[31] || notes[32] || notes[33] || notes[34] || notes[35]);
        end
    end

    assign o_dsp_ledr[14:0] = o_dsp_ledr_r;


    // Staging up to 4 modules
    logic [31:0] staging_control;
    Stager Stager(
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_staging_control(staging_control),

        .i_raw_valid(original_valid),
        .i_raw_data (original_data),

        .i_block1_out(OD_data_out),
        .i_block2_out(FZ_data_out),
        .i_block3_out(DT_data_out),
        .i_block4_out(RV_data_out),
        .i_block5_out(NG_data_out),
        .i_block6_out(DE_data_out),
        .i_block7_out(FG_data_out),
        .i_block8_out(CH_data_out),
        .i_block9_out(AW_data_out),

        .i_block1_valid_out(OD_valid_out),
        .i_block2_valid_out(FZ_valid_out),
        .i_block3_valid_out(DT_valid_out),
        .i_block4_valid_out(RV_valid_out),
        .i_block5_valid_out(NG_valid_out),
        .i_block6_valid_out(DE_valid_out),
        .i_block7_valid_out(FG_valid_out),
        .i_block8_valid_out(CH_valid_out),
        .i_block9_valid_out(AW_valid_out),

        .o_block1_in(OD_data_in),
        .o_block2_in(FZ_data_in),
        .o_block3_in(DT_data_in),
        .o_block4_in(RV_data_in),
        .o_block5_in(NG_data_in),
        .o_block6_in(DE_data_in),
        .o_block7_in(FG_data_in),
        .o_block8_in(CH_data_in),
        .o_block9_in(AW_data_in),

        .o_block1_valid_in(OD_valid_in),
        .o_block2_valid_in(FZ_valid_in),
        .o_block3_valid_in(DT_valid_in),
        .o_block4_valid_in(RV_valid_in),
        .o_block5_valid_in(NG_valid_in),
        .o_block6_valid_in(DE_valid_in),
        .o_block7_valid_in(FG_valid_in),
        .o_block8_valid_in(CH_valid_in),
        .o_block9_valid_in(AW_valid_in),

        .o_end_data (processed_data),
        .o_end_valid(processed_valid)
    );

    // Managing parameters for all modules
    logic [255:0] param_command;
    logic [7:0] test_addr;
    assign param_command = {8'd10, 216'b0, 24'b0, test_addr};
    Param_Manager Param_Manager(
        .i_clk(i_clk),
        .i_rst(i_rst),

        .i_command(param_command),
        .i_valid(1'b1),

        // Overdrive
        .o_od_gain       (od_gain),
        .o_od_level      (od_level),

        // Fuzz
        .o_fz_gain       (fz_gain),
        .o_fz_level      (fz_level),

        // Distortion
        .o_dt_gain       (dt_gain),
        .o_dt_level      (dt_level),

        // Reverb
        .o_rv_w_rate     (reverb_w_rate),
        .o_rv_ap_gain    (reverb_ap_gain),

        // Noise Gate
        .o_ng_rise_rate  (ng_rise_rate),
        .o_ng_decay_rate (ng_decay_rate),
        .o_ng_hold       (ng_hold),
        .o_ng_thres_lo   (ng_threshold_lo),
        .o_ng_thres_hi   (ng_threshold_hi),

        // Delay Effect
        .o_de_time       (de_time),
        .o_de_feedback   (de_feedback),
        .o_de_mix        (de_mix),

        // Flanger
        .o_fg_inc        (fg_inc),
        .o_fg_base       (fg_base),
        .o_fg_amp        (fg_amp),
        .o_fg_gain       (fg_gain),
        .o_fg_rate       (fg_rate),

        // Chorus
        .o_ch_inc        (ch_inc),
        .o_ch_base       (ch_base),
        .o_ch_amp        (ch_amp),
        .o_ch_rate       (ch_rate),

        // Auto-Wah
        .o_aw_inc        (aw_inc),
        .o_aw_base       (aw_base),
        .o_aw_amp        (aw_amp),
        .o_aw_rate       (aw_rate),

        // Stager
        .o_staging_control(staging_control),

        // Volume
        .o_volume_control(volume_control)
    );

    // Final Volume Control
    logic [6:0] volume_control; // 0 - Muted, 127 - Full Volume
    Volume final_volume (
        .i_prev_valid       (processed_valid),
        .i_data             (processed_data),
        .i_volume_control   (volume_control),
        .o_next_valid       (final_valid),
        .o_data             (final_data)
    );

    // Overdrive
    logic [9:0] od_gain;
    logic [15:0] od_level;
    Overdrive Overdrive(
        .i_clk  (i_clk),
        .i_rst  (i_rst),

        .i_gain (od_gain),
        .i_L    (od_level),

        .i_data (OD_data_in),
        .i_en   (OD_valid_in),
        .o_data (OD_data_out),
        .o_en   (OD_valid_out)
    );

    // Fuzz
    logic [7:0] fz_gain;
    logic [15:0] fz_level;
    fuzz Fuzz(
        .i_clk  (i_clk),
        .i_rst  (i_rst),

        .i_gain (fz_gain),
        .i_L    (fz_level),

        .i_data (FZ_data_in),
        .i_en   (FZ_valid_in),
        .o_data (FZ_data_out),
        .o_en   (FZ_valid_out)
    );

    //Distortion
    logic [7:0] dt_gain;
    logic [15:0] dt_level;
    distortion Distortion(
        .i_clk  (i_clk),
        .i_rst  (i_rst),

        .i_L    (dt_level),
        .i_gain (dt_gain),

        .i_data (DT_data_in),
        .i_en   (DT_valid_in),
        .o_data (DT_data_out),
        .o_en   (DT_valid_out)
    );

    // Reverb
    logic signed [7:0] reverb_ap_gain;
    logic [7:0] reverb_w_rate;
    Reverb Reverb(
        .clk       (i_clk),
        .rst       (i_rst),

        .w_rate    (reverb_w_rate),
        .ap_gain_0 (reverb_ap_gain),
        .ap_gain_1 (reverb_ap_gain),
        .ap_gain_2 (reverb_ap_gain),
        .ap_gain_3 (reverb_ap_gain),
        .ap_gain_4 (reverb_ap_gain),

        .in        (RV_data_in),
        .in_valid  (RV_valid_in),
        .out       (RV_data_out),
        .out_valid (RV_valid_out)
    );

    // Noise Gate
    logic [7:0]  ng_rise_rate;      // in bits
    logic [7:0]  ng_decay_rate;     // in bits
    logic [15:0] ng_hold;          // in samples
    logic [14:0] ng_threshold_lo;  // unsigned Q0.15
    logic [14:0] ng_threshold_hi;  // unsigned Q0.15
    Noise_Gate Noise_Gate(
        .i_clk          (i_clk),
        .i_rst          (i_rst),

        .i_rise_rate    (ng_rise_rate),
        .i_decay_rate   (ng_decay_rate),
        .i_hold         (ng_hold),
        .i_threshold_lo (ng_threshold_lo),
        .i_threshold_hi (ng_threshold_hi),

        .i_data         (NG_data_in),
        .i_prev_valid   (NG_valid_in),
        .o_data         (NG_data_out),
        .o_next_valid   (NG_valid_out)
    );

    // Delay Effect
    logic [15:0] de_time;     // Delay duration in samples
    logic [7:0]  de_feedback; // Feedback ratio (0 to 127, where 128 is 100%)
    logic [7:0]  de_mix;      // Mix ratio      (0 to 127, where 128 is 100%)
    Delay_Effect Delay_Effect(
        .i_clk          (i_clk),
        .i_rst          (i_rst),

        .i_time         (de_time),
        .i_feedback     (de_feedback),
        .i_mix          (de_mix),

        .i_data         (DE_data_in),
        .i_prev_valid   (DE_valid_in),
        .o_data         (DE_data_out),
        .o_next_valid   (DE_valid_out)
    );

    // Flanger
    logic [6:0] fg_inc;
    logic [9:0] fg_base;
    logic [9:0] fg_amp;
    logic [7:0] fg_gain;
    logic [7:0] fg_rate;
    Flanger Flanger(
        .clk            (i_clk),
        .rst            (i_rst),

        .inc            (fg_inc),
        .delay_base     (fg_base),
        .delay_amp      (fg_amp),
        .gain           (fg_gain),
        .w_rate         (fg_rate),

        .in             (FG_data_in),
        .in_valid       (FG_valid_in),
        .out            (FG_data_out),
        .out_valid      (FG_valid_out)
    );

    // Chorus
    logic [ 6:0] ch_inc;
    logic [11:0] ch_base;
    logic [11:0] ch_amp;
    logic [ 7:0] ch_rate;
    Chorus Chorus(
        .clk            (i_clk),
        .rst            (i_rst),

        .inc            (ch_inc),
        .delay_base     (ch_base),
        .delay_amp      (ch_amp),
        .w_rate         (ch_rate),

        .in             (CH_data_in),
        .in_valid       (CH_valid_in),
        .out            (CH_data_out),
        .out_valid      (CH_valid_out)
    );

    // Auto-Wah
    logic [ 6:0] aw_inc;
    logic [11:0] aw_base;
    logic [11:0] aw_amp;
    logic [ 7:0] aw_rate;
    Auto_Wah Auto_Wah(
        .clk            (i_clk),
        .rst            (i_rst),

        .inc            (aw_inc),
        .delay_base     (aw_base),
        .delay_amp      (aw_amp),
        .w_rate         (aw_rate),

        .in             (AW_data_in),
        .in_valid       (AW_valid_in),
        .out            (AW_data_out),
        .out_valid      (AW_valid_out)
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

    always_comb begin
        case (i_fx_sw_r[8:0])
            9'b0_0000_0001: begin
                test_addr = ADDR_OD;
            end

            9'b0_0000_0010: begin
                test_addr = ADDR_FZ;
            end

            9'b0_0000_0100: begin
                test_addr = ADDR_DT;
            end

            9'b0_0000_1000: begin
                test_addr = ADDR_RV;
            end

            9'b0_0001_0000: begin
                test_addr = ADDR_NG;
            end

            9'b0_0010_0000: begin
                test_addr = ADDR_DE;
            end

            9'b0_0100_0000: begin
                test_addr = ADDR_FG;
            end

            9'b0_1000_0000: begin
                test_addr = ADDR_CH;
            end

            9'b1_0000_0000: begin
                test_addr = ADDR_AW;
            end

            default: begin
                test_addr = 8'b0;
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            i_fx_sw_r <= 18'b0;
        end else begin
            i_fx_sw_r <= i_fx_sw_w;
        end
    end

endmodule