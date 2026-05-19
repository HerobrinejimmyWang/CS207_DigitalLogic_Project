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

module main_mode_fsm_tb;
  reg        clk;
  reg        rst;
  reg        main_select_sale;
  reg        main_select_admin;
  reg        sale_back_req;
  reg        sale_home_req;
  reg        auth_ok;
  reg        auth_back_req;
  reg        auth_home_req;
  reg        alarm_trigger;
  reg        admin_back_req;
  reg        admin_home_req;
  reg        alarm_done;
  wire [2:0] current_mode;
  wire       sale_mode_en;
  wire       auth_mode_en;
  wire       admin_mode_en;
  wire       alarm_mode_en;

  integer failures;

  main_mode_fsm dut (
      .clk(clk),
      .rst(rst),
      .main_select_sale(main_select_sale),
      .main_select_admin(main_select_admin),
      .sale_back_req(sale_back_req),
      .sale_home_req(sale_home_req),
      .auth_ok(auth_ok),
      .auth_back_req(auth_back_req),
      .auth_home_req(auth_home_req),
      .alarm_trigger(alarm_trigger),
      .admin_back_req(admin_back_req),
      .admin_home_req(admin_home_req),
      .alarm_done(alarm_done),
      .current_mode(current_mode),
      .sale_mode_en(sale_mode_en),
      .auth_mode_en(auth_mode_en),
      .admin_mode_en(admin_mode_en),
      .alarm_mode_en(alarm_mode_en)
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

  task clear_inputs;
    begin
      main_select_sale  = 1'b0;
      main_select_admin = 1'b0;
      sale_back_req     = 1'b0;
      sale_home_req     = 1'b0;
      auth_ok           = 1'b0;
      auth_back_req     = 1'b0;
      auth_home_req     = 1'b0;
      alarm_trigger     = 1'b0;
      admin_back_req    = 1'b0;
      admin_home_req    = 1'b0;
      alarm_done        = 1'b0;
    end
  endtask

  task reset_dut;
    begin
      rst = 1'b1;
      clear_inputs();
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);
    end
  endtask

  task pulse_main_select_sale;
    begin
      @(negedge clk);
      main_select_sale = 1'b1;
      @(negedge clk);
      main_select_sale = 1'b0;
    end
  endtask

  task pulse_main_select_admin;
    begin
      @(negedge clk);
      main_select_admin = 1'b1;
      @(negedge clk);
      main_select_admin = 1'b0;
    end
  endtask

  task pulse_sale_back_req;
    begin
      @(negedge clk);
      sale_back_req = 1'b1;
      @(negedge clk);
      sale_back_req = 1'b0;
    end
  endtask

  task pulse_sale_home_req;
    begin
      @(negedge clk);
      sale_home_req = 1'b1;
      @(negedge clk);
      sale_home_req = 1'b0;
    end
  endtask

  task pulse_auth_ok;
    begin
      @(negedge clk);
      auth_ok = 1'b1;
      @(negedge clk);
      auth_ok = 1'b0;
    end
  endtask

  task pulse_auth_home_req;
    begin
      @(negedge clk);
      auth_home_req = 1'b1;
      @(negedge clk);
      auth_home_req = 1'b0;
    end
  endtask

  task pulse_admin_back_req;
    begin
      @(negedge clk);
      admin_back_req = 1'b1;
      @(negedge clk);
      admin_back_req = 1'b0;
    end
  endtask

  task pulse_admin_home_req;
    begin
      @(negedge clk);
      admin_home_req = 1'b1;
      @(negedge clk);
      admin_home_req = 1'b0;
    end
  endtask

  task pulse_alarm_done;
    begin
      @(negedge clk);
      alarm_done = 1'b1;
      @(negedge clk);
      alarm_done = 1'b0;
    end
  endtask

  task scenario_sale_mode;
    begin
      $display("Running scenario_sale_mode");
      reset_dut();

      `CHECK(current_mode == `MODE_MAIN_MENU, "reset starts in MAIN_MENU");
      `CHECK(!sale_mode_en && !auth_mode_en && !admin_mode_en && !alarm_mode_en,
             "reset clears all mode enables");

      pulse_main_select_sale();
      `CHECK(current_mode == `MODE_SALE, "main_select_sale enters SALE mode");
      `CHECK(sale_mode_en, "SALE mode enable follows current_mode");

      pulse_sale_back_req();
      `CHECK(current_mode == `MODE_MAIN_MENU, "sale_back_req returns to MAIN_MENU");

      pulse_main_select_sale();
      pulse_sale_home_req();
      `CHECK(current_mode == `MODE_MAIN_MENU, "sale_home_req returns to MAIN_MENU");
    end
  endtask

  task scenario_auth_admin_alarm;
    begin
      $display("Running scenario_auth_admin_alarm");
      reset_dut();

      pulse_main_select_admin();
      `CHECK(current_mode == `MODE_AUTH, "main_select_admin enters AUTH mode");
      `CHECK(auth_mode_en, "AUTH mode enable follows current_mode");

      pulse_auth_ok();
      `CHECK(current_mode == `MODE_ADMIN, "auth_ok enters ADMIN mode");
      `CHECK(admin_mode_en, "ADMIN mode enable follows current_mode");

      pulse_admin_back_req();
      `CHECK(current_mode == `MODE_MAIN_MENU, "admin_back_req returns to MAIN_MENU");

      pulse_main_select_admin();
      pulse_auth_home_req();
      `CHECK(current_mode == `MODE_MAIN_MENU, "auth_home_req returns to MAIN_MENU");

      pulse_main_select_admin();
      @(negedge clk);
      auth_ok       = 1'b1;
      alarm_trigger = 1'b1;
      @(negedge clk);
      auth_ok       = 1'b0;
      alarm_trigger = 1'b0;
      `CHECK(current_mode == `MODE_ALARM, "alarm_trigger has priority over auth_ok");
      `CHECK(alarm_mode_en, "ALARM mode enable follows current_mode");

      pulse_admin_home_req();
      `CHECK(current_mode == `MODE_ALARM, "ALARM ignores unrelated return requests");

      pulse_alarm_done();
      `CHECK(current_mode == `MODE_MAIN_MENU, "alarm_done returns to MAIN_MENU");
    end
  endtask

  initial begin
    failures = 0;

    scenario_sale_mode();
    scenario_auth_admin_alarm();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
