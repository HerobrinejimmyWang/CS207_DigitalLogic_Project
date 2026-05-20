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

module buzzer_request_adapter_tb;
  reg        event_valid;
  reg        tick_1s;
  reg [3:0]  sale_state;
  reg [2:0]  remaining_sec;
  reg        sale_total_add_req;
  reg        sale_error_req;
  reg        auth_ok;
  reg        auth_error_req;
  reg        admin_set_price_req;
  reg        admin_add_stock_req;
  reg        admin_toggle_enable_req;
  reg        admin_error_req;
  reg        alarm_mode_en;
  wire       key_beep_req;
  wire       error_beep_req;
  wire       success_beep_req;
  wire       countdown_beep_req;
  wire       alarm_active;

  integer failures;

  buzzer_request_adapter dut (
      .event_valid(event_valid),
      .tick_1s(tick_1s),
      .sale_state(sale_state),
      .remaining_sec(remaining_sec),
      .sale_total_add_req(sale_total_add_req),
      .sale_error_req(sale_error_req),
      .auth_ok(auth_ok),
      .auth_error_req(auth_error_req),
      .admin_set_price_req(admin_set_price_req),
      .admin_add_stock_req(admin_add_stock_req),
      .admin_toggle_enable_req(admin_toggle_enable_req),
      .admin_error_req(admin_error_req),
      .alarm_mode_en(alarm_mode_en),
      .key_beep_req(key_beep_req),
      .error_beep_req(error_beep_req),
      .success_beep_req(success_beep_req),
      .countdown_beep_req(countdown_beep_req),
      .alarm_active(alarm_active)
  );

  task clear_inputs;
    begin
      event_valid            = 1'b0;
      tick_1s                = 1'b0;
      sale_state             = `SALE_STATE_SHOW_LIST;
      remaining_sec          = 3'd0;
      sale_total_add_req     = 1'b0;
      sale_error_req         = 1'b0;
      auth_ok                = 1'b0;
      auth_error_req         = 1'b0;
      admin_set_price_req    = 1'b0;
      admin_add_stock_req    = 1'b0;
      admin_toggle_enable_req= 1'b0;
      admin_error_req        = 1'b0;
      alarm_mode_en          = 1'b0;
      #1;
    end
  endtask

  initial begin
    failures = 0;
    clear_inputs();

    event_valid = 1'b1;
    #1;
    `CHECK(key_beep_req, "event_valid maps directly to key_beep_req");

    clear_inputs();
    sale_error_req = 1'b1;
    #1;
    `CHECK(error_beep_req, "sale error contributes to error_beep_req");
    clear_inputs();
    auth_error_req = 1'b1;
    #1;
    `CHECK(error_beep_req, "auth error contributes to error_beep_req");
    clear_inputs();
    admin_error_req = 1'b1;
    #1;
    `CHECK(error_beep_req, "admin error contributes to error_beep_req");

    clear_inputs();
    sale_total_add_req = 1'b1;
    #1;
    `CHECK(success_beep_req, "sale_total_add_req contributes to success_beep_req");
    clear_inputs();
    auth_ok = 1'b1;
    #1;
    `CHECK(success_beep_req, "auth_ok contributes to success_beep_req");
    clear_inputs();
    admin_set_price_req = 1'b1;
    #1;
    `CHECK(success_beep_req, "admin_set_price_req contributes to success_beep_req");
    clear_inputs();
    admin_add_stock_req = 1'b1;
    #1;
    `CHECK(success_beep_req, "admin_add_stock_req contributes to success_beep_req");
    clear_inputs();
    admin_toggle_enable_req = 1'b1;
    #1;
    `CHECK(success_beep_req, "admin_toggle_enable_req contributes to success_beep_req");

    clear_inputs();
    tick_1s       = 1'b1;
    sale_state    = `SALE_STATE_WAIT_TAKE;
    remaining_sec = 3'd5;
    #1;
    `CHECK(countdown_beep_req, "countdown beeps during WAIT_TAKE with remaining time");

    clear_inputs();
    tick_1s       = 1'b1;
    sale_state    = `SALE_STATE_WAIT_TAKE;
    remaining_sec = 3'd0;
    #1;
    `CHECK(!countdown_beep_req, "countdown stays low when remaining_sec is zero");

    clear_inputs();
    tick_1s       = 1'b1;
    sale_state    = `SALE_STATE_INPUT_MONEY;
    remaining_sec = 3'd3;
    #1;
    `CHECK(!countdown_beep_req, "countdown stays low outside WAIT_TAKE");

    clear_inputs();
    alarm_mode_en = 1'b1;
    #1;
    `CHECK(alarm_active, "alarm_mode_en maps directly to alarm_active");

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
