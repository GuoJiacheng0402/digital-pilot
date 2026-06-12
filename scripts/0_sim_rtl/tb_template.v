`timescale 1ns/1ps
// =============================================================================
// DigitalPilot · Testbench 骨架(黄金模型 + LATENCY 对齐 + 定向用例宏)
// 这是"方法学骨架":黄金模型 model_y() 必须按你的题目公式独立实现,勿抄 RTL。
// 三处 tb(RTL/前仿/后仿)共用本骨架,仅 SDF 注释行不同。
// =============================================================================
module tb_DESIGN;
    localparam integer LATENCY = 12;          // ← 与你的流水线深度一致(报告需说明)
    localparam integer N_RANDOM = 3000;       // 随机用例数(题面≥1000,建议 3000)

    reg clk, reset;
    // ↓ 按题目端口修改
    reg  [11:0] a, b, c;
    reg         e;
    wire [12:0] y;

    DESIGN dut (.clk(clk), .reset(reset), .a(a), .b(b), .c(c), .e(e), .y(y));

    initial begin clk = 0; forever #2.5 clk = ~clk; end   // 200 MHz

    initial begin
        $fsdbDumpfile("tb_DESIGN.fsdb");
        $fsdbDumpvars(0, tb_DESIGN);
        // 前仿: $sdf_annotate("./rtl/DESIGN.sdf",      dut, , "sdf.log", "MAXIMUM");
        // 后仿: $sdf_annotate("./rtl/DESIGN_wst.sdf",  dut, , "sdf.log", "MAXIMUM");
    end

    // ---------------- 黄金模型(独立实现题目公式!) ----------------
    function [12:0] model_y(input [11:0] in_a, in_b, in_c, in_d);
        begin
            // TODO: 按题目公式实现(实数运算 + 与 RTL 相同的舍入/饱和)
            model_y = 13'd0;
        end
    endfunction

    // ---------------- LATENCY 对齐管线 + 逐拍自检 ----------------
    reg [12:0] exp_pipe [0:LATENCY-1];
    integer i, cycle = 0, errors = 0, checks = 0;
    task clear_expected; integer k; begin
        for (k = 0; k < LATENCY; k = k + 1) exp_pipe[k] = 13'd0;
    end endtask

    task drive_cycle(input rst, input [11:0] aa, bb, cc, input ee); begin
        @(negedge clk); reset = rst; a = aa; b = bb; c = cc; e = ee;
    end endtask

    always @(posedge clk) begin : checker
        reg [12:0] exp_now;
        if (reset) begin
            #1; if (y !== 13'd0) begin errors = errors + 1;
                $display("ERROR cycle=%0d reset expects y=0 got %b", cycle, y); end
            clear_expected();
            // TODO: 同步清零黄金模型内部状态(如串行参数寄存器)
        end else begin
            exp_now = model_y(a, b, c, /*d_eff*/ 12'd0);
            #1; checks = checks + 1;
            if (y !== exp_pipe[LATENCY-1]) begin
                $display("ERROR cycle=%0d exp=%0d got=%0d", cycle,
                         $signed(exp_pipe[LATENCY-1]), $signed(y));
                errors = errors + 1;
                if (errors > 20) begin $display("Too many errors"); $finish; end
            end
            for (i = LATENCY-1; i > 0; i = i - 1) exp_pipe[i] = exp_pipe[i-1];
            exp_pipe[0] = exp_now;
            // TODO: 黄金模型的逐拍状态推进(串行参数移位等)
        end
        cycle = cycle + 1;
    end

    // ---------------- 定向用例宏(答辩友好:每组前 reset + 日志锚点) ----------------
`define RUN_CASE(ID, AV, BV, CV, EV) \
        begin \
            $display("CASE_%0d_START a=%0d b=%0d c=%0d time=%0t", ID, AV, BV, CV, $time); \
            repeat (2) drive_cycle(1'b1, 12'd0, 12'd0, 12'd0, 1'b0); \
            drive_cycle(1'b0, AV, BV, CV, EV); \
            repeat (LATENCY) drive_cycle(1'b0, 12'd0, 12'd0, 12'd0, 1'b0); \
            @(negedge clk); \
            $display("CASE_%0d_OUTPUT y=%0d raw=%b time=%0t", ID, $signed(y), y, $time); \
        end

    // ---------------- 激励主线(按题面覆盖清单组织) ----------------
    initial begin
        reset = 1; a = 0; b = 0; c = 0; e = 0; clear_expected();
        repeat (5) drive_cycle(1'b1, 12'd0, 12'd0, 12'd0, 1'b0);   // 1.上电复位
        // 2-9. TODO: 边界/排列/饱和/复位打断等定向场景(用 `RUN_CASE)
        repeat (N_RANDOM) drive_cycle(1'b0, $random, $random, $random, $random); // 10.随机
        repeat (LATENCY + 5) drive_cycle(1'b0, 12'd0, 12'd0, 12'd0, 1'b0);       // 排空
        @(negedge clk);
        if (errors == 0) $display("PASS tb_DESIGN checks=%0d latency=%0d", checks, LATENCY);
        else             $display("FAIL tb_DESIGN errors=%0d checks=%0d", errors, checks);
        $finish;
    end
`undef RUN_CASE
endmodule
