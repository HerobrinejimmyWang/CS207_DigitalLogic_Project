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

module TopModule_basic_tb;
  localparam [4:0] UI_PAGE_MAIN_MENU      = 5'd0;
  localparam [4:0] UI_PAGE_SALE_LIST      = 5'd1;
  localparam [4:0] UI_PAGE_SALE_PAY       = 5'd2;
  localparam [4:0] UI_PAGE_SALE_WAIT_TAKE = 5'd4;
  localparam [4:0] UI_PAGE_AUTH_INPUT     = 5'd8;
  localparam [4:0] UI_PAGE_ADMIN_MENU     = 5'd12;
  localparam [4:0] UI_PAGE_ERROR          = 5'd24;

  reg         sys_clk_in;
  reg         sys_rst_n;
  tri [7:0]   exp_io;
  wire [15:0] led_pin;
  wire [7:0]  seg_cs_pin;
  wire [7:0]  seg_data_0_pin;
  wire [7:0]  seg_data_1_pin;
  wire        vga_hs_pin;
  wire        vga_vs_pin;
  wire [11:0] vga_data_pin;
  wire        audio_pwm_o;
  wire        audio_sd_o;

  integer failures;

  assign exp_io[7:4] = 4'b1111;

  TopModule dut (
      .sys_clk_in(sys_clk_in),
      .sys_rst_n(sys_rst_n),
      .exp_io(exp_io),
      .led_pin(led_pin),
      .seg_cs_pin(seg_cs_pin),
      .seg_data_0_pin(seg_data_0_pin),
      .seg_data_1_pin(seg_data_1_pin),
      .vga_hs_pin(vga_hs_pin),
      .vga_vs_pin(vga_vs_pin),
      .vga_data_pin(vga_data_pin),
      .audio_pwm_o(audio_pwm_o),
      .audio_sd_o(audio_sd_o)
  );

  initial begin
    sys_clk_in = 1'b0;
    forever #5 sys_clk_in = ~sys_clk_in;
  end

  task wait_cycles;
    input integer count;
    integer i;
    begin
      for (i = 0; i < count; i = i + 1) begin
        @(negedge sys_clk_in);
      end
    end
  endtask

  task reset_dut;
    begin
      sys_rst_n = 1'b0;
      wait_cycles(4);
      sys_rst_n = 1'b1;
      wait(dut.rst == 1'b0);
      wait_cycles(2);
    end
  endtask

  task inject_event;
    input [2:0] ev_type;
    input [3:0] ev_value;
    begin
      @(negedge sys_clk_in);
      force dut.event_valid = 1'b1;
      force dut.event_type  = ev_type;
      force dut.event_value = ev_value;
      @(negedge sys_clk_in);
      release dut.event_valid;
      release dut.event_type;
      release dut.event_value;
      @(negedge sys_clk_in);
    end
  endtask

  task pulse_tick_1s;
    begin
      @(negedge sys_clk_in);
      force dut.tick_1s = 1'b1;
      @(negedge sys_clk_in);
      release dut.tick_1s;
      @(negedge sys_clk_in);
    end
  endtask

  task enter_auth_mode;
    begin
      inject_event(`EV_DIGIT, 4'd2);
      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(2);
      `CHECK(dut.current_mode == `MODE_AUTH, "main menu confirm on 2 enters AUTH mode");
      `CHECK(dut.ui_page == UI_PAGE_AUTH_INPUT, "AUTH mode maps to auth input page");
    end
  endtask

  task auth_with_42;
    begin
      inject_event(`EV_DIGIT, 4'd4);
      inject_event(`EV_DIGIT, 4'd2);
      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(4);
    end
  endtask

  task reach_sale_wait_take_default_item;
    begin
      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(2);
      `CHECK(dut.ui_page == UI_PAGE_SALE_PAY, "sale confirm enters payment page");

      inject_event(`EV_DIGIT, 4'd5);
      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(2);
      `CHECK(dut.sale_state == `SALE_STATE_DISPENSE, "paid order enters DISPENSE");

      pulse_tick_1s();
      wait_cycles(2);
      `CHECK(dut.ui_page == UI_PAGE_SALE_WAIT_TAKE, "dispense tick advances to WAIT_TAKE");
    end
  endtask

  task scenario_auth_vga_semantics;
    begin
      $display("Running scenario_auth_vga_semantics");
      reset_dut();

      `CHECK(dut.current_mode == `MODE_MAIN_MENU, "reset returns to MAIN_MENU");
      `CHECK(dut.ui_page == UI_PAGE_MAIN_MENU, "reset shows main menu page");

      enter_auth_mode();
      inject_event(`EV_DIGIT, 4'd4);
      inject_event(`EV_DIGIT, 4'd2);
      wait_cycles(2);

      `CHECK(dut.password_value == 8'h42, "AUTH buffer stores BCD password 42");
      `CHECK(dut.ui_input_value == 16'd42, "AUTH ui_input_value converts BCD password to decimal 42");
      `CHECK(dut.u_vga_system.text_char(6'd16, 7'd24) == "P", "AUTH VGA body starts with PASSWORD");
      `CHECK(dut.u_vga_system.text_char(6'd20, 7'd45) == "4", "AUTH VGA shows tens digit 4");
      `CHECK(dut.u_vga_system.text_char(6'd20, 7'd46) == "2", "AUTH VGA shows ones digit 2");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd8) == "*", "AUTH footer advertises clear key");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd30) == "B", "AUTH footer advertises back-to-main key");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd52) == "#", "AUTH footer advertises confirm key");
    end
  endtask

  task scenario_sale_flow_and_footer;
    begin
      $display("Running scenario_sale_flow_and_footer");
      reset_dut();

      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(2);
      `CHECK(dut.current_mode == `MODE_SALE, "main menu default confirm enters SALE mode");
      `CHECK(dut.ui_page == UI_PAGE_SALE_LIST, "SALE mode starts at sale list page");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd8) == "A", "sale list footer keeps A/D browse hint");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd30) == "B", "sale list footer keeps B main-menu hint");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd52) == "#", "sale list footer keeps confirm hint");

      reach_sale_wait_take_default_item();
      `CHECK(dut.stock0 == 5'd4, "sale dispense decrements stock once");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd30) == " ", "WAIT_TAKE footer removes invalid B hint");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd52) == "#", "WAIT_TAKE footer keeps only confirm key");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd54) == "T", "WAIT_TAKE footer labels confirm as TAKE");

      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(2);
      `CHECK(dut.sale_state == `SALE_STATE_SUCCESS, "WAIT_TAKE confirm enters success state");
      `CHECK(dut.sales_total == 16'd5, "successful take adds latched price into total");

      pulse_tick_1s();
      wait_cycles(2);
      `CHECK(dut.ui_page == UI_PAGE_SALE_LIST, "success display returns to sale list");
    end
  endtask

  task scenario_admin_overlay_lock;
    begin
      $display("Running scenario_admin_overlay_lock");
      reset_dut();

      enter_auth_mode();
      auth_with_42();
      `CHECK(dut.current_mode == `MODE_ADMIN, "correct password enters ADMIN mode");
      `CHECK(dut.ui_page == UI_PAGE_ADMIN_MENU, "ADMIN mode shows admin menu");

      inject_event(`EV_DIGIT, 4'd0);
      wait_cycles(2);
      `CHECK(dut.error_active, "invalid admin digit raises generic overlay");
      `CHECK(dut.ui_page == UI_PAGE_ERROR, "generic admin invalid input uses shared error page");
      `CHECK(dut.u_vga_system.text_char(6'd22, 7'd28) == "A", "generic error page labels ADMIN context");
      `CHECK(dut.u_vga_system.text_char(6'd55, 7'd52) == " ", "error overlay clears footer action hints");

      inject_event(`EV_CONFIRM, 4'd0);
      wait_cycles(2);
      `CHECK(dut.admin_state == `ADMIN_STATE_MENU, "error overlay locks out admin menu actions");

      pulse_tick_1s();
      wait_cycles(2);
      `CHECK(!dut.error_active, "tick_1s clears shared error overlay");
      `CHECK(dut.ui_page == UI_PAGE_ADMIN_MENU, "shared error overlay returns to admin menu");
    end
  endtask

  initial begin
    failures = 0;

    scenario_auth_vga_semantics();
    scenario_sale_flow_and_footer();
    scenario_admin_overlay_lock();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
