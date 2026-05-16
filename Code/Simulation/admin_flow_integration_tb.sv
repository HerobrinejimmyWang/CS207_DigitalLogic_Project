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

module admin_flow_integration_tb;
  localparam logic [2:0] EV_DIGIT      = `EV_DIGIT;
  localparam logic [2:0] EV_PREV       = `EV_PREV;
  localparam logic [2:0] EV_BACK       = `EV_BACK;
  localparam logic [2:0] EV_HOME       = `EV_HOME;
  localparam logic [2:0] EV_NEXT       = `EV_NEXT;
  localparam logic [2:0] EV_CLEAR      = `EV_CLEAR;
  localparam logic [2:0] EV_CONFIRM    = `EV_CONFIRM;
  localparam logic [2:0] AUTH_STATE_INPUT = `AUTH_STATE_INPUT;
  localparam logic [3:0] ADMIN_MENU       = `ADMIN_STATE_MENU;
  localparam logic [3:0] VIEW_ITEMS       = `ADMIN_STATE_VIEW_ITEMS;
  localparam logic [3:0] SET_PRICE_SELECT_ITEM = `ADMIN_STATE_SET_PRICE_SELECT_ITEM;
  localparam logic [3:0] SET_PRICE_INPUT       = `ADMIN_STATE_SET_PRICE_INPUT;
  localparam logic [3:0] SET_PRICE_SUCCESS     = `ADMIN_STATE_SET_PRICE_SUCCESS;
  localparam logic [3:0] ADD_STOCK_SELECT_ITEM = `ADMIN_STATE_ADD_STOCK_SELECT_ITEM;
  localparam logic [3:0] ADD_STOCK_INPUT       = `ADMIN_STATE_ADD_STOCK_INPUT;
  localparam logic [3:0] ADD_STOCK_SUCCESS     = `ADMIN_STATE_ADD_STOCK_SUCCESS;
  localparam logic [3:0] TOGGLE_SELECT_ITEM    = `ADMIN_STATE_TOGGLE_SELECT_ITEM;
  localparam logic [3:0] TOGGLE_SUCCESS        = `ADMIN_STATE_TOGGLE_SUCCESS;
  localparam logic [3:0] ERR_INVALID_INPUT     = `ERR_INVALID_INPUT;
  localparam logic [3:0] ERR_WRONG_PASSWORD    = `ERR_WRONG_PASSWORD;

  logic        clk;
  logic        rst;
  logic        auth_mode_en;
  logic        admin_mode_en;
  logic        event_valid;
  logic [2:0]  event_type;
  logic [3:0]  event_value;
  logic        tick_1s;

  logic [2:0]  auth_state;
  logic [3:0]  admin_state;
  logic [7:0]  password_value;
  logic [1:0]  wrong_count;
  logic [2:0]  selected_func;
  logic [1:0]  selected_item;
  logic [7:0]  input_value;
  logic [7:0]  price0;
  logic [7:0]  price1;
  logic [7:0]  price2;
  logic [7:0]  price3;
  logic [4:0]  stock0;
  logic [4:0]  stock1;
  logic [4:0]  stock2;
  logic [4:0]  stock3;
  logic [3:0]  enabled;
  logic [15:0] sales_total;
  logic [15:0] buffer_current_value;
  logic [3:0]  buffer_digit_count;
  logic        buffer_input_nonempty;
  logic        buffer_input_done;
  logic        buffer_input_error;
  logic        auth_ok;
  logic        auth_back_req;
  logic        auth_home_req;
  logic        alarm_trigger;
  logic        admin_back_req;
  logic        admin_home_req;
  logic        admin_set_price_req;
  logic        admin_add_stock_req;
  logic        admin_toggle_enable_req;
  logic [1:0]  admin_item_idx;
  logic [7:0]  admin_value;
  logic        auth_error_req;
  logic [3:0]  auth_error_code;
  logic        admin_error_req;
  logic [3:0]  admin_error_code;

  integer failures;

  admin_mode_subsystem dut (
      .clk(clk),
      .rst(rst),
      .tick_1s(tick_1s),
      .auth_mode_en(auth_mode_en),
      .admin_mode_en(admin_mode_en),
      .event_valid(event_valid),
      .event_type(event_type),
      .event_value(event_value),
      .sale_stock_dec_req(1'b0),
      .sale_stock_inc_req(1'b0),
      .sale_total_add_req(1'b0),
      .sale_item_idx(2'd0),
      .sale_amount(8'd0),
      .auth_state(auth_state),
      .price0(price0),
      .price1(price1),
      .price2(price2),
      .price3(price3),
      .stock0(stock0),
      .stock1(stock1),
      .stock2(stock2),
      .stock3(stock3),
      .enabled(enabled),
      .sales_total(sales_total),
      .password_value(password_value),
      .wrong_count(wrong_count),
      .auth_ok(auth_ok),
      .auth_back_req(auth_back_req),
      .auth_home_req(auth_home_req),
      .alarm_trigger(alarm_trigger),
      .auth_error_req(auth_error_req),
      .auth_error_code(auth_error_code),
      .admin_state(admin_state),
      .selected_func(selected_func),
      .selected_item(selected_item),
      .input_value(input_value),
      .admin_back_req(admin_back_req),
      .admin_home_req(admin_home_req),
      .admin_set_price_req(admin_set_price_req),
      .admin_add_stock_req(admin_add_stock_req),
      .admin_toggle_enable_req(admin_toggle_enable_req),
      .admin_item_idx(admin_item_idx),
      .admin_value(admin_value),
      .admin_error_req(admin_error_req),
      .admin_error_code(admin_error_code),
      .buffer_current_value(buffer_current_value),
      .buffer_digit_count(buffer_digit_count),
      .buffer_input_nonempty(buffer_input_nonempty),
      .buffer_input_done(buffer_input_done),
      .buffer_input_error(buffer_input_error)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic pulse_tick_1s;
    begin
      @(negedge clk);
      tick_1s = 1'b1;
      @(negedge clk);
      tick_1s = 1'b0;
    end
  endtask

  task automatic drive_event(input logic [2:0] ev_type, input logic [3:0] ev_value);
    begin
      @(negedge clk);
      event_valid = 1'b1;
      event_type  = ev_type;
      event_value = ev_value;
      @(negedge clk);
      event_valid = 1'b0;
      event_type  = EV_DIGIT;
      event_value = 4'd0;
    end
  endtask

  task automatic press_digit(input logic [3:0] digit);
    begin
      drive_event(EV_DIGIT, digit);
    end
  endtask

  task automatic press_confirm;
    begin
      drive_event(EV_CONFIRM, 4'd0);
    end
  endtask

  task automatic press_clear;
    begin
      drive_event(EV_CLEAR, 4'd0);
    end
  endtask

  task automatic press_prev;
    begin
      drive_event(EV_PREV, 4'd0);
    end
  endtask

  task automatic press_next;
    begin
      drive_event(EV_NEXT, 4'd0);
    end
  endtask

  task automatic press_back;
    begin
      drive_event(EV_BACK, 4'd0);
    end
  endtask

  task automatic press_home;
    begin
      drive_event(EV_HOME, 4'd0);
    end
  endtask

  task automatic reset_dut;
    begin
      rst          = 1'b1;
      auth_mode_en = 1'b0;
      admin_mode_en = 1'b0;
      event_valid  = 1'b0;
      event_type   = EV_DIGIT;
      event_value  = 4'd0;
      tick_1s      = 1'b0;
      repeat (3) @(negedge clk);
      rst = 1'b0;
      repeat (2) @(negedge clk);
    end
  endtask

  task automatic enter_auth_mode;
    begin
      auth_mode_en = 1'b1;
      admin_mode_en = 1'b0;
      repeat (2) @(negedge clk);
    end
  endtask

  task automatic switch_to_admin_mode;
    begin
      auth_mode_en = 1'b0;
      admin_mode_en = 1'b1;
      repeat (2) @(negedge clk);
    end
  endtask

  task automatic wait_for_auth_ok;
    integer i;
    bit seen;
    begin
      seen = 1'b0;
      for (i = 0; i < 6; i = i + 1) begin
        @(negedge clk);
        if (auth_ok) begin
          seen = 1'b1;
        end
      end
      `CHECK(seen, "correct password raises auth_ok");
    end
  endtask

  task automatic auth_with_password(input logic [3:0] d1, input logic [3:0] d2);
    begin
      press_digit(d1);
      press_digit(d2);
      press_confirm;
      repeat (2) @(negedge clk);
    end
  endtask

  task automatic reach_admin_mode;
    begin
      enter_auth_mode;
      auth_with_password(4'd4, 4'd2);
      wait_for_auth_ok();
      switch_to_admin_mode();
      `CHECK(admin_state == ADMIN_MENU, "admin session starts at ADMIN_MENU");
    end
  endtask

  task automatic scenario_auth_success;
    begin
      $display("Running scenario_auth_success");
      reset_dut;
      enter_auth_mode;
      auth_with_password(4'd4, 4'd2);
      wait_for_auth_ok();
      `CHECK(auth_state == AUTH_STATE_INPUT, "auth state returns to input after success pulse");
      `CHECK(wrong_count == 2'd0, "wrong_count cleared on success");
    end
  endtask

  task automatic scenario_auth_alarm;
    begin
      $display("Running scenario_auth_alarm");
      reset_dut;
      enter_auth_mode;

      auth_with_password(4'd1, 4'd1);
      @(negedge clk);
      `CHECK(auth_error_req, "wrong password raises auth_error_req");
      `CHECK(auth_error_code == ERR_WRONG_PASSWORD, "wrong password reports ERR_WRONG_PASSWORD");
      pulse_tick_1s;

      auth_with_password(4'd1, 4'd2);
      @(negedge clk);
      `CHECK(wrong_count == 2'd2, "wrong_count increments to 2 after second failure");
      pulse_tick_1s;

      auth_with_password(4'd1, 4'd3);
      @(negedge clk);
      `CHECK(alarm_trigger, "third wrong password raises alarm_trigger");
      `CHECK(!admin_mode_en, "alarm path never enables admin mode in testbench");
    end
  endtask

  task automatic scenario_admin_menu_and_returns;
    begin
      $display("Running scenario_admin_menu_and_returns");
      reset_dut;
      reach_admin_mode;

      press_digit(4'd0);
      `CHECK(admin_error_req, "invalid digit in ADMIN_MENU raises admin_error_req");
      `CHECK(admin_error_code == ERR_INVALID_INPUT, "invalid digit in ADMIN_MENU uses ERR_INVALID_INPUT");

      press_digit(4'd2);
      `CHECK(selected_func == 3'd2, "digit 2 selects SET PRICE");
      press_confirm;
      `CHECK(admin_state == SET_PRICE_SELECT_ITEM, "confirm enters SET_PRICE_SELECT_ITEM");

      press_back;
      `CHECK(admin_state == ADMIN_MENU, "B from function page returns to ADMIN_MENU");
      `CHECK(!admin_back_req, "B from function page does not raise admin_back_req");

      press_back;
      `CHECK(admin_back_req, "B from ADMIN_MENU raises admin_back_req");
      admin_mode_en = 1'b0;
      repeat (2) @(negedge clk);
      `CHECK(!admin_mode_en, "admin mode closes after admin_back_req");

      reach_admin_mode;
      press_home;
      `CHECK(admin_home_req, "C from ADMIN_MENU raises admin_home_req");
      admin_mode_en = 1'b0;
      repeat (2) @(negedge clk);
      `CHECK(!admin_mode_en, "admin mode closes after admin_home_req");
    end
  endtask

  task automatic scenario_set_price_success;
    begin
      $display("Running scenario_set_price_success");
      reset_dut;
      reach_admin_mode;

      press_digit(4'd2);
      press_confirm;
      `CHECK(admin_state == SET_PRICE_SELECT_ITEM, "SET PRICE function entry works");

      press_digit(4'd3);
      `CHECK(selected_item == 2'd2, "digit 3 selects item index 2");
      press_confirm;
      `CHECK(admin_state == SET_PRICE_INPUT, "confirm enters SET_PRICE_INPUT");
      `CHECK(buffer_current_value == 16'd0, "shared buffer is cleared before SET_PRICE_INPUT");
      `CHECK(input_value == 8'd0, "admin input_value starts empty in SET_PRICE_INPUT");

      press_digit(4'd1);
      press_digit(4'd5);
      press_confirm;
      repeat (2) @(negedge clk);
      `CHECK(admin_set_price_req, "SET PRICE commit pulses admin_set_price_req");
      `CHECK(admin_item_idx == 2'd2, "SET PRICE request targets selected item");
      `CHECK(admin_value == 8'd15, "SET PRICE request forwards committed value 15");
      repeat (2) @(negedge clk);
      `CHECK(price2 == 8'd15, "data_manager updates price2 to 15");
      `CHECK(admin_state == SET_PRICE_SUCCESS, "SET PRICE enters success state");

      pulse_tick_1s;
      `CHECK(admin_state == SET_PRICE_SELECT_ITEM, "SET PRICE success returns to select item after tick_1s");
    end
  endtask

  task automatic scenario_add_stock_saturation;
    begin
      $display("Running scenario_add_stock_saturation");
      reset_dut;
      reach_admin_mode;

      press_digit(4'd3);
      press_confirm;
      `CHECK(admin_state == ADD_STOCK_SELECT_ITEM, "ADD STOCK function entry works");

      press_digit(4'd1);
      press_confirm;
      `CHECK(admin_state == ADD_STOCK_INPUT, "confirm enters ADD_STOCK_INPUT");

      press_digit(4'd1);
      press_digit(4'd5);
      press_confirm;
      repeat (2) @(negedge clk);
      `CHECK(admin_add_stock_req, "ADD STOCK commit pulses admin_add_stock_req");
      repeat (2) @(negedge clk);
      `CHECK(stock0 == 5'd15, "data_manager saturates stock0 to 15");
      `CHECK(admin_state == ADD_STOCK_SUCCESS, "ADD STOCK enters success state");

      pulse_tick_1s;
      `CHECK(admin_state == ADD_STOCK_SELECT_ITEM, "ADD STOCK success returns to select item after tick_1s");
    end
  endtask

  task automatic scenario_toggle_and_view_navigation;
    begin
      $display("Running scenario_toggle_and_view_navigation");
      reset_dut;
      reach_admin_mode;

      press_confirm;
      `CHECK(admin_state == VIEW_ITEMS, "default ADMIN_MENU selection enters VIEW_ITEMS");
      press_next;
      `CHECK(selected_item == 2'd1, "VIEW_ITEMS next navigates to item 1");
      press_prev;
      `CHECK(selected_item == 2'd0, "VIEW_ITEMS prev navigates back to item 0");
      press_digit(4'd8);
      `CHECK(admin_error_req, "digit in VIEW_ITEMS is invalid");

      press_back;
      `CHECK(admin_state == ADMIN_MENU, "VIEW_ITEMS back returns to ADMIN_MENU");

      press_digit(4'd4);
      press_confirm;
      `CHECK(admin_state == TOGGLE_SELECT_ITEM, "TOGGLE function entry works");
      press_digit(4'd4);
      press_confirm;
      `CHECK(admin_toggle_enable_req, "TOGGLE confirm pulses admin_toggle_enable_req");
      repeat (2) @(negedge clk);
      `CHECK(enabled[3] == 1'b0, "TOGGLE flips enabled[3] low");
      `CHECK(admin_state == TOGGLE_SUCCESS, "TOGGLE enters success state");

      pulse_tick_1s;
      `CHECK(admin_state == TOGGLE_SELECT_ITEM, "TOGGLE success returns to select item after tick_1s");
    end
  endtask

  task automatic scenario_invalid_input_and_buffer_clear;
    begin
      $display("Running scenario_invalid_input_and_buffer_clear");
      reset_dut;
      reach_admin_mode;

      press_digit(4'd2);
      press_confirm;
      press_confirm;
      `CHECK(admin_state == SET_PRICE_INPUT, "SET PRICE input reached using default item");

      press_prev;
      `CHECK(admin_error_req, "A in SET_PRICE_INPUT is invalid");
      `CHECK(admin_error_code == ERR_INVALID_INPUT, "A in SET_PRICE_INPUT reports ERR_INVALID_INPUT");

      press_digit(4'd0);
      press_confirm;
      repeat (2) @(negedge clk);
      `CHECK(admin_error_req, "price 0 commit is invalid");
      `CHECK(admin_error_code == ERR_INVALID_INPUT, "price 0 commit reports ERR_INVALID_INPUT");

      press_clear;
      repeat (1) @(negedge clk);
      `CHECK(buffer_current_value == 16'd0, "clear request empties shared buffer");

      press_back;
      `CHECK(admin_state == SET_PRICE_SELECT_ITEM, "B from SET_PRICE_INPUT returns to item selection");
      press_home;
      admin_mode_en = 1'b0;
      repeat (2) @(negedge clk);
      `CHECK(!admin_mode_en, "C from select item exits admin mode in testbench");
    end
  endtask

  initial begin
    failures = 0;
    reset_dut;

    scenario_auth_success();
    scenario_auth_alarm();
    scenario_admin_menu_and_returns();
    scenario_set_price_success();
    scenario_add_stock_saturation();
    scenario_toggle_and_view_navigation();
    scenario_invalid_input_and_buffer_clear();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
