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

module audio_pwm_driver_tb;
  reg        clk;
  reg        rst;
  reg        beep_enable;
  reg [2:0]  beep_type;
  wire       audio_pwm_o;
  wire       audio_sd_o;

  integer failures;

  audio_pwm_driver #(
      .KEY_HALF_PERIOD(32'd2),
      .ERROR_HALF_PERIOD(32'd3),
      .SUCCESS_HALF_PERIOD(32'd4),
      .COUNTDOWN_HALF_PERIOD(32'd5),
      .ALARM_HALF_PERIOD(32'd6)
  ) dut (
      .clk(clk),
      .rst(rst),
      .beep_enable(beep_enable),
      .beep_type(beep_type),
      .audio_pwm_o(audio_pwm_o),
      .audio_sd_o(audio_sd_o)
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
      rst         = 1'b1;
      beep_enable = 1'b0;
      beep_type   = `BEEP_TYPE_NONE;
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);
    end
  endtask

  task count_pwm_toggles;
    input integer cycles;
    output integer toggles;
    integer i;
    reg previous_pwm;
    begin
      toggles = 0;
      previous_pwm = audio_pwm_o;
      for (i = 0; i < cycles; i = i + 1) begin
        @(negedge clk);
        if (audio_pwm_o != previous_pwm) begin
          toggles = toggles + 1;
          previous_pwm = audio_pwm_o;
        end
      end
    end
  endtask

  task scenario_disabled_output;
    integer toggles;
    begin
      $display("Running scenario_disabled_output");
      reset_dut();

      `CHECK(!audio_sd_o, "reset disables audio shutdown output");
      `CHECK(!audio_pwm_o, "reset clears PWM output");

      count_pwm_toggles(10, toggles);
      `CHECK(toggles == 0, "disabled driver does not toggle PWM");
    end
  endtask

  task scenario_key_pwm;
    integer toggles;
    begin
      $display("Running scenario_key_pwm");
      reset_dut();

      @(negedge clk);
      beep_enable = 1'b1;
      beep_type   = `BEEP_TYPE_KEY;
      wait_cycles(2);
      `CHECK(audio_sd_o, "enabled beep drives audio_sd_o high");

      count_pwm_toggles(12, toggles);
      `CHECK(toggles >= 3, "KEY beep toggles PWM repeatedly");

      @(negedge clk);
      beep_enable = 1'b0;
      wait_cycles(2);
      `CHECK(!audio_sd_o, "disabling beep drives audio_sd_o low");
      `CHECK(!audio_pwm_o, "disabling beep clears audio_pwm_o");
    end
  endtask

  task scenario_type_change_and_alarm;
    integer success_toggles;
    integer alarm_toggles;
    begin
      $display("Running scenario_type_change_and_alarm");
      reset_dut();

      @(negedge clk);
      beep_enable = 1'b1;
      beep_type   = `BEEP_TYPE_SUCCESS;
      wait_cycles(2);
      count_pwm_toggles(20, success_toggles);
      `CHECK(success_toggles >= 2, "SUCCESS beep toggles PWM");

      @(negedge clk);
      beep_type = `BEEP_TYPE_ALARM;
      wait_cycles(2);
      `CHECK(audio_sd_o, "ALARM beep keeps audio enabled");
      count_pwm_toggles(30, alarm_toggles);
      `CHECK(alarm_toggles >= 2, "ALARM beep toggles PWM");

      @(negedge clk);
      beep_type = `BEEP_TYPE_NONE;
      wait_cycles(2);
      `CHECK(!audio_sd_o, "NONE type disables audio even when beep_enable is high");
      `CHECK(!audio_pwm_o, "NONE type clears PWM");
    end
  endtask

  initial begin
    failures = 0;

    scenario_disabled_output();
    scenario_key_pwm();
    scenario_type_change_and_alarm();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
