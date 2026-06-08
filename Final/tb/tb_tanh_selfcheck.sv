`timescale 1ns/1ps

// Self-checking testbench for tanh.sv
// DUT behavior:
//   i_data : signed Q1.15
//   i_gain : unsigned Q2.6
//   o_data : signed Q1.15, approximately tanh(i_data * i_gain)
//
// This TB compares DUT output against a real-number golden model.
// Because the DUT uses a 128-entry LUT + linear interpolation, exact bit match
// to real tanh() is not expected. Use MAX_ERR_LSB as the tolerance.

module tb_tanh_selfcheck;

    localparam int MAX_ERR_LSB = 8;
    localparam int RANDOM_TESTS = 5000;

    logic signed [15:0] i_data;
    logic        [7:0]  i_gain;
    logic signed [15:0] o_data;

    int total_tests;
    int fail_count;
    int max_abs_err;

    tanh dut (
        .i_data(i_data),
        .i_gain(i_gain),
        .o_data(o_data)
    );

    function automatic real abs_real(input real x);
        begin
            abs_real = (x < 0.0) ? -x : x;
        end
    endfunction

    function automatic real tanh_real(input real x);
        real e2x;
        begin
            // Avoid overflow for very large magnitude, although this DUT only reaches about +/-4.
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

    function automatic int round_to_int(input real x);
        begin
            if (x >= 0.0)
                round_to_int = $rtoi(x + 0.5);
            else
                round_to_int = $rtoi(x - 0.5);
        end
    endfunction

    function automatic int sat_q15(input int x);
        begin
            if (x > 32767)
                sat_q15 = 32767;
            else if (x < -32768)
                sat_q15 = -32768;
            else
                sat_q15 = x;
        end
    endfunction

    function automatic int golden_tanh_q15(
        input logic signed [15:0] data_q15,
        input logic        [7:0]  gain_q26
    );
        real data_real;
        real gain_real;
        real x_real;
        real y_real;
        int  y_q15;
        begin
            data_real = $itor($signed(data_q15)) / 32768.0;
            gain_real = $itor(gain_q26) / 64.0;
            x_real = data_real * gain_real;

            // Match DUT saturation behavior for |x| >= 4.0.
            if (x_real >= 4.0)
                y_q15 = 32746;
            else if (x_real <= -4.0)
                y_q15 = -32746;
            else begin
                y_real = tanh_real(x_real);
                y_q15 = round_to_int(y_real * 32768.0);
            end

            golden_tanh_q15 = sat_q15(y_q15);
        end
    endfunction

    task automatic check_one(
        input logic signed [15:0] data_q15,
        input logic        [7:0]  gain_q26,
        input string              tag
    );
        int golden;
        int got;
        int err;
        real data_real;
        real gain_real;
        begin
            i_data = data_q15;
            i_gain = gain_q26;
            #1; // combinational settle

            golden = golden_tanh_q15(data_q15, gain_q26);
            got = $signed(o_data);
            err = got - golden;
            if (err < 0) err = -err;

            total_tests++;
            if (err > max_abs_err) max_abs_err = err;

            if (err > MAX_ERR_LSB) begin
                fail_count++;
                data_real = $itor($signed(data_q15)) / 32768.0;
                gain_real = $itor(gain_q26) / 64.0;
                $display("FAIL %-18s data=%0d (%f), gain=%0d (%f), got=%0d, golden=%0d, abs_err=%0d LSB",
                         tag, $signed(data_q15), data_real, gain_q26, gain_real, got, golden, err);
            end
        end
    endtask

    task automatic run_directed_tests;
        int g;
        begin
            // Important audio/input corner cases.
            for (g = 0; g <= 255; g++) begin
                check_one(16'sd0,      g[7:0], "zero");
                check_one(16'sd1,      g[7:0], "+1_lsb");
                check_one(-16'sd1,     g[7:0], "-1_lsb");
                check_one(16'sd32767,  g[7:0], "+fullscale");
                check_one(-16'sd32768, g[7:0], "-fullscale");
                check_one(16'sd16384,  g[7:0], "+0.5");
                check_one(-16'sd16384, g[7:0], "-0.5");
            end

            // Gain boundary cases near overdrive bypass threshold used by caller.
            check_one(16'sd1000, 8'd4,  "gain4");
            check_one(16'sd1000, 8'd5,  "gain5");
            check_one(16'sd1000, 8'd64, "gain1x");
            check_one(16'sd1000, 8'd128,"gain2x");
            check_one(16'sd1000, 8'd255,"gainmax");
        end
    endtask

    task automatic run_random_tests;
        int k;
        logic signed [15:0] rand_data;
        logic [7:0] rand_gain;
        begin
            for (k = 0; k < RANDOM_TESTS; k++) begin
                rand_data = $urandom_range(0, 65535);
                rand_gain = $urandom_range(0, 255);
                check_one(rand_data, rand_gain, "random");
            end
        end
    endtask

    initial begin
        total_tests = 0;
        fail_count = 0;
        max_abs_err = 0;
        i_data = '0;
        i_gain = '0;

        $display("=== tb_tanh_selfcheck start ===");
        $display("Tolerance = %0d LSB", MAX_ERR_LSB);

        run_directed_tests();
        run_random_tests();

        $display("=== tb_tanh_selfcheck summary ===");
        $display("Total tests : %0d", total_tests);
        $display("Failures    : %0d", fail_count);
        $display("Max abs err : %0d LSB", max_abs_err);

        if (fail_count == 0) begin
            $display("FINAL RESULT: PASS");
        end else begin
            $display("FINAL RESULT: FAIL");
            $fatal(1);
        end

        $finish;
    end

endmodule
