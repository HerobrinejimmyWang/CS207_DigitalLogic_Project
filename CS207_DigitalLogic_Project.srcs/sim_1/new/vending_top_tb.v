`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/18 16:39:10
// Design Name: 
// Module Name: vending_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module vending_top_tb;
    reg clk;
    reg rst_n;
    reg btn_coin_1;
    reg btn_coin_2;
    reg btn_coin_5;
    reg [1:0] btn_sel;
    reg btn_confirm;
    reg btn_cancel;

    wire [6:0] seg;
    wire [3:0] an;
    wire dp;
    wire [7:0] led;
    wire dispense_pulse;

    integer dispense_count;

    vending_top #(
        .DEBOUNCE_CYCLES(2),
        .HOLD_CYCLES(4),
        .SCAN_DIV_BITS(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_coin_1(btn_coin_1),
        .btn_coin_2(btn_coin_2),
        .btn_coin_5(btn_coin_5),
        .btn_sel(btn_sel),
        .btn_confirm(btn_confirm),
        .btn_cancel(btn_cancel),
        .seg(seg),
        .an(an),
        .dp(dp),
        .led(led),
        .dispense_pulse(dispense_pulse)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (dispense_pulse) begin
            dispense_count <= dispense_count + 1;
        end
    end

    task press_coin_1;
        begin
            btn_coin_1 = 1'b1;
            repeat (4) @(posedge clk);
            btn_coin_1 = 1'b0;
            repeat (4) @(posedge clk);
        end
    endtask

    task press_coin_2;
        begin
            btn_coin_2 = 1'b1;
            repeat (4) @(posedge clk);
            btn_coin_2 = 1'b0;
            repeat (4) @(posedge clk);
        end
    endtask

    task press_coin_5;
        begin
            btn_coin_5 = 1'b1;
            repeat (4) @(posedge clk);
            btn_coin_5 = 1'b0;
            repeat (4) @(posedge clk);
        end
    endtask

    task press_confirm;
        begin
            btn_confirm = 1'b1;
            repeat (4) @(posedge clk);
            btn_confirm = 1'b0;
            repeat (4) @(posedge clk);
        end
    endtask

    task press_cancel;
        begin
            btn_cancel = 1'b1;
            repeat (4) @(posedge clk);
            btn_cancel = 1'b0;
            repeat (4) @(posedge clk);
        end
    endtask

    task assert_equal;
        input [31:0] actual;
        input [31:0] expected;
        input [255:0] label;
        begin
            if (actual !== expected) begin
                $display("ASSERTION FAILED: %0s actual=%0d expected=%0d", label, actual, expected);
                $finish(1);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        btn_coin_1 = 1'b0;
        btn_coin_2 = 1'b0;
        btn_coin_5 = 1'b0;
        btn_sel = 2'b00;
        btn_confirm = 1'b0;
        btn_cancel = 1'b0;
        dispense_count = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        assert_equal(dut.u_money_counter.current_amount, 0, "reset amount");
        assert_equal(dut.u_inventory_mgr.stocks_flat, 16'h5555, "reset stock");

        btn_sel = 2'b01;
        repeat (2) @(posedge clk);
        assert_equal(dut.selected_product, 1, "selection follows input");

        press_coin_2;
        press_confirm;
        assert_equal(dut.u_vending_fsm.status_code, 2'b01, "insufficient funds status");
        assert_equal(dut.u_money_counter.current_amount, 2, "amount preserved on insufficient funds");

        press_coin_5;
        press_confirm;
        repeat (3) @(posedge clk);
        assert_equal(dispense_count, 1, "one successful vend");
        assert_equal(dut.u_inventory_mgr.stocks_flat[7:4], 4, "stock decremented after vend");
        repeat (6) @(posedge clk);
        assert_equal(dut.u_money_counter.current_amount, 0, "amount cleared after vend");

        btn_sel = 2'b10;
        repeat (2) @(posedge clk);
        press_coin_1;
        press_coin_2;
        press_cancel;
        repeat (2) @(posedge clk);
        assert_equal(dut.u_money_counter.current_amount, 0, "amount cleared after cancel");

        dut.u_inventory_mgr.stock3 = 0;
        btn_sel = 2'b11;
        repeat (2) @(posedge clk);
        press_coin_5;
        press_coin_5;
        press_confirm;
        repeat (2) @(posedge clk);
        assert_equal(dut.u_vending_fsm.status_code, 2'b10, "sold out status");
        assert_equal(dispense_count, 1, "sold out does not vend");

        $display("TB PASS");
        $finish;
    end
endmodule
