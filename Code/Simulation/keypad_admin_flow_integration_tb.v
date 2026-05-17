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

module keypad_admin_flow_integration_tb;
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
  localparam [3:0] ERR_INVALID_INPUT     = `ERR_INVALID_INPUT;
  localparam [3:0] ERR_WRONG_PASSWORD    = `ERR_WRONG_PASSWORD;

  reg         clk;
  reg         rst;
  reg         auth_mode_en;
  reg         admin_mode_en;
  reg         tick_1s;
  reg         tick_1ms;
  reg         press_active;
  reg [1:0]   press_row;
  reg [1:0]   press_col;
  reg         clear_observations;
  reg [3:0]   col_in;

  wire [3:0]  row_active;
  wire        event_valid;
  wire [2:0]  event_type;
  wire [3:0]  event_value;
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

  reg         saw_event_valid;
  reg [2:0]   last_event_type;
  reg [3:0]   last_event_value;
  reg         saw_auth_ok;
  reg         saw_auth_error_req;
  reg [3:0]   last_auth_error_code;
  reg         saw_alarm_trigger;
  reg         saw_admin_back_req;
  reg         saw_admin_home_req;
  reg         saw_admin_set_price_req;
  reg         saw_admin_error_req;
  reg [3:0]   last_admin_error_code;

  integer failures;

  function [3:0] onehot_row;
    input [1:0] row;
    begin
      case (row)
        2'd0: onehot_row = 4'b0001;
        2'd1: onehot_row = 4'b0010;
        2'd2: onehot_row = 4'b0100;
        2'd3: onehot_row = 4'b1000;
        default: onehot_row = 4'b0000;
      endcase
    end
  endfunction

  keypad_event_frontend #(
      .DEBOUNCE_SAMPLES(2),
      .RELEASE_SAMPLES (2)
  ) u_keypad_event_frontend (
      .clk        (clk),
      .rst        (rst),
      .tick_1ms   (tick_1ms),
      .col_in     (col_in),
      .row_active (row_active),
      .event_valid(event_valid),
      .event_type (event_type),
      .event_value(event_value)
  );

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

  always @(*) begin
    col_in = 4'b1111;
    if (press_active && (row_active == onehot_row(press_row))) begin
      col_in[press_col] = 1'b0;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      saw_event_valid        <= 1'b0;
      last_event_type        <= EV_DIGIT;
      last_event_value       <= 4'd0;
      saw_auth_ok            <= 1'b0;
      saw_auth_error_req     <= 1'b0;
      last_auth_error_code   <= 4'd0;
      saw_alarm_trigger      <= 1'b0;
      saw_admin_back_req     <= 1'b0;
      saw_admin_home_req     <= 1'b0;
      saw_admin_set_price_req <= 1'b0;
      saw_admin_error_req    <= 1'b0;
      last_admin_error_code  <= 4'd0;
    end else if (clear_observations) begin
      saw_event_valid        <= 1'b0;
      last_event_type        <= EV_DIGIT;
      last_event_value       <= 4'd0;
      saw_auth_ok            <= 1'b0;
      saw_auth_error_req     <= 1'b0;
      last_auth_error_code   <= 4'd0;
      saw_alarm_trigger      <= 1'b0;
      saw_admin_back_req     <= 1'b0;
      saw_admin_home_req     <= 1'b0;
      saw_admin_set_price_req <= 1'b0;
      saw_admin_error_req    <= 1'b0;
      last_admin_error_code  <= 4'd0;
    end else begin
      if (event_valid) begin
        saw_event_valid  <= 1'b1;
        last_event_type  <= event_type;
        last_event_value <= event_value;
      end
      if (auth_ok) begin
        saw_auth_ok <= 1'b1;
      end
      if (auth_error_req) begin
        saw_auth_error_req   <= 1'b1;
        last_auth_error_code <= auth_error_code;
      end
      if (alarm_trigger) begin
        saw_alarm_trigger <= 1'b1;
      end
      if (admin_back_req) begin
        saw_admin_back_req <= 1'b1;
      end
      if (admin_home_req) begin
        saw_admin_home_req <= 1'b1;
      end
      if (admin_set_price_req) begin
        saw_admin_set_price_req <= 1'b1;
      end
      if (admin_error_req) begin
        saw_admin_error_req   <= 1'b1;
        last_admin_error_code <= admin_error_code;
      end
    end
  end

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

  task pulse_tick_1ms;
    begin
      @(negedge clk);
      tick_1ms = 1'b1;
      @(negedge clk);
      tick_1ms = 1'b0;
    end
  endtask

  task advance_ms;
    input integer count;
    integer i;
    begin
      for (i = 0; i < count; i = i + 1) begin
        pulse_tick_1ms();
      end
    end
  endtask

  task settle_cycles;
    input integer count;
    integer i;
    begin
      for (i = 0; i < count; i = i + 1) begin
        @(negedge clk);
      end
    end
  endtask

  task reset_observations;
    begin
      @(negedge clk);
      clear_observations = 1'b1;
      @(negedge clk);
      clear_observations = 1'b0;
    end
  endtask

  task press_key_rc;
    input [1:0] row;
    input [1:0] col;
    begin
      press_row    = row;
      press_col    = col;
      press_active = 1'b1;
      advance_ms(10);
      press_active = 1'b0;
      advance_ms(8);
      settle_cycles(2);
    end
  endtask

  task press_digit;
    input [3:0] digit;
    begin
      case (digit)
        4'd0: press_key_rc(2'd3, 2'd1);
        4'd1: press_key_rc(2'd0, 2'd0);
        4'd2: press_key_rc(2'd0, 2'd1);
        4'd3: press_key_rc(2'd0, 2'd2);
        4'd4: press_key_rc(2'd1, 2'd0);
        4'd5: press_key_rc(2'd1, 2'd1);
        4'd6: press_key_rc(2'd1, 2'd2);
        4'd7: press_key_rc(2'd2, 2'd0);
        4'd8: press_key_rc(2'd2, 2'd1);
        4'd9: press_key_rc(2'd2, 2'd2);
        default: begin
          failures = failures + 1;
          $display("FAIL: unsupported digit key %0d", digit);
        end
      endcase
    end
  endtask

  task press_prev;
    begin
      press_key_rc(2'd0, 2'd3);
    end
  endtask

  task press_back;
    begin
      press_key_rc(2'd1, 2'd3);
    end
  endtask

  task press_home;
    begin
      press_key_rc(2'd2, 2'd3);
    end
  endtask

  task press_next;
    begin
      press_key_rc(2'd3, 2'd3);
    end
  endtask

  task press_clear;
    begin
      press_key_rc(2'd3, 2'd0);
    end
  endtask

  task press_confirm;
    begin
      press_key_rc(2'd3, 2'd2);
    end
  endtask

  task reset_dut;
    begin
      rst                = 1'b1;
      auth_mode_en       = 1'b0;
      admin_mode_en      = 1'b0;
      tick_1s            = 1'b0;
      tick_1ms           = 1'b0;
      press_active       = 1'b0;
      press_row          = 2'd0;
      press_col          = 2'd0;
      clear_observations = 1'b0;
      repeat (3) @(negedge clk);
      rst = 1'b0;
      repeat (2) @(negedge clk);
    end
  endtask

  task enter_auth_mode;
    begin
      auth_mode_en  = 1'b1;
      admin_mode_en = 1'b0;
      settle_cycles(2);
    end
  endtask

  task switch_to_admin_mode;
    begin
      auth_mode_en  = 1'b0;
      admin_mode_en = 1'b1;
      settle_cycles(2);
    end
  endtask

  task auth_with_password;
    input [3:0] d1;
    input [3:0] d2;
    begin
      press_digit(d1);
      press_digit(d2);
      press_confirm();
      settle_cycles(2);
    end
  endtask

  task reach_admin_mode;
    begin
      enter_auth_mode();
      reset_observations();
      auth_with_password(4'd4, 4'd2);
      `CHECK(saw_auth_ok, "correct keypad password raises auth_ok");
      switch_to_admin_mode();
      `CHECK(admin_state == ADMIN_MENU, "admin session starts at ADMIN_MENU");
    end
  endtask

  task scenario_keypad_frontend_mapping;
    begin
      $display("Running scenario_keypad_frontend_mapping");
      reset_dut();

      reset_observations();
      press_digit(4'd8);
      `CHECK(saw_event_valid, "pressing 8 produces a frontend event");
      `CHECK(last_event_type == EV_DIGIT, "pressing 8 maps to EV_DIGIT");
      `CHECK(last_event_value == 4'd8, "pressing 8 maps to digit value 8");

      reset_observations();
      press_next();
      `CHECK(saw_event_valid, "pressing D produces a frontend event");
      `CHECK(last_event_type == EV_NEXT, "pressing D maps to EV_NEXT");

      reset_observations();
      press_clear();
      `CHECK(saw_event_valid, "pressing * produces a frontend event");
      `CHECK(last_event_type == EV_CLEAR, "pressing * maps to EV_CLEAR");
    end
  endtask

  task scenario_mode_switch_clears_buffer;
    begin
      $display("Running scenario_mode_switch_clears_buffer");
      reset_dut();
      enter_auth_mode();

      press_digit(4'd4);
      `CHECK(buffer_current_value == 16'd4, "auth digit reaches shared buffer through keypad frontend");
      `CHECK(buffer_digit_count == 4'd1, "auth digit increments shared buffer count");

      switch_to_admin_mode();
      `CHECK(buffer_current_value == 16'd0, "switching buffer owner clears shared buffer value");
      `CHECK(buffer_digit_count == 4'd0, "switching buffer owner clears shared buffer count");
      `CHECK(!buffer_input_nonempty, "switching buffer owner clears shared buffer nonempty flag");
    end
  endtask

  task scenario_auth_alarm_via_keypad;
    begin
      $display("Running scenario_auth_alarm_via_keypad");
      reset_dut();
      enter_auth_mode();

      reset_observations();
      auth_with_password(4'd1, 4'd1);
      `CHECK(saw_auth_error_req, "wrong keypad password raises auth_error_req");
      `CHECK(last_auth_error_code == ERR_WRONG_PASSWORD, "wrong keypad password reports ERR_WRONG_PASSWORD");
      pulse_tick_1s();

      reset_observations();
      auth_with_password(4'd1, 4'd2);
      `CHECK(wrong_count == 2'd2, "wrong_count reaches 2 after second keypad failure");
      pulse_tick_1s();

      reset_observations();
      auth_with_password(4'd1, 4'd3);
      `CHECK(saw_alarm_trigger, "third wrong keypad password raises alarm_trigger");
    end
  endtask

  task scenario_set_price_success_via_keypad;
    begin
      $display("Running scenario_set_price_success_via_keypad");
      reset_dut();
      reach_admin_mode();

      press_digit(4'd2);
      `CHECK(selected_func == 3'd2, "digit 2 selects SET PRICE through keypad frontend");
      press_confirm();
      `CHECK(admin_state == SET_PRICE_SELECT_ITEM, "confirm key enters SET_PRICE_SELECT_ITEM");

      press_digit(4'd3);
      `CHECK(selected_item == 2'd2, "digit 3 selects item index 2 through keypad frontend");
      press_confirm();
      `CHECK(admin_state == SET_PRICE_INPUT, "confirm key enters SET_PRICE_INPUT");
      `CHECK(buffer_current_value == 16'd0, "shared buffer is cleared before SET_PRICE_INPUT");

      press_digit(4'd1);
      press_digit(4'd5);
      `CHECK(input_value == 8'd15, "price digits accumulate through keypad frontend");

      reset_observations();
      press_confirm();
      `CHECK(saw_admin_set_price_req, "SET PRICE commit raises admin_set_price_req");
      `CHECK(admin_item_idx == 2'd2, "SET PRICE request targets selected item");
      `CHECK(admin_value == 8'd15, "SET PRICE request forwards value 15");
      `CHECK(price2 == 8'd15, "data_manager updates price2 to 15 after keypad flow");
      `CHECK(admin_state == SET_PRICE_SUCCESS, "SET PRICE enters success state");

      pulse_tick_1s();
      `CHECK(admin_state == SET_PRICE_SELECT_ITEM, "SET PRICE success returns after tick_1s");
    end
  endtask

  task scenario_navigation_clear_and_home_via_keypad;
    begin
      $display("Running scenario_navigation_clear_and_home_via_keypad");
      reset_dut();
      reach_admin_mode();

      press_confirm();
      `CHECK(admin_state == VIEW_ITEMS, "confirm on default menu enters VIEW_ITEMS");
      press_next();
      `CHECK(selected_item == 2'd1, "D key maps to next item navigation");
      press_prev();
      `CHECK(selected_item == 2'd0, "A key maps to previous item navigation");
      press_back();
      `CHECK(admin_state == ADMIN_MENU, "B key returns VIEW_ITEMS to ADMIN_MENU");

      press_digit(4'd2);
      press_confirm();
      press_confirm();
      `CHECK(admin_state == SET_PRICE_INPUT, "default item path reaches SET_PRICE_INPUT");

      press_digit(4'd0);
      reset_observations();
      press_confirm();
      `CHECK(saw_admin_error_req, "invalid keypad price raises admin_error_req");
      `CHECK(last_admin_error_code == ERR_INVALID_INPUT, "invalid keypad price reports ERR_INVALID_INPUT");

      press_clear();
      `CHECK(buffer_current_value == 16'd0, "* key clears the shared input buffer");

      reset_observations();
      press_home();
      `CHECK(saw_admin_home_req, "C key raises admin_home_req");
      `CHECK(buffer_current_value == 16'd0, "HOME path keeps shared input buffer cleared");
    end
  endtask

  initial begin
    failures = 0;
    reset_dut();

    scenario_keypad_frontend_mapping();
    scenario_mode_switch_clears_buffer();
    scenario_auth_alarm_via_keypad();
    scenario_set_price_success_via_keypad();
    scenario_navigation_clear_and_home_via_keypad();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
