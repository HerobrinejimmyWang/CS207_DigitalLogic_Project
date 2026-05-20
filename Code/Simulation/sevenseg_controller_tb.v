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

module sevenseg_controller_tb;
  reg         clk;
  reg         rst;
  reg         tick_1ms;
  reg [4:0]   ui_page;
  reg [15:0]  ui_input_value;
  reg [2:0]   ui_countdown;
  reg [3:0]   ui_error_code;
  reg         ui_alarm_active;
  reg [127:0] ui_data_bus;
  wire [7:0]  seg_cs_pin;
  wire [7:0]  seg_data_0_pin;
  wire [7:0]  seg_data_1_pin;

  reg [7:0] frame_top [0:7];
  reg [7:0] frame_bottom [0:7];

  integer failures;

  localparam [4:0] UI_PAGE_MAIN_MENU          = 5'd0;
  localparam [4:0] UI_PAGE_SALE_LIST          = 5'd1;
  localparam [4:0] UI_PAGE_SALE_PAY           = 5'd2;
  localparam [4:0] UI_PAGE_SALE_WAIT_TAKE     = 5'd4;
  localparam [4:0] UI_PAGE_AUTH_INPUT         = 5'd8;
  localparam [4:0] UI_PAGE_ADMIN_MENU         = 5'd12;
  localparam [4:0] UI_PAGE_ADMIN_PRICE_INPUT  = 5'd15;
  localparam [4:0] UI_PAGE_ADMIN_TOTAL        = 5'd22;
  localparam [4:0] UI_PAGE_ALARM              = 5'd23;
  localparam [4:0] UI_PAGE_ERROR              = 5'd24;

  sevenseg_controller dut (
      .clk(clk),
      .rst(rst),
      .tick_1ms(tick_1ms),
      .ui_page(ui_page),
      .ui_input_value(ui_input_value),
      .ui_countdown(ui_countdown),
      .ui_error_code(ui_error_code),
      .ui_alarm_active(ui_alarm_active),
      .ui_data_bus(ui_data_bus),
      .seg_cs_pin(seg_cs_pin),
      .seg_data_0_pin(seg_data_0_pin),
      .seg_data_1_pin(seg_data_1_pin)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  function [7:0] ascii_digit;
    input [3:0] value;
    begin
      case (value)
        4'd0: ascii_digit = "0";
        4'd1: ascii_digit = "1";
        4'd2: ascii_digit = "2";
        4'd3: ascii_digit = "3";
        4'd4: ascii_digit = "4";
        4'd5: ascii_digit = "5";
        4'd6: ascii_digit = "6";
        4'd7: ascii_digit = "7";
        4'd8: ascii_digit = "8";
        4'd9: ascii_digit = "9";
        default: ascii_digit = "0";
      endcase
    end
  endfunction

  function [7:0] digit3_char;
    input [9:0] value;
    input [1:0] pos;
    reg [3:0] digit;
    begin
      case (pos)
        2'd0: digit = (value / 10'd100) % 10;
        2'd1: digit = (value / 10'd10) % 10;
        default: digit = value % 10;
      endcase
      digit3_char = ascii_digit(digit);
    end
  endfunction

  function [7:0] digit4_char;
    input [15:0] value;
    input [1:0] pos;
    reg [3:0] digit;
    begin
      case (pos)
        2'd0: digit = (value / 16'd1000) % 10;
        2'd1: digit = (value / 16'd100) % 10;
        2'd2: digit = (value / 16'd10) % 10;
        default: digit = value % 10;
      endcase
      digit4_char = ascii_digit(digit);
    end
  endfunction

  function [7:0] digit5_char_blanked;
    input [15:0] value;
    input [2:0] pos;
    reg [3:0] digit;
    begin
      case (pos)
        3'd0: begin
          if (value < 16'd10000) begin
            digit5_char_blanked = " ";
          end else begin
            digit = (value / 16'd10000) % 10;
            digit5_char_blanked = ascii_digit(digit);
          end
        end
        3'd1: begin
          if (value < 16'd1000) begin
            digit5_char_blanked = " ";
          end else begin
            digit = (value / 16'd1000) % 10;
            digit5_char_blanked = ascii_digit(digit);
          end
        end
        3'd2: begin
          if (value < 16'd100) begin
            digit5_char_blanked = " ";
          end else begin
            digit = (value / 16'd100) % 10;
            digit5_char_blanked = ascii_digit(digit);
          end
        end
        3'd3: begin
          if (value < 16'd10) begin
            digit5_char_blanked = " ";
          end else begin
            digit = (value / 16'd10) % 10;
            digit5_char_blanked = ascii_digit(digit);
          end
        end
        default: begin
          digit = value % 10;
          digit5_char_blanked = ascii_digit(digit);
        end
      endcase
    end
  endfunction

  function [7:0] char_at;
    input [63:0] row_chars;
    input [2:0] idx;
    begin
      case (idx)
        3'd0: char_at = row_chars[63:56];
        3'd1: char_at = row_chars[55:48];
        3'd2: char_at = row_chars[47:40];
        3'd3: char_at = row_chars[39:32];
        3'd4: char_at = row_chars[31:24];
        3'd5: char_at = row_chars[23:16];
        3'd6: char_at = row_chars[15:8];
        default: char_at = row_chars[7:0];
      endcase
    end
  endfunction

  function [7:0] seg_encode;
    input [7:0] ch;
    begin
      case (ch)
        "0": seg_encode = 8'h3F;
        "1": seg_encode = 8'h06;
        "2": seg_encode = 8'h5B;
        "3": seg_encode = 8'h4F;
        "4": seg_encode = 8'h66;
        "5": seg_encode = 8'h6D;
        "6": seg_encode = 8'h7D;
        "7": seg_encode = 8'h07;
        "8": seg_encode = 8'h7F;
        "9": seg_encode = 8'h6F;
        "A": seg_encode = 8'h77;
        "B": seg_encode = 8'h7C;
        "C": seg_encode = 8'h39;
        "D": seg_encode = 8'h5E;
        "E": seg_encode = 8'h79;
        "F": seg_encode = 8'h71;
        "G": seg_encode = 8'h3D;
        "H": seg_encode = 8'h76;
        "I": seg_encode = 8'h30;
        "K": seg_encode = 8'h76;
        "L": seg_encode = 8'h38;
        "M": seg_encode = 8'h37;
        "N": seg_encode = 8'h54;
        "O": seg_encode = 8'h3F;
        "P": seg_encode = 8'h73;
        "R": seg_encode = 8'h50;
        "S": seg_encode = 8'h6D;
        "T": seg_encode = 8'h78;
        "U": seg_encode = 8'h3E;
        "V": seg_encode = 8'h3E;
        "W": seg_encode = 8'h2A;
        "Y": seg_encode = 8'h6E;
        "-": seg_encode = 8'h40;
        default: seg_encode = 8'h00;
      endcase
    end
  endfunction

  function integer slot_from_cs;
    input [7:0] cs;
    begin
      case (cs)
        8'b0000_0001: slot_from_cs = 0;
        8'b0000_0010: slot_from_cs = 1;
        8'b0000_0100: slot_from_cs = 2;
        8'b0000_1000: slot_from_cs = 3;
        8'b0001_0000: slot_from_cs = 4;
        8'b0010_0000: slot_from_cs = 5;
        8'b0100_0000: slot_from_cs = 6;
        8'b1000_0000: slot_from_cs = 7;
        default:      slot_from_cs = -1;
      endcase
    end
  endfunction

  task wait_cycles;
    input integer count;
    integer i;
    begin
      for (i = 0; i < count; i = i + 1) begin
        @(negedge clk);
      end
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

  task load_default_bus;
    begin
      ui_data_bus           = 128'd0;
      ui_data_bus[44:37]    = 8'd5;
      ui_data_bus[52:45]    = 8'd6;
      ui_data_bus[60:53]    = 8'd7;
      ui_data_bus[68:61]    = 8'd3;
      ui_data_bus[73:69]    = 5'd5;
      ui_data_bus[78:74]    = 5'd4;
      ui_data_bus[83:79]    = 5'd2;
      ui_data_bus[88:84]    = 5'd9;
      ui_data_bus[92:89]    = 4'b1011;
      ui_data_bus[108:93]   = 16'd12345;
      ui_data_bus[9:8]      = 2'd0;
      ui_data_bus[12:10]    = 3'd1;
    end
  endtask

  task reset_dut;
    begin
      rst             = 1'b1;
      tick_1ms        = 1'b0;
      ui_page         = UI_PAGE_MAIN_MENU;
      ui_input_value  = 16'd0;
      ui_countdown    = 3'd0;
      ui_error_code   = 4'd0;
      ui_alarm_active = 1'b0;
      load_default_bus();
      wait_cycles(3);
      rst = 1'b0;
      wait_cycles(2);
    end
  endtask

  task capture_frame;
    integer i;
    integer slot;
    reg [7:0] seen_mask;
    begin
      seen_mask = 8'h00;
      for (i = 0; i < 8; i = i + 1) begin
        slot = slot_from_cs(seg_cs_pin);
        `CHECK(slot >= 0, "seg_cs_pin is one-hot during capture");
        if (slot >= 0) begin
          frame_top[slot]    = seg_data_0_pin;
          frame_bottom[slot] = seg_data_1_pin;
          seen_mask[slot]    = 1'b1;
        end
        pulse_tick_1ms();
      end
      `CHECK(seen_mask == 8'hFF, "capture_frame visits every scan slot exactly once");
    end
  endtask

  task expect_frame;
    input [63:0] expected_top;
    input [63:0] expected_bottom;
    input [255:0] label;
    integer idx;
    begin
      for (idx = 0; idx < 8; idx = idx + 1) begin
        `CHECK(frame_top[idx] == seg_encode(char_at(expected_top, idx)), label);
        `CHECK(frame_bottom[idx] == seg_encode(char_at(expected_bottom, idx)), label);
      end
    end
  endtask

  task scenario_main_menu;
    begin
      $display("Running scenario_main_menu");
      reset_dut();

      ui_page = UI_PAGE_MAIN_MENU;
      ui_data_bus[12:10] = 3'd1;
      wait_cycles(1);
      capture_frame();
      expect_frame({"S","A","L","E"," "," "," "," "},
                   {"S","E","L","0","0","0","1"," "},
                   "main menu sale frame");

      ui_data_bus[12:10] = 3'd2;
      wait_cycles(1);
      capture_frame();
      expect_frame({"A","U","T","H"," "," "," "," "},
                   {"S","E","L","0","0","0","2"," "},
                   "main menu auth frame");
    end
  endtask

  task scenario_sale_list_and_pay;
    begin
      $display("Running scenario_sale_list_and_pay");
      reset_dut();

      ui_page = UI_PAGE_SALE_LIST;
      ui_data_bus[9:8]   = 2'd2;
      wait_cycles(1);
      capture_frame();
      expect_frame({"I","T","E","M","3","O","F","F"},
                   {"P","0","0","7","S","0","0","2"},
                   "sale list frame");

      ui_page        = UI_PAGE_SALE_PAY;
      ui_input_value = 16'd123;
      wait_cycles(1);
      capture_frame();
      expect_frame({"P","A","Y"," ","0","1","2","3"},
                   {"P","R","C"," ","0","0","0","7"},
                   "sale pay frame");
    end
  endtask

  task scenario_wait_take_and_auth;
    begin
      $display("Running scenario_wait_take_and_auth");
      reset_dut();

      ui_page = UI_PAGE_SALE_WAIT_TAKE;
      ui_countdown = 3'd5;
      ui_data_bus[9:8] = 2'd0;
      wait_cycles(1);
      capture_frame();
      expect_frame({"T","A","K","E","0","0","0","5"},
                   {"I","T","E","M","1","O","N"," "},
                   "wait take frame");

      ui_page        = UI_PAGE_AUTH_INPUT;
      ui_input_value = 16'd42;
      wait_cycles(1);
      capture_frame();
      expect_frame({"P","A","S","S"," "," "," "," "},
                   {"I","N"," ","0","0","4","2"," "},
                   "auth input frame");
    end
  endtask

  task scenario_admin_pages;
    begin
      $display("Running scenario_admin_pages");
      reset_dut();

      ui_page = UI_PAGE_ADMIN_MENU;
      ui_data_bus[12:10] = 3'd4;
      wait_cycles(1);
      capture_frame();
      expect_frame({"T","O","G","G","L","E"," "," "},
                   {"S","E","L","0","0","0","4"," "},
                   "admin menu frame");

      ui_page        = UI_PAGE_ADMIN_PRICE_INPUT;
      ui_data_bus[9:8] = 2'd1;
      ui_input_value = 16'd88;
      wait_cycles(1);
      capture_frame();
      expect_frame({"P","R","I","C","E","0","0","2"},
                   {"N","E","W"," ","0","0","8","8"},
                   "admin price input frame");

      ui_page = UI_PAGE_ADMIN_TOTAL;
      ui_data_bus[108:93] = 16'd12345;
      wait_cycles(1);
      capture_frame();
      expect_frame({"T","O","T","A","L"," "," "," "},
                   {" "," "," ","1","2","3","4","5"},
                   "admin total frame");
    end
  endtask

  task scenario_error_and_alarm;
    begin
      $display("Running scenario_error_and_alarm");
      reset_dut();

      ui_page       = UI_PAGE_ERROR;
      ui_error_code = 4'd5;
      ui_data_bus[2:0] = 3'd0;
      wait_cycles(1);
      capture_frame();
      expect_frame({"E","R","R"," ","0","0","0","5"},
                   {"M","A","I","N"," "," "," "," "},
                   "main error frame");

      ui_data_bus[2:0] = 3'd3;
      wait_cycles(1);
      capture_frame();
      expect_frame({"E","R","R"," ","0","0","0","5"},
                   {"A","D","M","I","N"," "," "," "},
                   "admin error frame");

      ui_page         = UI_PAGE_ALARM;
      ui_alarm_active = 1'b1;
      wait_cycles(1);
      capture_frame();
      expect_frame({"A","L","A","R","M"," "," "," "},
                   {"C","O","D","E","0","0","0","1"},
                   "alarm frame");
    end
  endtask

  initial begin
    failures = 0;

    scenario_main_menu();
    scenario_sale_list_and_pay();
    scenario_wait_take_and_auth();
    scenario_admin_pages();
    scenario_error_and_alarm();

    if (failures == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d checks failed", failures);
    end
  end
endmodule
