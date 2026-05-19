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

module sale_flow_integration_tb;
  reg         clk;
  reg         rst;
  reg         mode_en;
  reg         event_valid;
  reg [2:0]   event_type;
  reg [3:0]   event_value;
  reg         tick_1s;
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
  wire [2:0]  remaining_sec;
  wire        order_timeout;
  wire        timer_running;
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

  data_manager u_data_manager (
      .clk(clk),
      .rst(rst),
      .sale_stock_dec_req(sale_stock_dec_req),
      .sale_stock_inc_req(sale_stock_inc_req),
      .sale_total_add_req(sale_total_add_req),
      .sale_item_idx(sale_item_idx),
      .sale_amount(sale_amount),
      .admin_set_price_req(1'b0),
      .admin_add_stock_req(1'b0),
      .admin_toggle_enable_req(1'b0),
      .admin_item_idx(2'd0),
      .admin_value(8'd0),
      .price0(price0),
      .price1(price1),
      .price2(price2),
      .price3(price3),
      .stock0(stock0),
      .stock1(stock1),
      .stock2(stock2),
      .stock3(stock3),
      .enabled(enabled),
      .sales_total(sales_total)
  );

  order_timer u_order_timer (
      .clk(clk),
      .rst(rst),
      .tick_1s(tick_1s),
      .start(order_timer_start),
      .stop(order_timer_stop),
      .remaining_sec(remaining_sec),
      .timeout(order_timeout),
      .running(timer_running)
  );

  sale_engine u_sale_engine (
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
      rst         = 1'b1;
      mode_en     = 1'b0;
      event_valid = 1'b0;
      event_type  = `EV_DIGIT;
      event_value = 4'd0;
      tick_1s     = 1'b0;
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

  task pulse_tick_1s;
    begin
      @(negedge clk);
      tick_1s = 1'b1;
      @(negedge clk);
      tick_1s = 1'b0;
    end
  endtask

  task complete_default_purchase_to_wait;
    input [4:0] expected_stock_after_dec;
    begin
      press_confirm();
      press_digit(4'd5);
      press_confirm();
      wait_cycles(2);
      `CHECK(stock0 == expected_stock_after_dec,
             "data_manager decrements stock0 after dispense request");
      pulse_tick_1s();
      wait_cycles(1);
      `CHECK(sale_state == `SALE_STATE_WAIT_TAKE, "paid order reaches WAIT_TAKE");
      `CHECK(timer_running, "order_timer runs in WAIT_TAKE");
      `CHECK(remaining_sec == 3'd5, "order_timer starts at 5 seconds");
    end
  endtask

  task scenario_successful_purchase;
    begin
      $display("Running scenario_successful_purchase");
      reset_dut();

      `CHECK(price0 == 8'd5, "data_manager initial price0 is 5");
      `CHECK(stock0 == 5'd5, "data_manager initial stock0 is 5");
      `CHECK(sales_total == 16'd0, "data_manager initial sales_total is 0");

      complete_default_purchase_to_wait(5'd4);
      press_confirm();
      wait_cycles(2);
      `CHECK(!timer_running, "taking item stops order timer");
      `CHECK(stock0 == 5'd4, "successful take keeps decremented stock");
      `CHECK(sales_total == 16'd5, "successful take adds latched price to sales_total");

      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "success display returns to item list");
    end
  endtask

  task scenario_timeout_refund;
    integer i;
    begin
      $display("Running scenario_timeout_refund");

      complete_default_purchase_to_wait(5'd3);
      `CHECK(stock0 == 5'd3, "second dispense decrements stock0 again");

      for (i = 0; i < 5; i = i + 1) begin
        pulse_tick_1s();
      end
      wait_cycles(2);
      `CHECK(sale_state == `SALE_STATE_TIMEOUT_REFUND, "order timeout enters refund display");
      wait_cycles(2);
      `CHECK(stock0 == 5'd4, "timeout refund restores stock0 by one");
      `CHECK(sales_total == 16'd5, "timeout refund does not add sales_total");

      pulse_tick_1s();
      `CHECK(sale_state == `SALE_STATE_SHOW_LIST, "refund display returns to item list");
    end
  endtask

  initial begin
    failures = 0;

    scenario_successful_purchase();
    scenario_timeout_refund();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
