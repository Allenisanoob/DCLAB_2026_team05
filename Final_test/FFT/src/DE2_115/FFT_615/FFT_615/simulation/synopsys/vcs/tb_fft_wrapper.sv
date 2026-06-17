`timescale 1ns/1ps

module tb_fft_wrapper;

    localparam int FFT_N    = 4096;
    localparam int CNT_W    = 12;
    localparam int FS_HZ    = 48000;
    localparam int TEST_BIN = 85;  // 85 * 48000 / 4096 = 996.09 Hz
    localparam real PI      = 3.14159265358979323846;

    logic clk;
    logic rst_n;

    logic signed [15:0] audio_sample;
    logic audio_valid;

    // FFT sink/input side debug
    logic sink_valid;
    logic sink_ready;
    logic sink_sop;
    logic sink_eop;
    logic signed [15:0] sink_real;
    logic signed [15:0] sink_imag;
    logic [CNT_W-1:0] in_cnt;
    logic input_drop;

    // FFT source/output side debug
    logic bin_valid;
    logic bin_sop;
    logic bin_eop;
    logic [CNT_W-1:0] bin_idx;
    logic signed [15:0] fft_real;
    logic signed [15:0] fft_imag;
    logic [5:0] fft_exp;
    logic [1:0] source_error;

    // Constants inside wrapper/IP connection
    // In FFT_wrapper.sv:
    //   sink_error   = 2'b00
    //   inverse      = 1'b0
    //   source_ready = 1'b1
    localparam logic [1:0] SINK_ERROR_CONST = 2'b00;
    localparam logic       INVERSE_CONST    = 1'b0;
    localparam logic       SOURCE_READY_CONST = 1'b1;

    FFT_audio_wrapper #(
        .FFT_N(FFT_N),
        .CNT_W(CNT_W)
    ) dut (
        .i_clk(clk),
        .i_rst_n(rst_n),

        .i_audio_sample(audio_sample),
        .i_audio_valid(audio_valid),

        .o_sink_valid(sink_valid),
        .o_sink_ready(sink_ready),
        .o_sink_sop(sink_sop),
        .o_sink_eop(sink_eop),
        .o_sink_real(sink_real),
        .o_sink_imag(sink_imag),
        .o_in_cnt(in_cnt),
        .o_input_drop(input_drop),

        .o_bin_valid(bin_valid),
        .o_bin_sop(bin_sop),
        .o_bin_eop(bin_eop),
        .o_bin_idx(bin_idx),
        .o_fft_real(fft_real),
        .o_fft_imag(fft_imag),
        .o_fft_exp(fft_exp),
        .o_source_error(source_error)
    );

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

`ifdef FSDB
    initial begin
        $fsdbDumpfile("fft_wrapper.fsdb");
        $fsdbDumpvars(0, tb_fft_wrapper);
    end
`endif

    function automatic int abs_int(input int signed x);
        if (x < 0)
            abs_int = -x;
        else
            abs_int = x;
    endfunction

    // ------------------------------------------------------------
    // CSV log files
    // ------------------------------------------------------------
    integer f_all;
    integer f_in;
    integer f_out;

    int cycle_cnt;
    int input_accept_cnt;
    int output_bin_cnt;

    int signed r_i;
    int signed im_i;
    int unsigned mag_approx;

    int unsigned top_mag [0:3];
    int          top_bin [0:3];

    task automatic clear_top4;
        int i;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                top_mag[i] = 0;
                top_bin[i] = -1;
            end
        end
    endtask

    task automatic consider_bin(input int bin, input int unsigned mag);
        int i, j;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                if ((top_bin[i] == -1) || (mag > top_mag[i])) begin
                    for (j = 3; j > i; j = j - 1) begin
                        top_mag[j] = top_mag[j-1];
                        top_bin[j] = top_bin[j-1];
                    end
                    top_mag[i] = mag;
                    top_bin[i] = bin;
                    i = 4; // break
                end
            end
        end
    endtask

    task automatic print_top4;
        real freq;
        int i;
        begin
            $display("");
            $display("========== FFT Top 4 Result ==========");
            for (i = 0; i < 4; i = i + 1) begin
                freq = top_bin[i] * FS_HZ * 1.0 / FFT_N;
                $display("TOP%0d: bin=%0d, freq=%0.2f Hz, mag_approx=%0d",
                         i+1, top_bin[i], freq, top_mag[i]);
            end
            $display("Expected main bin = %0d, freq = %0.2f Hz",
                     TEST_BIN, TEST_BIN * FS_HZ * 1.0 / FFT_N);
            $display("======================================");
            $display("");
        end
    endtask

    initial begin
        f_all = $fopen("fft_all_cycles.csv", "w");
        f_in  = $fopen("fft_input_accept.csv", "w");
        f_out = $fopen("fft_output_bins.csv", "w");

        if (f_all == 0) begin
            $display("ERROR: cannot open fft_all_cycles.csv");
            $finish;
        end

        if (f_in == 0) begin
            $display("ERROR: cannot open fft_input_accept.csv");
            $finish;
        end

        if (f_out == 0) begin
            $display("ERROR: cannot open fft_output_bins.csv");
            $finish;
        end

        // Every clock after reset is released.
        $fdisplay(f_all,
            "time_ps,cycle,rst_n,audio_valid,audio_sample,sink_valid,sink_ready,sink_fire,sink_sop,sink_eop,sink_real,sink_imag,sink_error,in_cnt,input_drop,source_valid,source_ready,source_fire,source_sop,source_eop,source_bin_idx,source_real,source_imag,source_exp,source_error,inverse");

        // Only accepted input samples: sink_valid && sink_ready.
        $fdisplay(f_in,
            "time_ps,accept_idx,audio_valid,audio_sample,sink_valid,sink_ready,sink_fire,sink_sop,sink_eop,sink_real,sink_imag,sink_error,in_cnt,input_drop,inverse");

        // Only valid output bins: source_valid.
        $fdisplay(f_out,
            "time_ps,out_idx,bin_idx,source_valid,source_ready,source_fire,source_sop,source_eop,source_real,source_imag,source_exp,source_error,mag_abs_real_plus_abs_imag");
    end

    task automatic send_sample(input logic signed [15:0] s);
        begin
            @(posedge clk);
            audio_sample <= s;
            audio_valid  <= 1'b1;

            @(posedge clk);
            audio_valid  <= 1'b0;

            // Keep the original slow injection.
            repeat (4) @(posedge clk);
        end
    endtask

    int n;
    real sample_real;
    int signed sample_int;

    initial begin
        rst_n = 1'b0;
        audio_sample = 16'sd0;
        audio_valid  = 1'b0;

        repeat (20) @(posedge clk);
        rst_n = 1'b1;
        repeat (20) @(posedge clk);

        $display("Start feeding sine wave.");
        $display("TEST_BIN = %0d", TEST_BIN);
        $display("TEST_FREQ = %0.2f Hz", TEST_BIN * FS_HZ * 1.0 / FFT_N);

        for (n = 0; n < FFT_N; n = n + 1) begin
            sample_real = 12000.0 * $sin(2.0 * PI * TEST_BIN * n / FFT_N);
            sample_int  = $rtoi(sample_real);
            send_sample(sample_int[15:0]);
        end

        $display("Finished feeding %0d samples. Waiting for FFT output...", FFT_N);

        // Wait enough cycles for FFT output.
        repeat (200000) @(posedge clk);

        $display("Timeout waiting complete.");
        $display("Total cycle count        = %0d", cycle_cnt);
        $display("Total input_accept count = %0d", input_accept_cnt);
        $display("Total output bin count   = %0d", output_bin_cnt);

        $fclose(f_all);
        $fclose(f_in);
        $fclose(f_out);

        $finish;
    end

    // Use normal always, not always_ff, to avoid strict VCS always_ff driver rules in TB.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt        <= 0;
            input_accept_cnt <= 0;
            output_bin_cnt   <= 0;
            clear_top4();
        end else begin
            cycle_cnt <= cycle_cnt + 1;

            // --------------------------------------------------------
            // Log every cycle: all sink/source visible parameters.
            // --------------------------------------------------------
            $fdisplay(f_all,
                "%0t,%0d,%0b,%0b,%0d,%0b,%0b,%0b,%0b,%0b,%0d,%0d,%0b,%0d,%0b,%0b,%0b,%0b,%0b,%0b,%0d,%0d,%0d,%0d,%0b,%0b",
                $time,
                cycle_cnt,
                rst_n,
                audio_valid,
                audio_sample,
                sink_valid,
                sink_ready,
                sink_valid && sink_ready,
                sink_sop,
                sink_eop,
                sink_real,
                sink_imag,
                SINK_ERROR_CONST,
                in_cnt,
                input_drop,
                bin_valid,
                SOURCE_READY_CONST,
                bin_valid && SOURCE_READY_CONST,
                bin_sop,
                bin_eop,
                bin_idx,
                fft_real,
                fft_imag,
                fft_exp,
                source_error,
                INVERSE_CONST
            );

            // --------------------------------------------------------
            // Log every accepted input sample.
            // This is the true FFT input transfer:
            // sink_valid && sink_ready.
            // --------------------------------------------------------
            if (sink_valid && sink_ready) begin
                $fdisplay(f_in,
                    "%0t,%0d,%0b,%0d,%0b,%0b,%0b,%0b,%0b,%0d,%0d,%0b,%0d,%0b,%0b",
                    $time,
                    input_accept_cnt,
                    audio_valid,
                    audio_sample,
                    sink_valid,
                    sink_ready,
                    sink_valid && sink_ready,
                    sink_sop,
                    sink_eop,
                    sink_real,
                    sink_imag,
                    SINK_ERROR_CONST,
                    in_cnt,
                    input_drop,
                    INVERSE_CONST
                );

                input_accept_cnt <= input_accept_cnt + 1;
            end

            // --------------------------------------------------------
            // Log every valid FFT output bin.
            // source_valid is exported as bin_valid from wrapper.
            // --------------------------------------------------------
            if (bin_valid) begin
                r_i = fft_real;
                im_i = fft_imag;
                mag_approx = abs_int(r_i) + abs_int(im_i);

                $fdisplay(f_out,
                    "%0t,%0d,%0d,%0b,%0b,%0b,%0b,%0b,%0d,%0d,%0d,%0b,%0d",
                    $time,
                    output_bin_cnt,
                    bin_idx,
                    bin_valid,
                    SOURCE_READY_CONST,
                    bin_valid && SOURCE_READY_CONST,
                    bin_sop,
                    bin_eop,
                    fft_real,
                    fft_imag,
                    fft_exp,
                    source_error,
                    mag_approx
                );

                output_bin_cnt <= output_bin_cnt + 1;

                if (bin_sop) begin
                    clear_top4();
                    $display("FFT output frame started.");
                end

                if ((bin_idx > 0) && (bin_idx < FFT_N/2)) begin
                    consider_bin(bin_idx, mag_approx);
                end

                if (bin_eop) begin
                    $display("Total cycle count        = %0d", cycle_cnt);
                    $display("Total input_accept count = %0d", input_accept_cnt);
                    $display("Total output bin count   = %0d", output_bin_cnt + 1);

                    $fclose(f_all);
                    $fclose(f_in);
                    $fclose(f_out);

                    print_top4();
                    $finish;
                end
            end
        end
    end

endmodule