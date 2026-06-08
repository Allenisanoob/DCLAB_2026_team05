`timescale 1ns/1ps

module tb_overdrive_selfcheck;

    // ============================================================
    // Self-checking TB for Overdrive.sv
    // Golden model:
    //   if gain <= 4: bypass, y = x
    //   else        : y = tanh(gain*x) / tanh(gain)
    // Fixed-point formats:
    //   i_data/o_data : signed Q1.15
    //   i_gain        : unsigned Q2.6
    //
    // Important:
    //   This TB checks the INTENDED behavior with 1-cycle latency:
    //      output sample[k] should match input sample[k-1], gain[k-1]
    //   If gain changes every sample and the DUT does not register i_gain,
    //   this TB will catch the data/gain misalignment.
    // ============================================================

    localparam int CLK_PERIOD_NS = 10;
    localparam int MAX_ERR_LSB   = 16;     // tolerance for LUT/interpolation error
    localparam int RANDOM_TESTS  = 5000;

    logic                      i_clk;
    logic                      i_rst;      // DUT reset is active-low in actual code
    logic signed [15:0]        i_data;
    logic        [7:0]         i_gain;
    logic                      i_en;
    logic signed [15:0]        o_data;
    logic                      o_en;

    int total_tests;
    int fail_count;
    int max_abs_err;
    int fd;

    // Expected-output queue for 1-cycle latency
    logic signed [15:0] exp_q[$];
    string             tag_q[$];

    Overdrive dut (
        .i_clk  (i_clk),
        .i_rst  (i_rst),
        .i_data (i_data),
        .i_gain (i_gain),
        .i_en   (i_en),
        .o_data (o_data),
        .o_en   (o_en)
    );

    // ---------------- Clock ----------------
    initial begin
        i_clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) i_clk = ~i_clk;
    end

    // ---------------- Wave dump ----------------
    initial begin
`ifdef FSDB
        $fsdbDumpfile("tb_overdrive_selfcheck.fsdb");
        $fsdbDumpvars(0, tb_overdrive_selfcheck);
`else
        $dumpfile("tb_overdrive_selfcheck.vcd");
        $dumpvars(0, tb_overdrive_selfcheck);
`endif
    end

    // ---------------- Utility functions ----------------
    function automatic real abs_real(input real x);
        if (x < 0.0) abs_real = -x;
        else         abs_real =  x;
    endfunction

    function automatic int abs_int(input int x);
        if (x < 0) abs_int = -x;
        else       abs_int =  x;
    endfunction

    function automatic real tanh_real(input real x);
        real e2x;
        begin
            if (x > 20.0) begin
                tanh_real = 1.0;
            end else if (x < -20.0) begin
                tanh_real = -1.0;
            end else begin
                e2x = $exp(2.0 * x);
                tanh_real = (e2x - 1.0) / (e2x + 1.0);
            end
        end
    endfunction

    function automatic real q15_to_real(input logic signed [15:0] x);
        q15_to_real = $itor(x) / 32768.0;
    endfunction

    function automatic logic signed [15:0] real_to_q15(input real x);
        int q;
        begin
            // saturate to signed Q1.15 range
            if (x >= (32767.0 / 32768.0)) begin
                real_to_q15 = 16'sd32767;
            end else if (x <= -1.0) begin
                real_to_q15 = -16'sd32768;
            end else begin
                // round to nearest, away from zero
                if (x >= 0.0) q = int'(x * 32768.0 + 0.5);
                else          q = int'(x * 32768.0 - 0.5);

                if (q > 32767)       q = 32767;
                else if (q < -32768) q = -32768;

                real_to_q15 = q[15:0];
            end
        end
    endfunction

    function automatic logic signed [15:0] golden_overdrive(
        input logic signed [15:0] data_q15,
        input logic [7:0] gain_q26
    );
        real x;
        real g;
        real y;
        real denom;
        begin
            if (gain_q26 <= 8'd4) begin
                golden_overdrive = data_q15;
            end else begin
                x = q15_to_real(data_q15);
                g = $itor(gain_q26) / 64.0;
                denom = tanh_real(g);
                y = tanh_real(g * x) / denom;
                golden_overdrive = real_to_q15(y);
            end
        end
    endfunction

    // ---------------- Checker ----------------
    task automatic check_output_if_ready;
        logic signed [15:0] exp;
        string tag;
        int err;
        begin
            if (exp_q.size() > 0) begin
                exp = exp_q.pop_front();
                tag = tag_q.pop_front();

                if (o_en !== 1'b1) begin
                    $display("FAIL %-18s o_en is not 1 when an output is expected. o_en=%b", tag, o_en);
                    fail_count++;
                end

                err = abs_int(int'(o_data) - int'(exp));
                if (err > max_abs_err) max_abs_err = err;

                total_tests++;
                $fwrite(fd, "%0t,%s,%0d,%0d,%0d,%0d,%0d\n",
                        $time, tag, int'(o_data), int'(exp), err, int'(i_data), int'(i_gain));

                if (err > MAX_ERR_LSB) begin
                    fail_count++;
                    $display("FAIL %-18s got=%0d expected=%0d err=%0d LSB  current_i_data=%0d current_i_gain=%0d",
                             tag, int'(o_data), int'(exp), err, int'(i_data), int'(i_gain));
                end
            end
        end
    endtask

    task automatic drive_one(
        input logic signed [15:0] data,
        input logic [7:0] gain,
        input string tag,
        input bit check_this_sample
    );
        logic signed [15:0] exp;
        begin
            // Drive before the active edge.
            @(negedge i_clk);
            i_data <= data;
            i_gain <= gain;
            i_en   <= 1'b1;

            // The expected result for this input should appear one cycle later.
            if (check_this_sample) begin
                exp = golden_overdrive(data, gain);
                exp_q.push_back(exp);
                tag_q.push_back(tag);
            end

            @(posedge i_clk);
            #1;
            check_output_if_ready();
        end
    endtask

    task automatic idle_one;
        begin
            @(negedge i_clk);
            i_en   <= 1'b0;
            i_data <= 16'sd0;
            i_gain <= 8'd0;
            @(posedge i_clk);
            #1;
            // Do not check during idle.
        end
    endtask

    task automatic flush_pipeline;
        begin
            // Push one dummy valid cycle so the last queued expected value can come out.
            drive_one(16'sd0, 8'd4, "flush", 1'b0);
        end
    endtask

    // ---------------- Test groups ----------------
    task automatic directed_tests;
        int gains[0:8];
        logic signed [15:0] samples[0:10];
        begin
            gains[0] = 0;
            gains[1] = 1;
            gains[2] = 4;
            gains[3] = 5;
            gains[4] = 8;
            gains[5] = 16;
            gains[6] = 64;
            gains[7] = 128;
            gains[8] = 255;

            samples[0]  = 16'sd0;
            samples[1]  = 16'sd1;
            samples[2]  = -16'sd1;
            samples[3]  = 16'sd1024;
            samples[4]  = -16'sd1024;
            samples[5]  = 16'sd8192;
            samples[6]  = -16'sd8192;
            samples[7]  = 16'sd16384;
            samples[8]  = -16'sd16384;
            samples[9]  = 16'sd32767;
            samples[10] = -16'sd32768;

            for (int gi = 0; gi < 9; gi++) begin
                for (int si = 0; si < 11; si++) begin
                    drive_one(samples[si], gains[gi][7:0], "directed", 1'b1);
                end
            end
        end
    endtask

    task automatic sine_like_tests(input logic [7:0] gain, input string tag);
        int amp;
        int val;
        begin
            // A deterministic sine-like table without relying on $sin support.
            int table[0:31] = '{
                 0,  6393, 12540, 18204, 23170, 27245, 30274, 32138,
             32767, 32138, 30274, 27245, 23170, 18204, 12540,  6393,
                 0, -6393,-12540,-18204,-23170,-27245,-30274,-32138,
            -32768,-32138,-30274,-27245,-23170,-18204,-12540, -6393
            };
            for (int k = 0; k < 128; k++) begin
                val = table[k % 32];
                drive_one($signed(val[15:0]), gain, tag, 1'b1);
            end
        end
    endtask

    task automatic random_tests;
        logic signed [15:0] rand_data;
        logic [7:0] rand_gain;
        int unsigned raw;
        begin
            for (int k = 0; k < RANDOM_TESTS; k++) begin
                raw = $urandom();
                rand_data = raw[15:0];
                rand_gain = $urandom_range(0, 255);
                drive_one(rand_data, rand_gain, "random", 1'b1);
            end
        end
    endtask

    task automatic gain_sweep_tests;
        logic signed [15:0] fixed_data;
        begin
            // This intentionally changes gain every sample.
            // A correct 1-cycle-pipeline design should register gain with data.
            fixed_data = 16'sd12000;
            for (int g = 0; g <= 255; g++) begin
                drive_one(fixed_data, g[7:0], "gain_sweep", 1'b1);
            end
        end
    endtask

    // ---------------- Main ----------------
    initial begin
        total_tests = 0;
        fail_count  = 0;
        max_abs_err = 0;

        fd = $fopen("tb_overdrive_selfcheck_log.csv", "w");
        if (fd == 0) begin
            $display("ERROR: cannot open CSV log file.");
            $finish;
        end
        $fwrite(fd, "time,tag,got_q15,expected_q15,err_lsb,current_i_data,current_i_gain\n");

        i_data = 16'sd0;
        i_gain = 8'd0;
        i_en   = 1'b0;
        i_rst  = 1'b0;   // active-low reset

        repeat (5) @(posedge i_clk);
        @(negedge i_clk);
        i_rst <= 1'b1;
        repeat (2) @(posedge i_clk);

        // Primer cycle: current DUT does not reset i_data_r, so do not check the first valid output.
        drive_one(16'sd0, 8'd4, "primer", 1'b0);

        $display("[TB] Start directed tests...");
        directed_tests();

        $display("[TB] Start sine-like tests...");
        sine_like_tests(8'd5,   "sine_g5");
        sine_like_tests(8'd64,  "sine_g64");
        sine_like_tests(8'd128, "sine_g128");
        sine_like_tests(8'd255, "sine_g255");

        $display("[TB] Start random tests...");
        random_tests();

        $display("[TB] Start gain sweep tests...");
        gain_sweep_tests();

        flush_pipeline();
        idle_one();

        $display("------------------------------------------------------------");
        $display("TOTAL TESTS = %0d", total_tests);
        $display("FAIL COUNT  = %0d", fail_count);
        $display("MAX ERR LSB = %0d", max_abs_err);
        if (fail_count == 0) begin
            $display("FINAL RESULT: PASS");
        end else begin
            $display("FINAL RESULT: FAIL");
            $display("Hint: If failures concentrate in gain_sweep/random cases, check whether i_gain is registered with i_data_r.");
            $display("Hint: Also reset i_data_r, otherwise the first valid output after reset can be X/unknown.");
        end
        $display("CSV log: tb_overdrive_selfcheck_log.csv");
        $display("------------------------------------------------------------");

        $fclose(fd);
        $finish;
    end

endmodule
