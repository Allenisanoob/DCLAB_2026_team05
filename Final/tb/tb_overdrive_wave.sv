`timescale 1ns/1ps

// ============================================================
// Testbench for overdrive.sv
// Purpose:
//   1. Generate VCD waveform: overdrive_tb.vcd
//   2. Sweep gain and input waveform to inspect pop/click/noise
//   3. Log key internal signals to overdrive_tb_log.csv
//
// Compile example with VCS:
//   vcs -full64 -sverilog -debug_access+all \
//       tb_overdrive_wave.sv overdrive.sv tanh.sv inv_tanh.sv \
//       -o simv
//   ./simv
//
// If your source file is named "overdrive(3).sv", either rename it to
// overdrive.sv or compile with escaped path:
//   vcs -full64 -sverilog -debug_access+all \
//       tb_overdrive_wave.sv "overdrive(3).sv" tanh.sv inv_tanh.sv \
//       -o simv
// ============================================================

module tb_overdrive_wave;

    localparam real CLK_PERIOD_NS = 20.0;   // 50 MHz simulation clock
    localparam int  Q15_MAX       = 32767;
    localparam int  Q15_MIN       = -32768;

    logic                      i_clk;
    logic                      i_rst;      // active-low reset in your overdrive.sv
    logic signed [15:0]        i_data;
    logic        [7:0]         i_gain;     // Q2.6 unsigned
    logic                      i_en;
    logic signed [15:0]        o_data;
    logic                      o_en;

    integer fd;
    integer sample_idx;
    string  section_name;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    overdrive dut (
        .i_clk  (i_clk),
        .i_rst  (i_rst),
        .i_data (i_data),
        .i_gain (i_gain),
        .i_en   (i_en),
        .o_data (o_data),
        .o_en   (o_en)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------
    initial begin
        i_clk = 1'b0;
        forever #(CLK_PERIOD_NS/2.0) i_clk = ~i_clk;
    end

    // ------------------------------------------------------------
    // Convert real value [-1.0, +1.0) to signed Q1.15
    // ------------------------------------------------------------
    function automatic signed [15:0] q15_from_real(input real x);
        int tmp;
        begin
            if (x >= 0.999969482421875) begin
                tmp = Q15_MAX;
            end else if (x <= -1.0) begin
                tmp = Q15_MIN;
            end else begin
                tmp = $rtoi(x * 32768.0);
                if (tmp > Q15_MAX) tmp = Q15_MAX;
                if (tmp < Q15_MIN) tmp = Q15_MIN;
            end
            q15_from_real = tmp[15:0];
        end
    endfunction

    function automatic real real_from_q15(input signed [15:0] x);
        begin
            real_from_q15 = x / 32768.0;
        end
    endfunction

    // Q2.6 gain helper: real gain g -> round(g * 64)
    function automatic [7:0] gain_q26(input real g);
        int tmp;
        begin
            tmp = $rtoi(g * 64.0 + 0.5);
            if (tmp < 0)   tmp = 0;
            if (tmp > 255) tmp = 255;
            gain_q26 = tmp[7:0];
        end
    endfunction

    // ------------------------------------------------------------
    // Log once per clock after output is registered
    // Note: hierarchical signals help debug normalization / saturation.
    // ------------------------------------------------------------
    task automatic log_sample;
        begin
            $fwrite(fd,
                "%0t,%s,%0d,%0d,%0f,%0d,%0f,%0d,%0f,%0d,%0d,%0d,%0d,%0d\n",
                $time,
                section_name,
                sample_idx,
                i_gain,
                i_gain / 64.0,
                i_data,
                real_from_q15(i_data),
                o_data,
                real_from_q15(o_data),
                o_en,
                dut.tanh_unnorm,
                dut.inv_tanh_val,
                dut.y_norm_full,
                dut.overdrive_out
            );
        end
    endtask

    task automatic drive_one_sample(input signed [15:0] x, input [7:0] gain);
        begin
            @(negedge i_clk);
            i_data <= x;
            i_gain <= gain;
            i_en   <= 1'b1;

            @(posedge i_clk);
            #1;
            log_sample();
            sample_idx++;
        end
    endtask

    task automatic idle_cycles(input int n);
        int k;
        begin
            @(negedge i_clk);
            i_en   <= 1'b0;
            i_data <= 16'sd0;
            for (k = 0; k < n; k++) begin
                @(posedge i_clk);
                #1;
                log_sample();
                sample_idx++;
            end
        end
    endtask

    // ------------------------------------------------------------
    // Stimulus sections
    // ------------------------------------------------------------

    task automatic run_silence(input [7:0] gain, input int n);
        int k;
        begin
            section_name = "silence";
            for (k = 0; k < n; k++) begin
                drive_one_sample(16'sd0, gain);
            end
        end
    endtask

    task automatic run_step_test(input [7:0] gain);
        begin
            section_name = "step_pos";
            repeat (20) drive_one_sample(16'sd0, gain);
            repeat (20) drive_one_sample(16'sd12000, gain);
            repeat (20) drive_one_sample(16'sd0, gain);

            section_name = "step_neg";
            repeat (20) drive_one_sample(16'sd0, gain);
            repeat (20) drive_one_sample(-16'sd12000, gain);
            repeat (20) drive_one_sample(16'sd0, gain);
        end
    endtask

    task automatic run_impulse_test(input [7:0] gain);
        begin
            section_name = "impulse";
            repeat (10) drive_one_sample(16'sd0, gain);
            drive_one_sample(16'sd32767, gain);
            repeat (10) drive_one_sample(16'sd0, gain);
            drive_one_sample(-16'sd32768, gain);
            repeat (10) drive_one_sample(16'sd0, gain);
        end
    endtask

    task automatic run_sine(input string name, input [7:0] gain, input real amp, input int n, input real cycles);
        int k;
        real theta;
        real x_real;
        begin
            section_name = name;
            for (k = 0; k < n; k++) begin
                theta  = 6.283185307179586 * cycles * k / n;
                x_real = amp * $sin(theta);
                drive_one_sample(q15_from_real(x_real), gain);
            end
        end
    endtask

    task automatic run_ramp(input [7:0] gain, input int n);
        int k;
        real x_real;
        begin
            section_name = "ramp_fullscale";
            for (k = 0; k < n; k++) begin
                x_real = -1.0 + 2.0 * k / (n - 1);
                drive_one_sample(q15_from_real(x_real), gain);
            end
        end
    endtask

    task automatic run_gain_sweep_sine(input real amp, input int n_per_gain);
        real gains [0:6];
        int gi, k;
        real theta;
        real x_real;
        begin
            gains[0] = 0.0625;  // i_gain = 4, bypass boundary
            gains[1] = 0.078125; // i_gain = 5, first non-bypass case
            gains[2] = 0.25;
            gains[3] = 0.5;
            gains[4] = 1.0;
            gains[5] = 2.0;
            gains[6] = 3.984375; // i_gain = 255, max Q2.6

            for (gi = 0; gi < 7; gi++) begin
                section_name = $sformatf("gain_sweep_sine_g_%0d", gain_q26(gains[gi]));
                for (k = 0; k < n_per_gain; k++) begin
                    theta  = 6.283185307179586 * 4.0 * k / n_per_gain;
                    x_real = amp * $sin(theta);
                    drive_one_sample(q15_from_real(x_real), gain_q26(gains[gi]));
                end
                idle_cycles(3);
            end
        end
    endtask

    task automatic run_gain_boundary_test;
        begin
            // Critical for your design:
            // i_gain <= 4 is bypass, i_gain = 5 enters tanh/inv_tanh path.
            section_name = "gain_boundary_4_to_5";
            repeat (20) drive_one_sample(16'sd12000, 8'd4);
            repeat (20) drive_one_sample(16'sd12000, 8'd5);
            repeat (20) drive_one_sample(16'sd12000, 8'd4);
            repeat (20) drive_one_sample(-16'sd12000, 8'd4);
            repeat (20) drive_one_sample(-16'sd12000, 8'd5);
            repeat (20) drive_one_sample(-16'sd12000, 8'd4);
        end
    endtask

    // ------------------------------------------------------------
    // Main
    // ------------------------------------------------------------
    initial begin
        $dumpfile("overdrive_tb.vcd");
        $dumpvars(0, tb_overdrive_wave);

        fd = $fopen("overdrive_tb_log.csv", "w");
        if (fd == 0) begin
            $display("ERROR: cannot open overdrive_tb_log.csv");
            $finish;
        end

        $fwrite(fd,
            "time,section,sample_idx,i_gain,gain_real,i_data,i_data_real,o_data,o_data_real,o_en,tanh_unnorm,inv_tanh_val,y_norm_full,overdrive_out\n"
        );

        sample_idx   = 0;
        section_name = "init";

        i_rst  = 1'b0;
        i_data = 16'sd0;
        i_gain = 8'd64;   // gain = 1.0
        i_en   = 1'b0;

        repeat (5) @(posedge i_clk);
        i_rst = 1'b1;
        repeat (3) @(posedge i_clk);

        // 1. Silence should not create output noise.
        run_silence(gain_q26(1.0), 50);
        run_silence(gain_q26(4.0), 50);

        // 2. Smooth sine wave at different amplitudes.
        run_sine("sine_amp_0p1_gain_1", gain_q26(1.0), 0.10, 256, 4.0);
        run_sine("sine_amp_0p5_gain_1", gain_q26(1.0), 0.50, 256, 4.0);
        run_sine("sine_amp_0p9_gain_1", gain_q26(1.0), 0.90, 256, 4.0);

        // 3. High gain sine; useful for clipping / saturation behavior.
        run_sine("sine_amp_0p5_gain_4", gain_q26(3.984375), 0.50, 256, 4.0);
        run_sine("sine_amp_0p9_gain_4", gain_q26(3.984375), 0.90, 256, 4.0);

        // 4. Gain boundary between bypass and nonlinear path.
        run_gain_boundary_test();

        // 5. Step and impulse tests are good for pop/click diagnosis.
        run_step_test(gain_q26(1.0));
        run_step_test(gain_q26(3.984375));
        run_impulse_test(gain_q26(3.984375));

        // 6. Full-scale DC transfer curve.
        run_ramp(gain_q26(1.0), 512);
        run_ramp(gain_q26(3.984375), 512);

        // 7. Gain sweep with same sine input.
        run_gain_sweep_sine(0.60, 128);

        idle_cycles(10);

        $fclose(fd);
        $display("DONE.");
        $display("Generated waveform: overdrive_tb.vcd");
        $display("Generated CSV log : overdrive_tb_log.csv");
        $finish;
    end

endmodule
