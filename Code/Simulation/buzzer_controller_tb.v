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

  task pulse_requests;
    input key_req;
    input error_req;
    input success_req;
    input countdown_req;
    begin
      @(negedge clk);
      key_beep_req       = key_req;
      error_beep_req     = error_req;
      success_beep_req   = success_req;
      countdown_beep_req = countdown_req;
      @(negedge clk);
      key_beep_req       = 1'b0;
      error_beep_req     = 1'b0;
      success_beep_req   = 1'b0;
      countdown_beep_req = 1'b0;
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

  task scenario_reset_and_single_pulses;
    begin
      $display("Running scenario_reset_and_single_pulses");
      reset_dut();

      `CHECK(!beep_enable, "reset leaves beep_enable low");
      `CHECK(beep_type == `BEEP_TYPE_NONE, "reset leaves beep_type at NONE");

      pulse_requests(1'b1, 1'b0, 1'b0, 1'b0);
      `CHECK(beep_enable, "key request starts beep");
      `CHECK(beep_type == `BEEP_TYPE_KEY, "key request selects KEY");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "single key beep clears after one tick");
      `CHECK(beep_type == `BEEP_TYPE_NONE, "single key beep returns to NONE");

      pulse_requests(1'b0, 1'b1, 1'b0, 1'b0);
      `CHECK(beep_enable, "error request starts beep");
      `CHECK(beep_type == `BEEP_TYPE_ERROR, "error request selects ERROR");
      pulse_tick_100ms();
      `CHECK(beep_enable, "error beep survives first tick");
      pulse_tick_100ms();
      `CHECK(beep_enable, "error beep survives second tick");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "error beep clears after third tick");

      pulse_requests(1'b0, 1'b0, 1'b1, 1'b0);
      `CHECK(beep_enable, "success request starts beep");
      `CHECK(beep_type == `BEEP_TYPE_SUCCESS, "success request selects SUCCESS");
      pulse_tick_100ms();
      `CHECK(beep_enable, "success beep survives first tick");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "success beep clears after second tick");

      pulse_requests(1'b0, 1'b0, 1'b0, 1'b1);
      `CHECK(beep_enable, "countdown request starts beep");
      `CHECK(beep_type == `BEEP_TYPE_COUNTDOWN, "countdown request selects COUNTDOWN");
      pulse_tick_100ms();
      `CHECK(!beep_enable, "countdown beep clears after one tick");
    end
  endtask

  task scenario_priority_and_preemption;
    begin
      $display("Running scenario_priority_and_preemption");
      reset_dut();

      pulse_requests(1'b1, 1'b1, 1'b0, 1'b0);
      `CHECK(beep_enable, "simultaneous key/error still starts beep");
      `CHECK(beep_type == `BEEP_TYPE_ERROR, "ERROR outranks KEY");
      pulse_tick_100ms();
      pulse_tick_100ms();
      pulse_tick_100ms();

      pulse_requests(1'b0, 1'b0, 1'b1, 1'b1);
      `CHECK(beep_type == `BEEP_TYPE_SUCCESS, "SUCCESS outranks COUNTDOWN");

      pulse_requests(1'b1, 1'b0, 1'b0, 1'b0);
      `CHECK(beep_type == `BEEP_TYPE_SUCCESS, "lower priority KEY is ignored during SUCCESS");
      pulse_tick_100ms();
      pulse_tick_100ms();
      `CHECK(!beep_enable, "success beep eventually clears");

      pulse_requests(1'b1, 1'b0, 1'b0, 1'b0);
      `CHECK(beep_type == `BEEP_TYPE_KEY, "fresh KEY starts after idle");
      pulse_requests(1'b0, 1'b1, 1'b0, 1'b0);
      `CHECK(beep_type == `BEEP_TYPE_ERROR, "ERROR preempts active KEY");
    end
  endtask

  task scenario_alarm_and_recovery;
    begin
      $display("Running scenario_alarm_and_recovery");
      reset_dut();

      pulse_requests(1'b0, 1'b0, 1'b0, 1'b1);
      `CHECK(beep_type == `BEEP_TYPE_COUNTDOWN, "countdown beep enters active state");

      @(negedge clk);
      alarm_active = 1'b1;
      @(negedge clk);
      `CHECK(beep_enable, "alarm keeps beep enabled");
      `CHECK(beep_type == `BEEP_TYPE_ALARM, "alarm preempts active non-alarm beep");

      pulse_requests(1'b1, 1'b1, 1'b1, 1'b1);
      `CHECK(beep_type == `BEEP_TYPE_ALARM, "alarm ignores other simultaneous requests");

      @(negedge clk);
      alarm_active = 1'b0;
      @(negedge clk);
      `CHECK(!beep_enable, "dropping alarm returns controller to idle");
      `CHECK(beep_type == `BEEP_TYPE_NONE, "dropping alarm restores NONE type");

      pulse_requests(1'b1, 1'b0, 1'b0, 1'b0);
      `CHECK(beep_enable, "controller accepts new request after alarm");
      `CHECK(beep_type == `BEEP_TYPE_KEY, "post-alarm request still works");
    end
  endtask

  initial begin
    failures = 0;

    scenario_reset_and_single_pulses();
    scenario_priority_and_preemption();
    scenario_alarm_and_recovery();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
