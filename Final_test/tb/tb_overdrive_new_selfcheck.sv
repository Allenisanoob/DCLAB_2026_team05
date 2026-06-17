`timescale 1ns/1ps

module tb_overdrive_selfcheck;

    // ============================================================
    // Self-checking TB for Overdrive.sv (Gain-Separation LPF Ready)
    //
    // Golden model logic:
    //   x = data * gain
    //   v = x / L
    //   g = (abs(v) <= threshold) ? 1.0 : tanh(v) / v
    //   y = x * g
    //
    // Fixed-point formats:
    //   i_data/o_data : signed Q1.15
    //   i_gain        : unsigned Q2.6
    //   i_L           : signed Q1.15 (Expected to be > 0)
    // ============================================================

    localparam int CLK_PERIOD_NS = 10;
    localparam int MAX_ERR_LSB   = 64;     // tolerance for tanh LUT and integer division/truncation
    localparam int RANDOM_TESTS  = 5000;

    logic                      i_clk;
    logic                      i_rst;      // Active-low reset
    logic signed [15:0]        i_data;
    logic        [7:0]         i_gain;
    logic signed [15:0]        i_L;
    logic                      i_en;
    logic signed [15:0]        o_data;
    logic                      o_en;

    int total_tests;
    int fail_count;
    int max_abs_err;
    int fd;

    // Expected-output and input tracking queues for dynamic latency handling
    logic signed [15:0] exp_q[$];
    logic signed [15:0] in_data_q[$];
    logic        [7:0]  in_gain_q[$];
    logic signed [15:0] in_L_q[$];
    string              tag_q[$];

    Overdrive dut (
        .i_clk  (i_clk),
        .i_rst  (i_rst),
        .i_data (i_data),
        .i_gain (i_gain),
        .i_L    (i_L),
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
            if (x >= (32767.0 / 32768.0)) begin
                real_to_q15 = 16'sd32767;
            end else if (x <= -1.0) begin
                real_to_q15 = -16'sd32768;
            end else begin
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
        input logic [7:0] gain_q26,
        input logic signed [15:0] L_q15
    );
        int x_full, x_q15, v_int;
        real x_real, L_real, v_real, g_real, y_real, tanh_val;
        begin
            // 1. Simulate hardware x calculation
            x_full = int'(data_q15) * int'({1'b0, gain_q26});
            x_q15 = x_full >> 6; // Q17.15 representation
            x_real = real'(x_q15) / 32768.0;

            L_real = q15_to_real(L_q15);

            // 2. Simulate v = x / L
            if (L_q15 <= 16'sd0) begin
                v_real = 0.0;
                v_int = 0;
            end else begin
                v_real = x_real / L_real;
                v_int = int'(v_real * 32768.0);
            end

            // 3. Simulate g = tanh(v)/v with zero-protection threshold ([-5, 5] in Q1.15)
            if (v_int >= -5 && v_int <= 5) begin
                g_real = 32767.0 / 32768.0; // Max Q1.15 limit
            end else begin
                tanh_val = tanh_real(v_real);
                g_real = tanh_val / v_real;
                if (g_real > (32767.0/32768.0)) g_real = 32767.0/32768.0;
                if (g_real < -1.0) g_real = -1.0;
            end

            // 4. Output y = x * g
            y_real = x_real * g_real;
            golden_overdrive = real_to_q15(y_real);
        end
    endfunction

    // ---------------- Autonomous Checker Thread ----------------
    // Checks outputs dynamically whenever o_en is high, agnostic to pipeline depth
    always @(posedge i_clk) begin
        if (i_rst !== 1'b0) begin
            #1; // Sample after hold time
            if (o_en === 1'b1) begin
                if (exp_q.size() > 0) begin
                    logic signed [15:0] exp = exp_q.pop_front();
                    logic signed [15:0] d   = in_data_q.pop_front();
                    logic [7:0]         g   = in_gain_q.pop_front();
                    logic signed [15:0] L   = in_L_q.pop_front();
                    string              tag = tag_q.pop_front();
                    int err = abs_int(int'(o_data) - int'(exp));

                    if (err > max_abs_err) max_abs_err = err;

                    total_tests++;
                    $fwrite(fd, "%0t,%s,%0d,%0d,%0d,%0d,%0d,%0d\n",
                            $time, tag, int'(o_data), int'(exp), err, int'(d), int'(g), int'(L));

                    if (err > MAX_ERR_LSB) begin
                        fail_count++;
                        $display("FAIL %-18s got=%0d expected=%0d err=%0d LSB  [data=%0d gain=%0d L=%0d]",
                                 tag, int'(o_data), int'(exp), err, int'(d), int'(g), int'(L));
                    end
                end else begin
                    $display("FAIL at time %0t: DUT asserted o_en, but no matching input was provided!", $time);
                    fail_count++;
                end
            end
        end
    end

    // ---------------- Drivers ----------------
    task automatic drive_one(
        input logic signed [15:0] data,
        input logic [7:0] gain,
        input logic signed [15:0] L,
        input string tag,
        input bit check_this_sample
    );
        logic signed [15:0] exp;
        begin
            @(negedge i_clk);
            i_data <= data;
            i_gain <= gain;
            i_L    <= L;
            i_en   <= 1'b1;

            if (check_this_sample) begin
                exp = golden_overdrive(data, gain, L);
                exp_q.push_back(exp);
                in_data_q.push_back(data);
                in_gain_q.push_back(gain);
                in_L_q.push_back(L);
                tag_q.push_back(tag);
            end
        end
    endtask

    task automatic idle_one;
        begin
            @(negedge i_clk);
            i_en   <= 1'b0;
            i_data <= 16'sd0;
            i_gain <= 8'd0;
            i_L    <= 16'sd0;
        end
    endtask

    task automatic flush_pipeline;
        begin
            // Feed idle cycles to flush the pipeline. 
            // 4 cycles minimum for a 4-stage pipeline.
            repeat (6) idle_one();
        end
    endtask

    // ---------------- Test groups ----------------
    task automatic directed_tests;
        int gains[0:8] = '{0, 1, 4, 5, 8, 16, 64, 128, 255};
        int L_vals[0:2] = '{16'sd32767, 16'sd16384, 16'sd8192}; // 1.0, 0.5, 0.25
        logic signed [15:0] samples[0:10];
        begin
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

            for (int li = 0; li < 3; li++) begin
                for (int gi = 0; gi < 9; gi++) begin
                    for (int si = 0; si < 11; si++) begin
                        drive_one(samples[si], gains[gi][7:0], L_vals[li][15:0], "directed", 1'b1);
                    end
                end
            end
        end
    endtask

    task automatic sine_like_tests(input logic [7:0] gain, input logic signed [15:0] L, input string tag);
        int val;
        begin
            int table[0:31] = '{
                 0,  6393, 12540, 18204, 23170, 27245, 30274, 32138,
             32767, 32138, 30274, 27245, 23170, 18204, 12540,  6393,
                 0, -6393,-12540,-18204,-23170,-27245,-30274,-32138,
            -32768,-32138,-30274,-27245,-23170,-18204,-12540, -6393
            };
            for (int k = 0; k < 128; k++) begin
                val = table[k % 32];
                drive_one($signed(val[15:0]), gain, L, tag, 1'b1);
            end
        end
    endtask

    task automatic random_tests;
        logic signed [15:0] rand_data;
        logic [7:0]         rand_gain;
        logic signed [15:0] rand_L;
        int unsigned raw_data, raw_L;
        begin
            for (int k = 0; k < RANDOM_TESTS; k++) begin
                raw_data  = $urandom();
                rand_data = raw_data[15:0];
                rand_gain = $urandom_range(0, 255);
                
                // Keep L positive for valid tests (0.01 to 1.0)
                raw_L = $urandom_range(327, 32767); 
                rand_L = raw_L[15:0];

                drive_one(rand_data, rand_gain, rand_L, "random", 1'b1);
            end
        end
    endtask

    task automatic gain_sweep_tests;
        logic signed [15:0] fixed_data;
        logic signed [15:0] fixed_L;
        begin
            fixed_data = 16'sd12000;
            fixed_L    = 16'sd26214; // L = 0.8
            for (int g = 0; g <= 255; g++) begin
                drive_one(fixed_data, g[7:0], fixed_L, "gain_sweep", 1'b1);
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
        $fwrite(fd, "time,tag,got_q15,expected_q15,err_lsb,i_data,i_gain,i_L\n");

        i_data = 16'sd0;
        i_gain = 8'd0;
        i_L    = 16'sd32767;
        i_en   = 1'b0;
        i_rst  = 1'b0;

        repeat (5) @(posedge i_clk);
        @(negedge i_clk);
        i_rst <= 1'b1;
        repeat (2) @(posedge i_clk);

        $display("[TB] Start directed tests...");
        directed_tests();

        $display("[TB] Start sine-like tests...");
        sine_like_tests(8'd5,   16'sd32767, "sine_g5_L1.0");
        sine_like_tests(8'd64,  16'sd16384, "sine_g64_L0.5");
        sine_like_tests(8'd128, 16'sd8192,  "sine_g128_L0.25");
        sine_like_tests(8'd255, 16'sd32767, "sine_g255_L1.0");

        $display("[TB] Start random tests...");
        random_tests();

        $display("[TB] Start gain sweep tests...");
        gain_sweep_tests();

        flush_pipeline();

        $display("------------------------------------------------------------");
        $display("TOTAL TESTS = %0d", total_tests);
        $display("FAIL COUNT  = %0d", fail_count);
        $display("MAX ERR LSB = %0d", max_abs_err);
        if (fail_count == 0) begin
            $display("FINAL RESULT: PASS");
        end else begin
            $display("FINAL RESULT: FAIL");
        end
        $display("CSV log: tb_overdrive_selfcheck_log.csv");
        $display("------------------------------------------------------------");

        $fclose(fd);
        $finish;
    end

endmodule