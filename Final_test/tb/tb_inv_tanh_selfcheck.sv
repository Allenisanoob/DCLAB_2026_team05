`timescale 1ns/1ps

// Self-checking testbench for inv_tanh.sv
// DUT behavior:
//   i_gain          : unsigned Q2.6, gain = i_gain / 64.0
//   o_inv_tanh_val : unsigned Q7.9, approximately 1 / tanh(gain)
//
// The DUT intentionally returns 0 for i_gain <= 4, because the caller should
// bypass the overdrive path in that region.

module tb_inv_tanh_selfcheck;

    localparam int MAX_ERR_LSB = 1;

    logic [7:0]  i_gain;
    logic [15:0] o_inv_tanh_val;

    int total_tests;
    int fail_count;
    int max_abs_err;

    inv_tanh dut (
        .i_gain(i_gain),
        .o_inv_tanh_val(o_inv_tanh_val)
    );

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

    function automatic int round_to_int(input real x);
        begin
            if (x >= 0.0)
                round_to_int = $rtoi(x + 0.5);
            else
                round_to_int = $rtoi(x - 0.5);
        end
    endfunction

    function automatic int sat_u16(input int x);
        begin
            if (x < 0)
                sat_u16 = 0;
            else if (x > 65535)
                sat_u16 = 65535;
            else
                sat_u16 = x;
        end
    endfunction

    function automatic int golden_inv_tanh_q79(input logic [7:0] gain_q26);
        real gain_real;
        real y_real;
        int  y_q79;
        begin
            if (gain_q26 <= 8'd4) begin
                // Match DUT design: dummy 0; caller bypasses this range.
                golden_inv_tanh_q79 = 0;
            end else begin
                gain_real = $itor(gain_q26) / 64.0;
                y_real = 1.0 / tanh_real(gain_real);
                y_q79 = round_to_int(y_real * 512.0);
                golden_inv_tanh_q79 = sat_u16(y_q79);
            end
        end
    endfunction

    task automatic check_one(input logic [7:0] gain_q26);
        int golden;
        int got;
        int err;
        real gain_real;
        begin
            i_gain = gain_q26;
            #1; // combinational settle

            golden = golden_inv_tanh_q79(gain_q26);
            got = o_inv_tanh_val;
            err = got - golden;
            if (err < 0) err = -err;

            total_tests++;
            if (err > max_abs_err) max_abs_err = err;

            if (err > MAX_ERR_LSB) begin
                fail_count++;
                gain_real = $itor(gain_q26) / 64.0;
                $display("FAIL gain=%0d (%f), got=%0d, golden=%0d, abs_err=%0d LSB",
                         gain_q26, gain_real, got, golden, err);
            end
        end
    endtask

    initial begin
        total_tests = 0;
        fail_count = 0;
        max_abs_err = 0;
        i_gain = '0;

        $display("=== tb_inv_tanh_selfcheck start ===");
        $display("Tolerance = %0d LSB", MAX_ERR_LSB);

        // Exhaustive: only 256 possible input codes.
        for (int g = 0; g <= 255; g++) begin
            check_one(g[7:0]);
        end

        $display("=== tb_inv_tanh_selfcheck summary ===");
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
