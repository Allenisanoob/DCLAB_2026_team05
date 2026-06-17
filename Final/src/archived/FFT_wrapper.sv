module FFT_Wrapper #(
    parameter int N     = 4096,
    parameter int LOG_N = 12,
    parameter int DATA_W = 16
)(
    input  logic                    i_clk,
    input  logic                    i_rst,

    // input sample
    input  logic signed [DATA_W-1:0] i_sample,
    input  logic                     i_sample_valid,

    // FFT output analysis
    output logic                     o_fft_out_valid,
    output logic [LOG_N-1:0]          o_bin,
    output logic signed [DATA_W-1:0]  o_fft_real,
    output logic signed [DATA_W-1:0]  o_fft_imag,
    output logic [2*DATA_W:0]         o_mag_sq,

    output logic                     o_frame_done
);

    // ============================================================
    // FFT input signals
    // ============================================================

    logic                    sink_valid;
    logic                    sink_ready;
    logic                    sink_sop;
    logic                    sink_eop;
    logic signed [DATA_W-1:0] sink_real;
    logic signed [DATA_W-1:0] sink_imag;

    // ============================================================
    // FFT output signals
    // ============================================================

    logic                    source_valid;
    logic                    source_ready;
    logic                    source_sop;
    logic                    source_eop;
    logic signed [DATA_W-1:0] source_real;
    logic signed [DATA_W-1:0] source_imag;

    assign source_ready = 1'b1;

    // ============================================================
    // Input counter: count 0 ~ 4095
    // ============================================================

    logic [LOG_N-1:0] in_cnt;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            in_cnt     <= '0;
            sink_valid <= 1'b0;
            sink_sop   <= 1'b0;
            sink_eop   <= 1'b0;
            sink_real  <= '0;
            sink_imag  <= '0;
        end else begin
            sink_valid <= 1'b0;
            sink_sop   <= 1'b0;
            sink_eop   <= 1'b0;

            if (i_sample_valid && sink_ready) begin
                sink_valid <= 1'b1;
                sink_real  <= i_sample;
                sink_imag  <= '0;

                sink_sop <= (in_cnt == 0);
                sink_eop <= (in_cnt == N-1);

                if (in_cnt == N-1) begin
                    in_cnt <= '0;
                end else begin
                    in_cnt <= in_cnt + 1'b1;
                end
            end
        end
    end

    // ============================================================
    // Instantiate FFT IP
    // ============================================================
    //
    // 這裡 port name 要依照你的 FFT_4096.v 修改。
    // 如果 compile error，通常就是 port 名稱不一樣。

    FFT_4096 u_fft (
        .clk          (i_clk),
        .reset_n      (~i_rst),

        .sink_valid   (sink_valid),
        .sink_ready   (sink_ready),
        .sink_sop     (sink_sop),
        .sink_eop     (sink_eop),
        .sink_real    (sink_real),
        .sink_imag    (sink_imag),

        .source_valid (source_valid),
        .source_ready (source_ready),
        .source_sop   (source_sop),
        .source_eop   (source_eop),
        .source_real  (source_real),
        .source_imag  (source_imag)
    );

    // ============================================================
    // Output bin counter
    // ============================================================

    logic [LOG_N-1:0] out_bin;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            out_bin <= '0;
        end else begin
            if (source_valid && source_ready) begin
                if (source_sop) begin
                    out_bin <= '0;
                end else begin
                    out_bin <= out_bin + 1'b1;
                end
            end
        end
    end

    // ============================================================
    // Magnitude squared = real^2 + imag^2
    // ============================================================

    logic signed [2*DATA_W-1:0] real_sq;
    logic signed [2*DATA_W-1:0] imag_sq;

    always_comb begin
        real_sq = source_real * source_real;
        imag_sq = source_imag * source_imag;
    end

    // ============================================================
    // Output registers
    // ============================================================

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_fft_out_valid <= 1'b0;
            o_bin           <= '0;
            o_fft_real      <= '0;
            o_fft_imag      <= '0;
            o_mag_sq        <= '0;
            o_frame_done    <= 1'b0;
        end else begin
            o_fft_out_valid <= 1'b0;
            o_frame_done    <= 1'b0;

            if (source_valid && source_ready) begin
                o_fft_out_valid <= 1'b1;
                o_bin           <= out_bin;
                o_fft_real      <= source_real;
                o_fft_imag      <= source_imag;
                o_mag_sq        <= real_sq + imag_sq;

                if (source_eop) begin
                    o_frame_done <= 1'b1;
                end
            end
        end
    end

endmodule