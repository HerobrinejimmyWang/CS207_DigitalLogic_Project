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

module error_manager_tb;
  reg        clk;
  reg        rst;
  reg        tick_1s;
  reg        error_req;
  reg [3:0]  error_code_in;
  reg [3:0]  return_target_in;
  wire       error_active;
  wire [3:0] display_error_code;
  wire [3:0] return_target;
  wire       error_done;

  integer failures;

  error_manager dut (
      .clk(clk),
      .rst(rst),
      .tick_1s(tick_1s),
      .error_req(error_req),
      .error_code_in(error_code_in),
      .return_target_in(return_target_in),
      .error_active(error_active),
      .display_error_code(display_error_code),
      .return_target(return_target),
      .error_done(error_done)
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

  task pulse_tick_1s;
    begin
      @(negedge clk);
      tick_1s = 1'b1;
      @(negedge clk);
      tick_1s = 1'b0;
    end
  endtask

  task scenario_basic_hold_and_done;
    begin
      $display("Running scenario_basic_hold_and_done");
      rst              = 1'b1;
      tick_1s          = 1'b0;
      error_req        = 1'b0;
      error_code_in    = 4'd0;
      return_target_in = 4'd0;
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);

      @(negedge clk);
      error_req        = 1'b1;
      error_code_in    = 4'd3;
      return_target_in = 4'd7;
      @(negedge clk);
      error_req = 1'b0;
      `CHECK(error_active, "error request enters active state");
      `CHECK(display_error_code == 4'd3, "error code is latched");
      `CHECK(return_target == 4'd7, "return target is latched");

      pulse_tick_1s();
      `CHECK(!error_active, "tick_1s clears the active error");
      `CHECK(error_done, "tick_1s produces error_done pulse");
      wait_cycles(1);
      `CHECK(!error_done, "error_done pulse clears on following cycle");
    end
  endtask

  task scenario_ignore_reentrant_request;
    begin
      $display("Running scenario_ignore_reentrant_request");
      rst              = 1'b1;
      tick_1s          = 1'b0;
      error_req        = 1'b0;
      error_code_in    = 4'd0;
      return_target_in = 4'd0;
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);

      @(negedge clk);
      error_req        = 1'b1;
      error_code_in    = 4'd1;
      return_target_in = 4'd2;
      @(negedge clk);
      error_req = 1'b0;

      @(negedge clk);
      error_req        = 1'b1;
      error_code_in    = 4'd5;
      return_target_in = 4'd9;
      @(negedge clk);
      error_req = 1'b0;

      `CHECK(display_error_code == 4'd1, "active error ignores reentrant error code");
      `CHECK(return_target == 4'd2, "active error ignores reentrant return target");
    end
  endtask

  initial begin
    failures = 0;

    scenario_basic_hold_and_done();
    scenario_ignore_reentrant_request();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
