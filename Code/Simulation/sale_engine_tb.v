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

module sale_engine_tb;
  reg         clk;
  reg         rst;
  reg         mode_en;
  reg         event_valid;
  reg [2:0]   event_type;
  reg [3:0]   event_value;
  reg         tick_1s;
  reg [7:0]   price0;
  reg [7:0]   price1;
  reg [7:0]   price2;
  reg [7:0]   price3;
  reg [4:0]   stock0;
  reg [4:0]   stock1;
  reg [4:0]   stock2;
  reg [4:0]   stock3;
  reg [3:0]   enabled;
  reg [2:0]   remaining_sec;
  reg         order_timeout;
  wire [3:0]  sale_state;
  wire [1:0]  selected_item;
  wire [7:0]  latched_price;
  wire [7:0]  paid_amount;
  wire        sale_back_req;
  wire        sale_home_req;
  wire        order_timer_start;
  wire        order_timer_stop;
  wire        sale_stock_dec_req;
  wire        sale_stock_inc_req;
  wire        sale_total_add_req;
  wire [1:0]  sale_item_idx;
  wire [7:0]  sale_amount;
  wire        error_req;
  wire [3:0]  error_code;
  wire        beep_req;

  integer failures;

  sale_engine dut (
      .clk(clk),
      .rst(rst),
      .mode_en(mode_en),
      .event_valid(event_valid),
      .event_type(event_type),
      .event_value(event_value),
      .tick_1s(tick_1s),
      .price0(price0),
      .price1(price1),
      .price2(price2),
      .price3(price3),
      .stock0(stock0),
      .stock1(stock1),
      .stock2(stock2),
      .stock3(stock3),
      .enabled(enabled),
      .remaining_sec(remaining_sec),
      .order_timeout(order_timeout),
      .sale_state(sale_state),
      .selected_item(selected_item),
      .latched_price(latched_price),
      .paid_amount(paid_amount),
      .sale_back_req(sale_back_req),
      .sale_home_req(sale_home_req),
      .order_timer_start(order_timer_start),
      .order_timer_stop(order_timer_stop),
      .sale_stock_dec_req(sale_stock_dec_req),
      .sale_stock_inc_req(sale_stock_inc_req),
      .sale_total_add_req(sale_total_add_req),
      .sale_item_idx(sale_item_idx),
      .sale_amount(sale_amount),
      .error_req(error_req),
      .error_code(error_code),
      .beep_req(beep_req)
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
      rst           = 1'b1;
      mode_en       = 1'b0;
      event_valid   = 1'b0;
      event_type    = `EV_DIGIT;
      event_value   = 4'd0;
      tick_1s       = 1'b0;
      price0        = 8'd5;
      price1        = 8'd6;
      price2        = 8'd7;
      price3        = 8'd3;
      stock0        = 5'd5;
      stock1        = 5'd5;
      stock2        = 5'd5;
      stock3        = 5'd5;
      enabled       = 4'b1111;
      remaining_sec = 3'd0;
      order_timeout = 1'b0;
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);
      mode_en = 1'b1;
      wait_cycles(2);
    end
  endtask

  task drive_event;
    input [2:0] ev_type;
    input [3:0] ev_value;
    begin
      @(negedge clk);
      event_valid = 1'b1;
      event_type  = ev_type;
      event_value = ev_value;
      @(negedge clk);
      event_valid = 1'b0;
      event_type  = `EV_DIGIT;
      event_value = 4'd0;
    end
  endtask

  task press_digit;
    input [3:0] digit;
    begin
      drive_event(`EV_DIGIT, digit);
    end
  endtask

  task press_confirm;
    begin
      drive_event(`EV_CONFIRM, 4'd0);
    end
  endtask

  task press_clear;
    begin
      drive_event(`EV_CLEAR, 4'd0);
    end
  endtask

  task press_prev;
    begin
      drive_event(`EV_PREV, 4'd0);
    end
  endtask

  task press_next;
    begin
      drive_event(`EV_NEXT, 4'd0);
    end
  endtask

  task press_back;
    begin
      drive_event(`EV_BACK, 4'd0);
    end
  endtask

  task press_home;
    begin
      drive_event(`EV_HOME, 4'd0);
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

  task pulse_order_timeout;
    begin
      @(negedge clk);
      order_timeout = 1'b1;
      @(negedge clk);
      order_timeout = 1'b0;
    end
  endtask

  task reach_input_money_default_item;
    begin
      press_confirm();
      `CHECK(sale_state == `SALE_STATE_INPUT_MONEY, "confirm on default item enters INPUT_MONEY");
      `CHECK(latched_price == price0, "sale_engine latches selected item price");
    end
  endtask

  task reach_wait_take_with_default_item;
    begin
      reach_input_money_default_item();
      press_digit(4'd5);
      press_confirm();
      `CHECK(sale_stock_dec_req, "paid order requests stock decrement");
      `CHECK(sale_state == `SALE_STATE_DISPENSE, "paid order enters DISPENSE");
      press_home();
      `CHECK(sale_state == `SALE_STATE_DISPENSE, "DISPENSE silently ignores HOME");
      pulse_tick_1s();
      `CHECK(order_timer_start, "DISPENSE starts order timer after tick_1s");
      `CHECK(sale_state == `SALE_STATE_WAIT_TAKE, "DISPENSE advances to WAIT_TAKE");
    end
  endtask

  task scenario_selection_and_invalid_input;
    begin
      $display("Running scenario_selection_and_invalid_input");
      reset_dut();

      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "reset/enabled sale starts at SHOW_LIST");
      `CHECK(selected_item == 2'd0, "default selected item is item 0");

      press_digit(4'd3);
      `CHECK(selected_item == 2'd2, "digit 3 selects item index 2 without entering payment");
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "digit selection still requires confirm");

      press_confirm();
      `CHECK(sale_state == `SALE_STATE_INPUT_MONEY, "confirm enters INPUT_MONEY after digit selection");
      `CHECK(latched_price == 8'd7, "item 3 latches price2");

      press_back();
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "B in payment returns to item list");

      press_digit(4'd0);
      `CHECK(error_req, "digit 0 in item list raises invalid input");
      `CHECK(error_code == `ERR_INVALID_INPUT, "digit 0 reports ERR_INVALID_INPUT");
      `CHECK(sale_state == `SALE_STATE_ERROR_DISPLAY, "invalid input enters error display");
      press_digit(4'd4);
      `CHECK(selected_item == 2'd2, "error display ignores new item digits");
      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "error display returns to item list after tick");
    end
  endtask

  task scenario_item_error_paths;
    begin
      $display("Running scenario_item_error_paths");
      reset_dut();

      enabled[0] = 1'b0;
      press_confirm();
      `CHECK(error_req, "disabled item raises error_req");
      `CHECK(error_code == `ERR_ITEM_OFF, "disabled item reports ERR_ITEM_OFF");
      pulse_tick_1s();

      enabled[0] = 1'b1;
      stock0 = 5'd0;
      press_confirm();
      `CHECK(error_req, "empty item raises error_req");
      `CHECK(error_code == `ERR_NO_STOCK, "empty item reports ERR_NO_STOCK");
      pulse_tick_1s();
    end
  endtask

  task scenario_payment_and_take_success;
    begin
      $display("Running scenario_payment_and_take_success");
      reset_dut();

      reach_wait_take_with_default_item();
      press_next();
      `CHECK(sale_state == `SALE_STATE_WAIT_TAKE, "WAIT_TAKE silently ignores NEXT");
      `CHECK(!sale_home_req && !sale_back_req, "WAIT_TAKE does not raise navigation requests for ignored keys");

      press_confirm();
      `CHECK(sale_total_add_req, "confirm in WAIT_TAKE requests sales total add");
      `CHECK(order_timer_stop, "confirm in WAIT_TAKE stops order timer");
      `CHECK(sale_state == `SALE_STATE_SUCCESS, "confirm in WAIT_TAKE enters SUCCESS");
      `CHECK(sale_item_idx == 2'd0, "sale item index stays on purchased item");
      `CHECK(sale_amount == 8'd5, "sale amount forwards latched price");

      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "SUCCESS returns to item list after tick");
      `CHECK(paid_amount == 8'd0, "SUCCESS clears paid amount on return");
      `CHECK(latched_price == 8'd0, "SUCCESS clears latched price on return");
    end
  endtask

  task scenario_payment_errors_and_timeout;
    begin
      $display("Running scenario_payment_errors_and_timeout");
      reset_dut();

      reach_input_money_default_item();
      press_digit(4'd4);
      press_confirm();
      `CHECK(error_req, "underpayment raises error_req");
      `CHECK(error_code == `ERR_NOT_ENOUGH, "underpayment reports ERR_NOT_ENOUGH");
      `CHECK(sale_state == `SALE_STATE_ERROR_DISPLAY, "underpayment enters error display");
      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_INPUT_MONEY, "underpayment returns to payment page");
      `CHECK(paid_amount == 8'd4, "underpayment preserves current paid amount");

      press_clear();
      `CHECK(paid_amount == 8'd0, "clear resets paid amount");
      press_digit(4'd2);
      press_digit(4'd5);
      press_digit(4'd6);
      `CHECK(error_req, "amount overflow raises invalid input");
      `CHECK(error_code == `ERR_INVALID_INPUT, "amount overflow reports ERR_INVALID_INPUT");
      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_INPUT_MONEY, "amount overflow returns to payment page");

      press_clear();
      press_digit(4'd5);
      press_confirm();
      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_WAIT_TAKE, "second paid order reaches WAIT_TAKE");

      pulse_order_timeout();
      `CHECK(sale_stock_inc_req, "timeout requests stock increment");
      `CHECK(order_timer_stop, "timeout stops order timer");
      `CHECK(!sale_total_add_req, "timeout does not add sales total");
      `CHECK(sale_state == `SALE_STATE_TIMEOUT_REFUND, "timeout enters refund display");

      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "refund display returns to item list");
    end
  endtask

  task scenario_navigation_requests;
    begin
      $display("Running scenario_navigation_requests");
      reset_dut();

      press_next();
      `CHECK(selected_item == 2'd1, "D moves to next item");
      press_prev();
      `CHECK(selected_item == 2'd0, "A moves to previous item");
      press_back();
      `CHECK(sale_back_req, "B in item list raises sale_back_req");
      press_home();
      `CHECK(sale_home_req, "C in item list raises sale_home_req");

      reach_input_money_default_item();
      press_home();
      `CHECK(sale_home_req, "C in payment raises sale_home_req");
      `CHECK(paid_amount == 8'd0, "home from payment clears paid amount");
    end
  endtask

  initial begin
    failures = 0;

    scenario_selection_and_invalid_input();
    scenario_item_error_paths();
    scenario_payment_and_take_success();
    scenario_payment_errors_and_timeout();
    scenario_navigation_requests();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
