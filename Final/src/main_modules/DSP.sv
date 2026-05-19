module DSP (
    // Main chain I/O
    input         i_rst,
    input         i_clk,
    input         i_R2D_valid,
    input  signed [15:0] i_raw_data,
    output        o_D2B_valid,
    output signed [15:0] o_buf_data_l,
    output signed [15:0] o_buf_data_r,

    // SRAM I/O for 4 blocks (B0-B3)
    output [19:0] o_B0_r_addr,
    input  [15:0] i_B0_r_data,
    output        o_B0_read_req,
    input         i_B0_read_valid,
    output [19:0] o_B0_w_addr,
    output [15:0] o_B0_w_data,
    output        o_B0_write_req,

    output [19:0] o_B1_r_addr,
    input  [15:0] i_B1_r_data,
    output        o_B1_read_req,
    input         i_B1_read_valid,
    output [19:0] o_B1_w_addr,
    output [15:0] o_B1_w_data,
    output        o_B1_write_req,

    output [19:0] o_B2_r_addr,
    input  [15:0] i_B2_r_data,
    output        o_B2_read_req,
    input         i_B2_read_valid,
    output [19:0] o_B2_w_addr,
    output [15:0] o_B2_w_data,
    output        o_B2_write_req,

    output [19:0] o_B3_r_addr,
    input  [15:0] i_B3_r_data,
    output        o_B3_read_req,
    input         i_B3_read_valid,
    output [19:0] o_B3_w_addr,
    output [15:0] o_B3_w_data,
    output        o_B3_write_req,

    input         i_sram_ready,    // SRAM scheduler is not full
    input         sw
);
    
    logic [6:0] i_volume_control; // 0 - Muted, 127 - Full Volume
    logic original_valid, final_valid;
    logic signed [15:0] original_data, final_data;

    //For testing Reverb
    logic [7:0] r; 
    logic [15:0] i_cosw;
    logic [7:0] w_rate;
    assign r = 8'd255; // Reverb intensity, can be controlled by the user interface later
    assign i_cosw = 16'sd16384; // cos(2*pi*1000Hz/48000Hz) in Q15 format, can be calculated for different frequencies if needed
   // assign w_rate = 8'd255; // Reverb update rate, can be controlled by the user interface later
    assign w_rate = sw ?  8'd0 : 8'd250; 
    
    // For testing Overdrive, Fuzz, Distortion
    logic [7:0] i_gain; 
    assign i_gain = 8'd100;

    assign o_D2B_valid = final_valid;
    assign o_buf_data_l = final_data; // Playing the same data on both channels for now
    assign o_buf_data_r = final_data; // Playing the same data on both channels for now

    // Raw Data Catcher
    Data_Catcher raw_data_catcher (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_raw_valid(i_R2D_valid),
        .i_data(i_raw_data),
        .o_next_valid(original_valid),
        .o_data(original_data)
    );
    
    // TODO: Implement the stager to pipeline the data through the DSP blocks
    // Stager8 stager8 ();

    /* -------------------------------------------------------------
    |    Placeholder for now, should replaced by the stager        |
    ------------------------------------------------------------- */
    logic processed_valid;
    logic signed [15:0] processed_data;
    assign processed_valid = original_valid;
    assign processed_data = original_data;
    /* -------------------------------------------------------------
    |    Placeholder for now, should replaced by the stager        |
    ------------------------------------------------------------- */
/*
    // Final Volume Control
    assign i_volume_control = 127; // Full volume for now, can be controlled by the user interface later
    Volume final_volume (
        .i_prev_valid(processed_valid),
        .i_data(processed_data),
        .i_volume_control(i_volume_control),
        .o_next_valid(final_valid),
        .o_data(final_data)
    );
*/
/*
    overdrive OverDrive(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(processed_data),
        .i_gain(i_gain),
        .i_en(processed_valid),
        .o_data(final_data),
        .o_en(final_valid)
    );
*/
 Reverb_basic Reverb(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(processed_data),
        .r(r),
        .i_cosw(i_cosw),
        .w_rate(w_rate),
        .i_valid(processed_valid),
        .o_data(final_data),
        .o_valid(final_valid)
    );
/*
    fuzz Fuzz(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(processed_data),
        .i_gain(i_gain),
        .i_en(processed_valid),
        .o_data(final_data),
        .o_en(final_valid)
    );
*/
/*
    distortion Distortion(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(processed_data),
        .i_gain(i_gain),
        .i_en(processed_valid),
        .o_data(final_data),
        .o_en(final_valid)
    );
*/

endmodule