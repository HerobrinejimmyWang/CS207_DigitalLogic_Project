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
  localparam [2:0] EV_DIGIT      = `EV_DIGIT;
  localparam [2:0] EV_PREV       = `EV_PREV;
  localparam [2:0] EV_BACK       = `EV_BACK;
  localparam [2:0] EV_HOME       = `EV_HOME;
  localparam [2:0] EV_NEXT       = `EV_NEXT;
  localparam [2:0] EV_CLEAR      = `EV_CLEAR;
  localparam [2:0] EV_CONFIRM    = `EV_CONFIRM;
  localparam [2:0] AUTH_STATE_INPUT = `AUTH_STATE_INPUT;
  localparam [3:0] ADMIN_MENU       = `ADMIN_STATE_MENU;
  localparam [3:0] VIEW_ITEMS       = `ADMIN_STATE_VIEW_ITEMS;
  localparam [3:0] SET_PRICE_SELECT_ITEM = `ADMIN_STATE_SET_PRICE_SELECT_ITEM;
  localparam [3:0] SET_PRICE_INPUT       = `ADMIN_STATE_SET_PRICE_INPUT;
  localparam [3:0] SET_PRICE_SUCCESS     = `ADMIN_STATE_SET_PRICE_SUCCESS;
  localparam [3:0] ADD_STOCK_SELECT_ITEM = `ADMIN_STATE_ADD_STOCK_SELECT_ITEM;
  localparam [3:0] ADD_STOCK_INPUT       = `ADMIN_STATE_ADD_STOCK_INPUT;
  localparam [3:0] ADD_STOCK_SUCCESS     = `ADMIN_STATE_ADD_STOCK_SUCCESS;
  localparam [3:0] TOGGLE_SELECT_ITEM    = `ADMIN_STATE_TOGGLE_SELECT_ITEM;
  localparam [3:0] TOGGLE_SUCCESS        = `ADMIN_STATE_TOGGLE_SUCCESS;
  localparam [3:0] ERR_INVALID_INPUT     = `ERR_INVALID_INPUT;
  localparam [3:0] ERR_WRONG_PASSWORD    = `ERR_WRONG_PASSWORD;

  reg         clk;
  reg         rst;
  reg         auth_mode_en;
  reg         admin_mode_en;
  reg         event_valid;
  reg [2:0]   event_type;
  reg [3:0]   event_value;
  reg         tick_1s;

  wire [2:0]  auth_state;
  wire [3:0]  admin_state;
  wire [7:0]  password_value;
  wire [1:0]  wrong_count;
  wire [2:0]  selected_func;
  wire [1:0]  selected_item;
  wire [7:0]  input_value;
  wire [7:0]  price0;
  wire [7:0]  price1;
  wire [7:0]  price2;
  wire [7:0]  price3;
  wire [4:0]  stock0;
  wire [4:0]  stock1;
  wire [4:0]  stock2;
  wire [4:0]  stock3;
  wire [3:0]  enabled;
  wire [15:0] sales_total;
  wire [15:0] buffer_current_value;
  wire [3:0]  buffer_digit_count;
  wire        buffer_input_nonempty;
  wire        buffer_input_done;
  wire        buffer_input_error;
  wire        auth_ok;
  wire        auth_back_req;
  wire        auth_home_req;
  wire        alarm_trigger;
  wire        admin_back_req;
  wire        admin_home_req;
  wire        admin_set_price_req;
  wire        admin_add_stock_req;
  wire        admin_toggle_enable_req;
  wire [1:0]  admin_item_idx;
  wire [7:0]  admin_value;
  wire        auth_error_req;
  wire [3:0]  auth_error_code;
  wire        admin_error_req;
  wire [3:0]  admin_error_code;

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

  task pulse_tick_1s;
    begin
      @(negedge clk);
      tick_1s = 1'b1;
      @(negedge clk);
      tick_1s = 1'b0;
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
      event_type  = EV_DIGIT;
      event_value = 4'd0;
    end
  endtask

  task press_digit;
    input [3:0] digit;
    begin
      drive_event(EV_DIGIT, digit);
    end
  endtask

  task press_confirm;
    begin
      drive_event(EV_CONFIRM, 4'd0);
    end
  endtask

  task press_clear;
    begin
      drive_event(EV_CLEAR, 4'd0);
    end
  endtask

  task press_prev;
    begin
      drive_event(EV_PREV, 4'd0);
    end
  endtask

  task press_next;
    begin
      drive_event(EV_NEXT, 4'd0);
    end
  endtask

  task press_back;
    begin
      drive_event(EV_BACK, 4'd0);
    end
  endtask

  task press_home;
    begin
      drive_event(EV_HOME, 4'd0);
    end
  endtask

  task reset_dut;
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

  task enter_auth_mode;
    begin
      auth_mode_en = 1'b1;
      admin_mode_en = 1'b0;
      repeat (2) @(negedge clk);
    end
  endtask

  task switch_to_admin_mode;
    begin
      auth_mode_en = 1'b0;
      admin_mode_en = 1'b1;
      repeat (2) @(negedge clk);
    end
  endtask

  task wait_for_auth_ok;
    integer i;
    reg     seen;
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

  task auth_with_password;
    input [3:0] d1;
    input [3:0] d2;
    begin
      press_digit(d1);
      press_digit(d2);
      press_confirm;
      repeat (2) @(negedge clk);
    end
  endtask

  task reach_admin_mode;
    begin
      enter_auth_mode;
      auth_with_password(4'd4, 4'd2);
      wait_for_auth_ok();
      switch_to_admin_mode();
      `CHECK(admin_state == ADMIN_MENU, "admin session starts at ADMIN_MENU");
    end
  endtask

  task scenario_auth_success;
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

  task scenario_auth_alarm;
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

  task scenario_admin_menu_and_returns;
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

  task scenario_set_price_success;
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

  task scenario_add_stock_saturation;
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

  task scenario_toggle_and_view_navigation;
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

  task scenario_invalid_input_and_buffer_clear;
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
