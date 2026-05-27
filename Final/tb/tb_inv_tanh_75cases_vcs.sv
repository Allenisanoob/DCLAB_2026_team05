`timescale 1ns/1ps
// 75-case VCS testbench for inv_tanh.sv
// DUT default module name matches your current inv_tanh.sv:
//   module inv_tanh_lut_128_pruned (...)
// Compile:
//   vcs -full64 -sverilog -timescale=1ns/1ps inv_tanh.sv tb_inv_tanh_75cases_vcs.sv -o simv
//   ./simv
// If you rename the DUT module itself to inv_tanh, compile with:
//   vcs -full64 -sverilog -timescale=1ns/1ps +define+DUT_MODULE=inv_tanh inv_tanh.sv tb_inv_tanh_75cases_vcs.sv -o simv

`ifndef DUT_MODULE
`define DUT_MODULE inv_tanh_lut_128_pruned
`endif

module tb_inv_tanh_75cases;

    logic [7:0]  i_gain;
    logic [15:0] o_inv_tanh_val;

    integer test_count;
    integer fail_count;
    integer max_abs_err_lsb;
    integer log_fd;

    `DUT_MODULE dut (
        .i_gain(i_gain),
        .o_inv_tanh_val(o_inv_tanh_val)
    );

    task automatic run_one_case;
        input [7:0] gain_code;
        input integer expected_q79;
        integer dut_q79;
        integer err_lsb;
        integer abs_err_lsb;
        real gain_real;
        real dut_real;
        real exp_real;
        begin
            i_gain = gain_code;
            #1;

            dut_q79 = o_inv_tanh_val;
            err_lsb = dut_q79 - expected_q79;
            abs_err_lsb = (err_lsb < 0) ? -err_lsb : err_lsb;

            gain_real = gain_code / 64.0;
            dut_real  = dut_q79 / 512.0;
            exp_real  = expected_q79 / 512.0;

            test_count = test_count + 1;
            if (abs_err_lsb > max_abs_err_lsb)
                max_abs_err_lsb = abs_err_lsb;

            if (err_lsb != 0)
                fail_count = fail_count + 1;

            $display("case=%0d gain_code=%0d gain=%0.6f | dut_q79=%0d dut=%0.9f | ref_q79=%0d ref=%0.9f | err_lsb=%0d abs_err_lsb=%0d %s",
                     test_count, gain_code, gain_real,
                     dut_q79, dut_real,
                     expected_q79, exp_real,
                     err_lsb, abs_err_lsb,
                     (err_lsb == 0) ? "PASS" : "FAIL");

            if (log_fd != 0) begin
                $fdisplay(log_fd, "%0d,%0d,%0.9f,%0d,%0.9f,%0d,%0.9f,%0d,%0d,%s",
                          test_count, gain_code, gain_real,
                          dut_q79, dut_real,
                          expected_q79, exp_real,
                          err_lsb, abs_err_lsb,
                          (err_lsb == 0) ? "PASS" : "FAIL");
            end
        end
    endtask

    initial begin
        i_gain = 8'd0;
        test_count = 0;
        fail_count = 0;
        max_abs_err_lsb = 0;

        log_fd = $fopen("inv_tanh_error_lsb_75cases.csv", "w");
        if (log_fd == 0) begin
            $display("WARNING: could not open inv_tanh_error_lsb_75cases.csv");
        end else begin
            $fdisplay(log_fd, "case,gain_code,gain_real,dut_q79,dut_real,ref_q79,ref_real,err_lsb,abs_err_lsb,result");
        end

        $display("Start inv_tanh 75-case LUT testbench");
        $display("Reference: i_gain <= 4 => dummy 0; otherwise round((1/tanh(i_gain/64))*512), Q7.9");
        $display("------------------------------------------------------------------------------------------------------------");

        run_one_case(8'd0, 0);
        run_one_case(8'd1, 0);
        run_one_case(8'd2, 0);
        run_one_case(8'd3, 0);
        run_one_case(8'd4, 0);
        run_one_case(8'd5, 6567);
        run_one_case(8'd6, 5477);
        run_one_case(8'd7, 4700);
        run_one_case(8'd8, 4117);
        run_one_case(8'd9, 3665);
        run_one_case(8'd10, 3303);
        run_one_case(8'd11, 3008);
        run_one_case(8'd12, 2763);
        run_one_case(8'd13, 2555);
        run_one_case(8'd14, 2378);
        run_one_case(8'd15, 2224);
        run_one_case(8'd16, 2090);
        run_one_case(8'd17, 1973);
        run_one_case(8'd19, 1775);
        run_one_case(8'd20, 1691);
        run_one_case(8'd21, 1616);
        run_one_case(8'd23, 1486);
        run_one_case(8'd24, 1429);
        run_one_case(8'd25, 1377);
        run_one_case(8'd27, 1285);
        run_one_case(8'd28, 1244);
        run_one_case(8'd29, 1206);
        run_one_case(8'd31, 1138);
        run_one_case(8'd32, 1108);
        run_one_case(8'd33, 1079);
        run_one_case(8'd35, 1028);
        run_one_case(8'd36, 1004);
        run_one_case(8'd37, 982);
        run_one_case(8'd39, 942);
        run_one_case(8'd40, 923);
        run_one_case(8'd41, 906);
        run_one_case(8'd44, 859);
        run_one_case(8'd48, 806);
        run_one_case(8'd52, 763);
        run_one_case(8'd56, 727);
        run_one_case(8'd60, 697);
        run_one_case(8'd64, 672);
        run_one_case(8'd68, 651);
        run_one_case(8'd72, 633);
        run_one_case(8'd76, 617);
        run_one_case(8'd80, 604);
        run_one_case(8'd84, 592);
        run_one_case(8'd88, 582);
        run_one_case(8'd92, 573);
        run_one_case(8'd96, 566);
        run_one_case(8'd100, 559);
        run_one_case(8'd104, 553);
        run_one_case(8'd108, 548);
        run_one_case(8'd112, 544);
        run_one_case(8'd116, 540);
        run_one_case(8'd120, 537);
        run_one_case(8'd124, 534);
        run_one_case(8'd128, 531);
        run_one_case(8'd132, 529);
        run_one_case(8'd140, 525);
        run_one_case(8'd148, 522);
        run_one_case(8'd156, 520);
        run_one_case(8'd164, 518);
        run_one_case(8'd172, 517);
        run_one_case(8'd180, 516);
        run_one_case(8'd188, 515);
        run_one_case(8'd196, 514);
        run_one_case(8'd204, 514);
        run_one_case(8'd212, 513);
        run_one_case(8'd220, 513);
        run_one_case(8'd228, 513);
        run_one_case(8'd236, 513);
        run_one_case(8'd244, 513);
        run_one_case(8'd252, 512);
        run_one_case(8'd255, 512);

        $display("------------------------------------------------------------------------------------------------------------");
        $display("Total cases       = %0d", test_count);
        $display("Fail count        = %0d", fail_count);
        $display("Max abs error LSB = %0d", max_abs_err_lsb);

        if (log_fd != 0)
            $fclose(log_fd);

        if (fail_count == 0) begin
            $display("PASS: all 75 inv_tanh cases match expected Q7.9 values exactly.");
        end else begin
            $display("FAIL: %0d / %0d cases mismatched.", fail_count, test_count);
        end

        $finish;
    end

endmodule
