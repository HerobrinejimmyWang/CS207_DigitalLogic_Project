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

module buzzer_controller_tb;
  reg        clk;
  reg        rst;
  reg        tick_100ms;
  reg        key_beep_req;
  reg        error_beep_req;
  reg        success_beep_req;
  reg        countdown_beep_req;
  reg        alarm_active;
  wire       beep_enable;
  wire [2:0] beep_type;

  integer failures;

  buzzer_controller dut (
      .clk(clk),
      .rst(rst),
      .tick_100ms(tick_100ms),
      .key_beep_req(key_beep_req),
      .error_beep_req(error_beep_req),
      .success_beep_req(success_beep_req),
      .countdown_beep_req(countdown_beep_req),
      .alarm_active(alarm_active),
      .beep_enable(beep_enable),
      .beep_type(beep_type)
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
      rst                = 1'b1;
      tick_100ms         = 1'b0;
      key_beep_req       = 1'b0;
      error_beep_req     = 1'b0;
      success_beep_req   = 1'b0;
      countdown_beep_req = 1'b0;
      alarm_active       = 1'b0;
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

  task pulse_key_req;
    begin
      @(negedge clk);
      key_beep_req = 1'b1;
      @(negedge clk);
      key_beep_req = 1'b0;
    end
  endtask

  task pulse_success_req;
    begin
      @(negedge clk);
      success_beep_req = 1'b1;
      @(negedge clk);
      success_beep_req = 1'b0;
    end
  endtask

  task scenario_basic_key_and_countdown;
    begin
      $display("Running scenario_basic_key_and_countdown");
      reset_dut();

      `CHECK(!beep_enable, "reset clears beep_enable");
      `CHECK(beep_type == `BEEP_TYPE_NONE, "reset clears beep_type");

      pulse_key_req();
      `CHECK(beep_enable, "key request enables beep");
      `CHECK(beep_type == `BEEP_TYPE_KEY, "key request selects KEY type");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "KEY beep stops after one 100ms tick");
      `CHECK(beep_type == `BEEP_TYPE_NONE, "KEY beep clears type after duration");

      @(negedge clk);
      countdown_beep_req = 1'b1;
      @(negedge clk);
      countdown_beep_req = 1'b0;
      `CHECK(beep_enable, "countdown request enables beep");
      `CHECK(beep_type == `BEEP_TYPE_COUNTDOWN, "countdown request selects COUNTDOWN type");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "COUNTDOWN beep stops after one 100ms tick");
    end
  endtask

  task scenario_priority_and_override;
    begin
      $display("Running scenario_priority_and_override");
      reset_dut();

      @(negedge clk);
      key_beep_req   = 1'b1;
      error_beep_req = 1'b1;
      @(negedge clk);
      key_beep_req   = 1'b0;
      error_beep_req = 1'b0;
      `CHECK(beep_enable, "simultaneous request enables beep");
      `CHECK(beep_type == `BEEP_TYPE_ERROR, "ERROR has priority over KEY");

      pulse_key_req();
      `CHECK(beep_type == `BEEP_TYPE_KEY, "new KEY request can start after ERROR request");
      pulse_success_req();
      `CHECK(beep_type == `BEEP_TYPE_SUCCESS, "SUCCESS request overrides active KEY beep");
      pulse_tick_100ms();
      `CHECK(beep_enable, "SUCCESS beep remains active after first 100ms tick");
      `CHECK(beep_type == `BEEP_TYPE_SUCCESS, "SUCCESS type remains during second tick window");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "SUCCESS beep stops after two 100ms ticks");
    end
  endtask

  task scenario_alarm_priority;
    begin
      $display("Running scenario_alarm_priority");
      reset_dut();

      @(negedge clk);
      alarm_active   = 1'b1;
      key_beep_req   = 1'b1;
      error_beep_req = 1'b1;
      @(negedge clk);
      key_beep_req   = 1'b0;
      error_beep_req = 1'b0;
      `CHECK(beep_enable, "alarm enables beep");
      `CHECK(beep_type == `BEEP_TYPE_ALARM, "ALARM has highest priority");

      pulse_tick_100ms();
      pulse_tick_100ms();
      `CHECK(beep_enable, "alarm stays active across ticks");
      `CHECK(beep_type == `BEEP_TYPE_ALARM, "alarm type stays active across ticks");

      @(negedge clk);
      alarm_active = 1'b0;
      @(negedge clk);
      `CHECK(!beep_enable, "clearing alarm disables continuous beep");
      `CHECK(beep_type == `BEEP_TYPE_NONE, "clearing alarm clears beep type");
    end
  endtask

  initial begin
    failures = 0;

    scenario_basic_key_and_countdown();
    scenario_priority_and_override();
    scenario_alarm_priority();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
