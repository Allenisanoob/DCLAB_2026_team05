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

    input         i_sram_ready    // SRAM scheduler is not full
);  

    logic [17:0] i_fx_sw_w, i_fx_sw_r;
    assign i_fx_sw_w = i_fx_sw;

    logic signed [15:0] original_data, final_data;
    logic original_valid, final_valid;
    
    logic signed [15:0] processed_data;
    logic processed_valid;

    /* -------------------------------------------------------------
    |               For Testing Independent Modules                |
    ------------------------------------------------------------- */
    logic signed [15:0] od_data;
    logic signed [15:0] fuzz_data;
    logic signed [15:0] dist_data;
    logic signed [15:0] reverb_data;
    logic signed [15:0] ng_data;
    logic signed [15:0] de_data;

    logic od_valid,     od_en;
    logic fuzz_valid,   fuzz_en;
    logic dist_valid,   dist_en;
    logic reverb_valid, reverb_en;
    logic ng_valid,     ng_en;
    logic de_valid,     de_en;

    assign od_en     = (i_fx_sw_r[5:0] == 6'b000001) ? original_valid : 1'b0;
    assign fuzz_en   = (i_fx_sw_r[5:0] == 6'b000010) ? original_valid : 1'b0;
    assign dist_en   = (i_fx_sw_r[5:0] == 6'b000100) ? original_valid : 1'b0;
    assign reverb_en = (i_fx_sw_r[5:0] == 6'b001000) ? original_valid : 1'b0;
    assign ng_en     = (i_fx_sw_r[5:0] == 6'b010000) ? original_valid : 1'b0;
    assign de_en     = (i_fx_sw_r[5:0] == 6'b100000) ? original_valid : 1'b0;
    /* -------------------------------------------------------------
    |               For Testing Independent Modules                |
    ------------------------------------------------------------- */

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

    /* ----------------------------------------------------------------
    |    Placeholder for now, should be replaced by the stager        |
    ---------------------------------------------------------------- */

        // TODO: Implement the stager to pipeline the data through the DSP blocks
        // Stager8 stager8 ();

    /* ----------------------------------------------------------------
    |    Placeholder for now, should be replaced by the stager        |
    ---------------------------------------------------------------- */

    // Final Volume Control
    logic [6:0] i_volume_control; // 0 - Muted, 127 - Full Volume
    assign i_volume_control = 7'd127; // Full volume for now, can be controlled by the user interface later
    Volume final_volume (
        .i_prev_valid       (processed_valid),
        .i_data             (processed_data),
        .i_volume_control   (i_volume_control),
        .o_next_valid       (final_valid),
        .o_data             (final_data)
    );


    // // Overdrive, Fuzz, Distortion
    // logic [7:0] i_gain; 
    // assign i_gain = 8'd100;
    // overdrive OverDrive(
    //     .i_clk  (i_clk),
    //     .i_rst  (i_rst),
    //     .i_data (original_data),
    //     .i_gain (i_gain),
    //     .i_en   (od_en),
    //     .o_data (od_data),
    //     .o_en   (od_valid)
    // );

    // fuzz Fuzz(
    //     .i_clk  (i_clk),
    //     .i_rst  (i_rst),
    //     .i_data (original_data),
    //     .i_gain (i_gain),
    //     .i_en   (fuzz_en),
    //     .o_data (fuzz_data),
    //     .o_en   (fuzz_valid)
    // );

    // distortion Distortion(
    //     .i_clk  (i_clk),
    //     .i_rst  (i_rst),
    //     .i_data (original_data),
    //     .i_gain (i_gain),
    //     .i_en   (dist_en),
    //     .o_data (dist_data),
    //     .o_en   (dist_valid)
    // );

    // // Reverb
    // logic [23:0] r; 
    // logic signed [15:0] i_cosw;
    // logic [7:0] w_rate;
    // assign r      = 24'd15099494; // about 0.999
    // assign i_cosw = 16'sd16384;   // about 1000 Hz
    // assign w_rate = 8'd128;       // 0.5
    // Reverb_basic Reverb(
    //     .i_clk    (i_clk),
    //     .i_rst    (i_rst),
    //     .i_data   (original_data),
    //     .r        (r),
    //     .i_cosw   (i_cosw),
    //     .w_rate   (w_rate),
    //     .i_valid  (reverb_en),
    //     .o_data   (reverb_data),
    //     .o_valid  (reverb_valid)
    // );

    Reverb Reverb(
        .clk(i_clk),
        .rst(i_rst),
        .in_valid(reverb_en),
        .in(original_data),
        .out_valid(reverb_valid),
        .out(reverb_data)
    );

    // Noise Gate
    logic [7:0]  ng_rise_rate;      // in bits
    logic [7:0]  ng_decay_rate;     // in bits
    logic [15:0] ng_hold;          // in samples
    logic [14:0] ng_threshold_lo;  // unsigned Q0.15
    logic [14:0] ng_threshold_hi;  // unsigned Q0.15
    // assign ng_rise_rate  = 16'b0000_0000_0000_1000;  // 1/8192
    // assign ng_decay_rate = 16'b0000_0000_0000_0010;  // 1/32768
    assign ng_rise_rate  = 8'd4;    // about 4/256
    assign ng_decay_rate = 8'd1;    // about 1/256
    assign ng_hold = 16'd24000;    // 0.5s
    // assign ng_threshold_lo = 15'b00010_00000_00000;    // 1/16 max strength
    // assign ng_threshold_hi = 15'b00100_00000_00000;    // 2/16 max strength
    assign ng_threshold_lo = 15'b10000_00000_00000;    //  4/8 max strength
    assign ng_threshold_hi = 15'b11000_00000_00000;    //  6/8 max strength
    Noise_Gate Noise_Gate(
        .i_clk          (i_clk),
        .i_rst          (i_rst),
        .i_prev_valid   (ng_en),
        .i_data         (original_data),
        .i_rise_rate    (ng_rise_rate),
        .i_decay_rate   (ng_decay_rate),
        .i_hold         (ng_hold),
        .i_threshold_lo (ng_threshold_lo),
        .i_threshold_hi (ng_threshold_hi),
        .o_next_valid   (ng_valid),
        .o_data         (ng_data)
    );

    // Delay Effect
    logic [15:0] de_time;     // Delay duration in samples
    logic [7:0]  de_feedback; // Feedback ratio (0 to 127, where 128 is 100%)
    logic [7:0]  de_mix;      // Mix ratio      (0 to 127, where 128 is 100%)
    assign de_time = 16'd24000;         // 0.5s
    assign de_feedback = 8'd0001_1000;  // x0.375
    assign de_mix = 8'd0110_0000;       // x0.375
    Delay_Effect #(.BASE_ADDR(20'h00000)) Delay_Effect(
        .i_clk          (i_clk),
        .i_rst          (i_rst),
        .i_prev_valid   (de_en),
        .i_data         (original_data),
        .i_time         (de_time),
        .i_feedback     (de_feedback),
        .i_mix          (de_mix),
        .o_next_valid   (de_valid),
        .o_data         (de_data),
        // SRAM connection
        .o_SRAM_r_addr  (o_B0_r_addr),
        .i_SRAM_r_data  (i_B0_r_data),
        .o_read_req     (o_B0_read_req),
        .i_read_valid   (i_B0_read_valid),
        .o_SRAM_w_addr  (o_B0_w_addr),
        .o_SRAM_w_data  (o_B0_w_data),
        .o_write_req    (o_B0_write_req)
    );
  

    always_comb begin
        processed_data  = original_data;
        processed_valid = original_valid;

        case (i_fx_sw_r[5:0])
            // 6'b000001: begin
            //     processed_data  = od_data;
            //     processed_valid = od_valid;
            // end

            // 6'b000010: begin
            //     processed_data  = fuzz_data;
            //     processed_valid = fuzz_valid;
            // end

            // 6'b000100: begin
            //     processed_data  = dist_data;
            //     processed_valid = dist_valid;
            // end

            6'b001000: begin
                processed_data  = reverb_data;
                processed_valid = reverb_valid;
            end

            6'b010000: begin
                processed_data  = ng_data;
                processed_valid = ng_valid;
            end

            6'b100000: begin
                processed_data  = de_data;
                processed_valid = de_valid;
            end

            default: begin
                processed_data  = original_data;
                processed_valid = original_valid;
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