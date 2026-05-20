`timescale 1ns / 1ps

`include "../Design/admin_mode_defs.vh"

`define CHECK(cond, msg) \
  begin \
    if (!(cond)) begin \
      failures = failures + 1; \
      $display("FAIL: %s at time %0t", msg, $time); \
    end else begin \
      $display("PASS: %s", msg); \
    end \
  end

module led_controller_tb;
  reg        clk;
  reg        rst;
  reg        tick_100ms;
  reg [4:0]  ui_page;
  reg [2:0]  ui_mode;
  reg [3:0]  ui_error_code;
  reg        ui_alarm_active;
  wire [15:0] led_pin;

  integer failures;

  localparam [4:0] UI_PAGE_MAIN_MENU      = 5'd0;
  localparam [4:0] UI_PAGE_SALE_WAIT_TAKE = 5'd4;

  led_controller dut (
      .clk(clk),
      .rst(rst),
      .tick_100ms(tick_100ms),
      .ui_page(ui_page),
      .ui_mode(ui_mode),
      .ui_error_code(ui_error_code),
      .ui_alarm_active(ui_alarm_active),
      .led_pin(led_pin)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task wait_cycles;
    input integer count;
    integer i;
    begin
      for (i = 0; i < count; i = i + 1) begin
        @(negedge clk);
      end
    end
  endtask

  task reset_dut;
    begin
      rst             = 1'b1;
      tick_100ms      = 1'b0;
      ui_page         = UI_PAGE_MAIN_MENU;
      ui_mode         = `MODE_MAIN_MENU;
      ui_error_code   = 4'd0;
      ui_alarm_active = 1'b0;
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);
    end
  endtask

  task pulse_tick_100ms;
    begin
      @(negedge clk);
      tick_100ms = 1'b1;
      @(negedge clk);
      tick_100ms = 1'b0;
    end
  endtask

  task scenario_reset_mode_and_error;
    begin
      $display("Running scenario_reset_mode_and_error");
      reset_dut();

      `CHECK(led_pin[15:12] == 4'b1000, "reset/release shows MAIN mode lamp");
      `CHECK(led_pin[11:8] == 4'b0000, "reset clears error lamps");
      `CHECK(led_pin[7:0] == 8'h00, "reset clears animation LEDs");

      ui_mode = `MODE_SALE;
      wait_cycles(1);
      `CHECK(led_pin[15:12] == 4'b0100, "SALE mode lamp is one-hot");

      ui_mode = `MODE_AUTH;
      wait_cycles(1);
      `CHECK(led_pin[15:12] == 4'b0010, "AUTH mode lamp is one-hot");

      ui_mode = `MODE_ADMIN;
      wait_cycles(1);
      `CHECK(led_pin[15:12] == 4'b0001, "ADMIN mode lamp is one-hot");

      ui_error_code = 4'd5;
      wait_cycles(1);
      `CHECK(led_pin[11:8] == 4'd5, "error code transparently drives mid LEDs");
    end
  endtask

  task scenario_wait_take_running_light;
    begin
      $display("Running scenario_wait_take_running_light");
      reset_dut();

      ui_mode = `MODE_SALE;
      ui_page = UI_PAGE_SALE_WAIT_TAKE;
      wait_cycles(1);
      `CHECK(led_pin[7:0] == 8'b0000_0001, "WAIT_TAKE starts from first running-light position");

      pulse_tick_100ms();
      `CHECK(led_pin[7:0] == 8'b0000_0010, "running light advances on first 100ms tick");

      pulse_tick_100ms();
      `CHECK(led_pin[7:0] == 8'b0000_0100, "running light advances on second 100ms tick");

      ui_page = UI_PAGE_MAIN_MENU;
      wait_cycles(1);
      `CHECK(led_pin[7:0] == 8'h00, "leaving WAIT_TAKE clears animation LEDs");

      ui_page = UI_PAGE_SALE_WAIT_TAKE;
      wait_cycles(1);
      `CHECK(led_pin[7:0] == 8'b0000_0001, "re-entering WAIT_TAKE restarts from initial position");
    end
  endtask

  task scenario_alarm_priority;
    begin
      $display("Running scenario_alarm_priority");
      reset_dut();

      ui_mode = `MODE_SALE;
      ui_page = UI_PAGE_SALE_WAIT_TAKE;
      wait_cycles(1);
      `CHECK(led_pin[15:12] == 4'b0100, "SALE mode lamp visible before alarm");

      ui_alarm_active = 1'b1;
      wait_cycles(1);
      `CHECK(led_pin[15:12] == 4'b0000, "alarm suppresses normal mode lamps");
      `CHECK(led_pin[7:0] == 8'h00, "alarm starts from flash-off phase before first tick");

      pulse_tick_100ms();
      `CHECK(led_pin[7:0] == 8'hFF, "alarm flash turns all low LEDs on");

      pulse_tick_100ms();
      `CHECK(led_pin[7:0] == 8'h00, "alarm flash toggles all low LEDs off");

      ui_alarm_active = 1'b0;
      ui_page         = UI_PAGE_MAIN_MENU;
      wait_cycles(1);
      `CHECK(led_pin[7:0] == 8'h00, "clearing alarm returns low LEDs to idle");
      `CHECK(led_pin[15:12] == 4'b0100, "clearing alarm restores current mode lamp");
    end
  endtask

  initial begin
    failures = 0;

    scenario_reset_mode_and_error();
    scenario_wait_take_running_light();
    scenario_alarm_priority();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
