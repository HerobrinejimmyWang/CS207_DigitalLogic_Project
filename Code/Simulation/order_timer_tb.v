`timescale 1ns / 1ps

`define CHECK(cond, msg) \
  begin \
    if (!(cond)) begin \
      failures = failures + 1; \
      $display("FAIL: %s at time %0t", msg, $time); \
    end else begin \
      $display("PASS: %s", msg); \
    end \
  end

module order_timer_tb;
  reg        clk;
  reg        rst;
  reg        tick_1s;
  reg        start;
  reg        stop;
  wire [2:0] remaining_sec;
  wire       timeout;
  wire       running;

  integer failures;

  order_timer dut (
      .clk(clk),
      .rst(rst),
      .tick_1s(tick_1s),
      .start(start),
      .stop(stop),
      .remaining_sec(remaining_sec),
      .timeout(timeout),
      .running(running)
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
      rst     = 1'b1;
      tick_1s = 1'b0;
      start   = 1'b0;
      stop    = 1'b0;
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);
    end
  endtask

  task pulse_start;
    begin
      @(negedge clk);
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
    end
  endtask

  task pulse_stop;
    begin
      @(negedge clk);
      stop = 1'b1;
      @(negedge clk);
      stop = 1'b0;
    end
  endtask

  task pulse_tick_1s;
    begin
      @(negedge clk);
      tick_1s = 1'b1;
      @(negedge clk);
      tick_1s = 1'b0;
    end
  endtask

  task scenario_countdown_timeout;
    begin
      $display("Running scenario_countdown_timeout");
      reset_dut();

      `CHECK(!running, "reset clears running");
      `CHECK(remaining_sec == 3'd0, "reset clears remaining_sec");
      `CHECK(!timeout, "reset clears timeout");

      pulse_start();
      `CHECK(running, "start begins countdown");
      `CHECK(remaining_sec == 3'd5, "start loads 5 seconds");

      pulse_tick_1s();
      `CHECK(running, "timer still running after first tick");
      `CHECK(remaining_sec == 3'd4, "first tick decrements to 4");

      pulse_tick_1s();
      pulse_tick_1s();
      pulse_tick_1s();
      `CHECK(remaining_sec == 3'd1, "four ticks leave one second");
      `CHECK(!timeout, "timeout has not fired before zero");

      pulse_tick_1s();
      `CHECK(!running, "timer stops at zero");
      `CHECK(remaining_sec == 3'd0, "timeout leaves remaining_sec at 0");
      `CHECK(timeout, "timeout pulses when countdown reaches zero");

      wait_cycles(1);
      `CHECK(!timeout, "timeout is a one-cycle pulse");
    end
  endtask

  task scenario_stop_and_restart;
    begin
      $display("Running scenario_stop_and_restart");
      reset_dut();

      pulse_start();
      pulse_tick_1s();
      pulse_tick_1s();
      `CHECK(remaining_sec == 3'd3, "timer reaches 3 before stop");

      pulse_stop();
      `CHECK(!running, "stop clears running");
      `CHECK(remaining_sec == 3'd0, "stop clears remaining_sec");

      pulse_tick_1s();
      `CHECK(!timeout, "stopped timer ignores ticks");

      pulse_start();
      `CHECK(running, "timer can restart after stop");
      `CHECK(remaining_sec == 3'd5, "restart reloads 5 seconds");
    end
  endtask

  initial begin
    failures = 0;

    scenario_countdown_timeout();
    scenario_stop_and_restart();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
