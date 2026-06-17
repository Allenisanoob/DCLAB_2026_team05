module fft_top4_detector #(
    parameter int FFT_N       = 4096,
    parameter int SAMPLE_RATE = 48000,
    parameter int BIN_W       = $clog2(FFT_N),
    parameter int DATA_W      = 16,
    parameter int FREQ_W      = 17
)(
    input  logic                       i_clk,
    input  logic                       i_rst_n,   // active-low reset

    // FFT bin stream from FFT_audio_wrapper
    input  logic                       i_bin_valid,
    input  logic                       i_bin_sop,
    input  logic                       i_bin_eop,
    input  logic [BIN_W-1:0]           i_bin_idx,
    input  logic signed [DATA_W-1:0]   i_fft_real,
    input  logic signed [DATA_W-1:0]   i_fft_imag,

    // one-cycle pulse when new top4 result is updated
    output logic                       o_peak_valid,

    output logic [BIN_W-1:0]           o_bin_1,
    output logic [BIN_W-1:0]           o_bin_2,
    output logic [BIN_W-1:0]           o_bin_3,
    output logic [BIN_W-1:0]           o_bin_4,

    output logic [FREQ_W-1:0]          o_freq_1,
    output logic [FREQ_W-1:0]          o_freq_2,
    output logic [FREQ_W-1:0]          o_freq_3,
    output logic [FREQ_W-1:0]          o_freq_4
);

    localparam int HALF_N  = FFT_N / 2;
    localparam int LOG2_N  = $clog2(FFT_N);
    localparam int SR_W    = $clog2(SAMPLE_RATE + 1);
    localparam int PROD_W  = BIN_W + SR_W + 1;
    localparam int MAG_W   = DATA_W + 1;

    logic [MAG_W-1:0] top_mag [0:3];
    logic [BIN_W-1:0] top_bin [0:3];

    logic [MAG_W-1:0] mag_now;
    logic             eop_d;

    // ------------------------------------------------------------
    // absolute value for signed DATA_W-bit number
    // ------------------------------------------------------------
    function automatic logic [DATA_W-1:0] abs_s(
        input logic signed [DATA_W-1:0] x
    );
        begin
            if (x == {1'b1, {(DATA_W-1){1'b0}}})
                abs_s = {1'b1, {(DATA_W-1){1'b0}}};  // most negative value
            else if (x < 0)
                abs_s = $unsigned(-x);
            else
                abs_s = $unsigned(x);
        end
    endfunction

    // ------------------------------------------------------------
    // approximate magnitude:
    // mag ~= max(|real|, |imag|) + min(|real|, |imag|)/2
    // This avoids real^2 + imag^2, so it is much cheaper in FPGA.
    // ------------------------------------------------------------
    function automatic logic [MAG_W-1:0] approx_mag(
        input logic signed [DATA_W-1:0] re,
        input logic signed [DATA_W-1:0] im
    );
        logic [DATA_W-1:0] abs_re;
        logic [DATA_W-1:0] abs_im;
        logic [DATA_W-1:0] max_v;
        logic [DATA_W-1:0] min_v;
        begin
            abs_re = abs_s(re);
            abs_im = abs_s(im);

            if (abs_re >= abs_im) begin
                max_v = abs_re;
                min_v = abs_im;
            end else begin
                max_v = abs_im;
                min_v = abs_re;
            end

            approx_mag = {1'b0, max_v} + ({1'b0, min_v} >> 1);
        end
    endfunction

    assign mag_now = approx_mag(i_fft_real, i_fft_imag);

    // ------------------------------------------------------------
    // bin to frequency, rounded:
    // freq = bin * SAMPLE_RATE / FFT_N
    // For FFT_N = 4096, division is >> 12.
    // ------------------------------------------------------------
    function automatic logic [FREQ_W-1:0] bin_to_freq(
        input logic [BIN_W-1:0] bin
    );
        logic [PROD_W-1:0] prod;
        begin
            prod = bin * SAMPLE_RATE;
            bin_to_freq = (prod + (FFT_N / 2)) >> LOG2_N;
        end
    endfunction

    // ------------------------------------------------------------
    // main top4 logic
    // ------------------------------------------------------------
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            eop_d        <= 1'b0;
            o_peak_valid <= 1'b0;

            for (int i = 0; i < 4; i++) begin
                top_mag[i] <= '0;
                top_bin[i] <= '0;
            end

            o_bin_1  <= '0;
            o_bin_2  <= '0;
            o_bin_3  <= '0;
            o_bin_4  <= '0;

            o_freq_1 <= '0;
            o_freq_2 <= '0;
            o_freq_3 <= '0;
            o_freq_4 <= '0;
        end else begin
            o_peak_valid <= eop_d;
            eop_d        <= i_bin_valid && i_bin_eop;

            // One cycle after EOP, latch final top4 output.
            if (eop_d) begin
                o_bin_1  <= top_bin[0];
                o_bin_2  <= top_bin[1];
                o_bin_3  <= top_bin[2];
                o_bin_4  <= top_bin[3];

                o_freq_1 <= bin_to_freq(top_bin[0]);
                o_freq_2 <= bin_to_freq(top_bin[1]);
                o_freq_3 <= bin_to_freq(top_bin[2]);
                o_freq_4 <= bin_to_freq(top_bin[3]);
            end

            if (i_bin_valid) begin
                // Clear top4 at the start of each FFT output frame.
                if (i_bin_sop) begin
                    for (int i = 0; i < 4; i++) begin
                        top_mag[i] <= '0;
                        top_bin[i] <= '0;
                    end
                end

                // Search only positive-frequency bins:
                // bin 1 ~ FFT_N/2 - 1.
                // Ignore bin 0 DC and bin FFT_N/2 Nyquist.
                else if ((i_bin_idx > 0) && (i_bin_idx < HALF_N)) begin
                    if (mag_now > top_mag[0]) begin
                        top_mag[3] <= top_mag[2];
                        top_bin[3] <= top_bin[2];

                        top_mag[2] <= top_mag[1];
                        top_bin[2] <= top_bin[1];

                        top_mag[1] <= top_mag[0];
                        top_bin[1] <= top_bin[0];

                        top_mag[0] <= mag_now;
                        top_bin[0] <= i_bin_idx;
                    end else if (mag_now > top_mag[1]) begin
                        top_mag[3] <= top_mag[2];
                        top_bin[3] <= top_bin[2];

                        top_mag[2] <= top_mag[1];
                        top_bin[2] <= top_bin[1];

                        top_mag[1] <= mag_now;
                        top_bin[1] <= i_bin_idx;
                    end else if (mag_now > top_mag[2]) begin
                        top_mag[3] <= top_mag[2];
                        top_bin[3] <= top_bin[2];

                        top_mag[2] <= mag_now;
                        top_bin[2] <= i_bin_idx;
                    end else if (mag_now > top_mag[3]) begin
                        top_mag[3] <= mag_now;
                        top_bin[3] <= i_bin_idx;
                    end
                end
            end
        end
    end

endmodule
