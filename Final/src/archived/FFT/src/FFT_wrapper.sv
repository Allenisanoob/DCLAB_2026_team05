// -----------------------------------------------------------------------------
// FFT_audio_wrapper.sv
// Minimal audio-to-Intel-FFT Avalon-ST wrapper for DE2-115 audio analysis.
//
//   - FFT size is 4096.
//   - Input audio sample is signed 16-bit PCM / Q1.15 style.
//   - Input sample and i_audio_valid are synchronous to i_clk.
//
//
// -----------------------------------------------------------------------------

module FFT_audio_wrapper #(
    parameter int FFT_N = 4096,
    parameter int CNT_W = 12       // log2(4096) = 12
)(
    input  logic                  i_clk,
    input  logic                  i_rst_n,          // active-low reset

    input  logic signed [15:0]    i_audio_sample,
    input  logic                  i_audio_valid,

    // Debug: FFT sink/input side
    output logic                  o_sink_valid,
    output logic                  o_sink_ready,
    output logic                  o_sink_sop,
    output logic                  o_sink_eop,
    output logic signed [15:0]    o_sink_real,
    output logic signed [15:0]    o_sink_imag,
    output logic [CNT_W-1:0]      o_in_cnt,
    output logic                  o_input_drop,

    // Debug/result: FFT source/output side
    output logic                  o_bin_valid,
    output logic                  o_bin_sop,
    output logic                  o_bin_eop,
    output logic [CNT_W-1:0]      o_bin_idx,
    output logic signed [15:0]    o_fft_real,
    output logic signed [15:0]    o_fft_imag,
    output logic [5:0]            o_fft_exp,
    output logic [1:0]            o_source_error
);

    localparam logic [CNT_W-1:0] LAST_CNT = FFT_N - 1;

    // -------------------------------------------------------------------------
    // One-sample input buffer
    // -------------------------------------------------------------------------
    logic                  sample_buf_valid;
    logic signed [15:0]    sample_buf;

    logic                  sink_valid;
    logic                  sink_ready;
    logic                  sink_sop;
    logic                  sink_eop;
    logic signed [15:0]    sink_real;
    logic signed [15:0]    sink_imag;
    logic [CNT_W-1:0]      in_cnt;
    logic                  input_fire;

    // -------------------------------------------------------------------------
    // Synchronize i_audio_valid into i_clk domain and detect rising edge
    // -------------------------------------------------------------------------
    logic audio_valid_meta;
    logic audio_valid_sync;
    logic audio_valid_sync_d;
    logic audio_valid_pulse;

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            audio_valid_meta   <= 1'b0;
            audio_valid_sync   <= 1'b0;
            audio_valid_sync_d <= 1'b0;
        end else begin
            audio_valid_meta   <= i_audio_valid;
            audio_valid_sync   <= audio_valid_meta;
            audio_valid_sync_d <= audio_valid_sync;
        end
    end

    assign audio_valid_pulse = audio_valid_sync && !audio_valid_sync_d;

    assign input_fire = sink_valid && sink_ready;

    // Present the buffered sample to the FFT IP.
    assign sink_valid = sample_buf_valid;
    assign sink_real  = sample_buf;
    assign sink_imag  = 16'sd0;
    assign sink_sop   = sample_buf_valid && (in_cnt == '0);
    assign sink_eop   = sample_buf_valid && (in_cnt == LAST_CNT);

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sample_buf_valid <= 1'b0;
            sample_buf       <= 16'sd0;
            o_input_drop     <= 1'b0;
        end else begin
            o_input_drop <= 1'b0;

            // FFT accepted the currently buffered sample.
            if (input_fire) begin
                sample_buf_valid <= 1'b0;
            end

            // Capture only once for each audio_valid rising edge.
            if (audio_valid_pulse) begin
                if (!sample_buf_valid || input_fire) begin
                    sample_buf       <= i_audio_sample;
                    sample_buf_valid <= 1'b1;
                end else begin
                    o_input_drop <= 1'b1;
                end
            end
        end
    end

    // Count accepted FFT input samples, not raw i_audio_valid pulses.
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            in_cnt <= '0;
        end else begin
            if (input_fire) begin
                if (in_cnt == LAST_CNT)
                    in_cnt <= '0;
                else
                    in_cnt <= in_cnt + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // FFT output side
    // -------------------------------------------------------------------------
    logic                  source_valid;
    logic                  source_ready;
    logic [1:0]            source_error;
    logic                  source_sop;
    logic                  source_eop;
    logic signed [15:0]    source_real;
    logic signed [15:0]    source_imag;
    logic [5:0]            source_exp;
    logic [CNT_W-1:0]      out_cnt;

    assign source_ready = 1'b1;
    

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            out_cnt <= '0;
        end else begin
            if (source_valid && source_ready) begin
                if (source_sop)
                    out_cnt <= {{(CNT_W-1){1'b0}}, 1'b1};
                else if (source_eop)
                    out_cnt <= '0;
                else
                    out_cnt <= out_cnt + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Debug/output assignments
    // -------------------------------------------------------------------------
    assign o_sink_valid  = sink_valid;
    assign o_sink_ready  = sink_ready;
    assign o_sink_sop    = sink_sop;
    assign o_sink_eop    = sink_eop;
    assign o_sink_real   = sink_real;
    assign o_sink_imag   = sink_imag;
    assign o_in_cnt      = in_cnt;

    assign o_bin_valid   = source_valid;
    assign o_bin_sop     = source_sop;
    assign o_bin_eop     = source_eop;
    assign o_bin_idx     = source_sop ? '0 : out_cnt;
    assign o_fft_real    = source_real;
    assign o_fft_imag    = source_imag;
    assign o_fft_exp     = source_exp;
    assign o_source_error = source_error;

    // -------------------------------------------------------------------------
    // Intel FFT IP
    // -------------------------------------------------------------------------
    FFT_615 FFT (
        .clk          (i_clk),
        .reset_n      (i_rst_n),

        .sink_valid   (sink_valid),
        .sink_ready   (sink_ready),
        .sink_error   (2'b00),
        .sink_sop     (sink_sop),
        .sink_eop     (sink_eop),
        .sink_real    (sink_real),
        .sink_imag    (sink_imag),
        .inverse      (1'b0),

        .source_valid (source_valid),
        .source_ready (source_ready),
        .source_error (source_error),
        .source_sop   (source_sop),
        .source_eop   (source_eop),
        .source_real  (source_real),
        .source_imag  (source_imag),
        .source_exp   (source_exp)
    );

endmodule
