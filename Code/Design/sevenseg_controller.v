`timescale 1ns / 1ps

module sevenseg_controller (
    input               clk,
    input               rst,
    input               tick_1ms,
    input       [4:0]   ui_page,
    input       [15:0]  ui_input_value,
    input       [2:0]   ui_countdown,
    input       [3:0]   ui_error_code,
    input               ui_alarm_active,
    input       [127:0] ui_data_bus,
    output reg  [7:0]   seg_cs_pin,
    output reg  [7:0]   seg_data_0_pin,
    output reg  [7:0]   seg_data_1_pin
);

    localparam [4:0] UI_PAGE_MAIN_MENU          = 5'd0;
    localparam [4:0] UI_PAGE_SALE_LIST          = 5'd1;
    localparam [4:0] UI_PAGE_SALE_PAY           = 5'd2;
    localparam [4:0] UI_PAGE_SALE_DISPENSE      = 5'd3;
    localparam [4:0] UI_PAGE_SALE_WAIT_TAKE     = 5'd4;
    localparam [4:0] UI_PAGE_SALE_SUCCESS       = 5'd5;
    localparam [4:0] UI_PAGE_SALE_TIMEOUT       = 5'd6;
    localparam [4:0] UI_PAGE_SALE_ERROR         = 5'd7;
    localparam [4:0] UI_PAGE_AUTH_INPUT         = 5'd8;
    localparam [4:0] UI_PAGE_AUTH_FAIL          = 5'd9;
    localparam [4:0] UI_PAGE_AUTH_SUCCESS       = 5'd10;
    localparam [4:0] UI_PAGE_AUTH_ERROR         = 5'd11;
    localparam [4:0] UI_PAGE_ADMIN_MENU         = 5'd12;
    localparam [4:0] UI_PAGE_ADMIN_VIEW         = 5'd13;
    localparam [4:0] UI_PAGE_ADMIN_PRICE_SELECT = 5'd14;
    localparam [4:0] UI_PAGE_ADMIN_PRICE_INPUT  = 5'd15;
    localparam [4:0] UI_PAGE_ADMIN_PRICE_OK     = 5'd16;
    localparam [4:0] UI_PAGE_ADMIN_STOCK_SELECT = 5'd17;
    localparam [4:0] UI_PAGE_ADMIN_STOCK_INPUT  = 5'd18;
    localparam [4:0] UI_PAGE_ADMIN_STOCK_OK     = 5'd19;
    localparam [4:0] UI_PAGE_ADMIN_TOGGLE       = 5'd20;
    localparam [4:0] UI_PAGE_ADMIN_TOGGLE_OK    = 5'd21;
    localparam [4:0] UI_PAGE_ADMIN_TOTAL        = 5'd22;
    localparam [4:0] UI_PAGE_ALARM              = 5'd23;
    localparam [4:0] UI_PAGE_ERROR              = 5'd24;

    reg [2:0]  scan_idx;
    reg [63:0] top_row_chars;
    reg [63:0] bottom_row_chars;

    wire [1:0] selected_item   = ui_data_bus[9:8];
    wire [2:0] selected_menu   = ui_data_bus[12:10];
    wire [7:0] price0          = ui_data_bus[44:37];
    wire [7:0] price1          = ui_data_bus[52:45];
    wire [7:0] price2          = ui_data_bus[60:53];
    wire [7:0] price3          = ui_data_bus[68:61];
    wire [4:0] stock0          = ui_data_bus[73:69];
    wire [4:0] stock1          = ui_data_bus[78:74];
    wire [4:0] stock2          = ui_data_bus[83:79];
    wire [4:0] stock3          = ui_data_bus[88:84];
    wire [3:0] enabled         = ui_data_bus[92:89];
    wire [15:0] sales_total    = ui_data_bus[108:93];

    reg [7:0] selected_price;
    reg [4:0] selected_stock;
    reg       selected_enabled;

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

    function [7:0] item_char;
        input [1:0] item_idx;
        begin
            item_char = ascii_digit({2'd0, item_idx} + 4'd1);
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

    always @(*) begin
        case (selected_item)
            2'd0: begin
                selected_price   = price0;
                selected_stock   = stock0;
                selected_enabled = enabled[0];
            end
            2'd1: begin
                selected_price   = price1;
                selected_stock   = stock1;
                selected_enabled = enabled[1];
            end
            2'd2: begin
                selected_price   = price2;
                selected_stock   = stock2;
                selected_enabled = enabled[2];
            end
            default: begin
                selected_price   = price3;
                selected_stock   = stock3;
                selected_enabled = enabled[3];
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_idx <= 3'd0;
        end else if (tick_1ms) begin
            scan_idx <= scan_idx + 3'd1;
        end
    end

    always @(*) begin
        top_row_chars    = {" "," "," "," "," "," "," "," "};
        bottom_row_chars = {" "," "," "," "," "," "," "," "};

        if (ui_alarm_active || (ui_page == UI_PAGE_ALARM)) begin
            top_row_chars    = {"A","L","A","R","M"," "," "," "};
            bottom_row_chars = {"C","O","D","E","0","0","0","1"};
        end else begin
            case (ui_page)
                UI_PAGE_MAIN_MENU: begin
                    top_row_chars = (selected_menu == 3'd2)
                                  ? {"A","U","T","H"," "," "," "," "}
                                  : {"S","A","L","E"," "," "," "," "};
                    bottom_row_chars = {"S","E","L",
                                        digit4_char({13'd0, selected_menu}, 2'd0),
                                        digit4_char({13'd0, selected_menu}, 2'd1),
                                        digit4_char({13'd0, selected_menu}, 2'd2),
                                        digit4_char({13'd0, selected_menu}, 2'd3),
                                        " "};
                end

                UI_PAGE_SALE_LIST,
                UI_PAGE_ADMIN_VIEW: begin
                    top_row_chars = {"I","T","E","M",
                                     item_char(selected_item),
                                     "O",
                                     selected_enabled ? "N" : "F",
                                     selected_enabled ? " " : "F"};
                    bottom_row_chars = {"P",
                                        digit3_char({2'd0, selected_price}, 2'd0),
                                        digit3_char({2'd0, selected_price}, 2'd1),
                                        digit3_char({2'd0, selected_price}, 2'd2),
                                        "S",
                                        digit3_char({5'd0, selected_stock}, 2'd0),
                                        digit3_char({5'd0, selected_stock}, 2'd1),
                                        digit3_char({5'd0, selected_stock}, 2'd2)};
                end

                UI_PAGE_SALE_PAY: begin
                    top_row_chars = {"P","A","Y"," ",
                                     digit4_char(ui_input_value, 2'd0),
                                     digit4_char(ui_input_value, 2'd1),
                                     digit4_char(ui_input_value, 2'd2),
                                     digit4_char(ui_input_value, 2'd3)};
                    bottom_row_chars = {"P","R","C"," ",
                                        digit4_char({8'd0, selected_price}, 2'd0),
                                        digit4_char({8'd0, selected_price}, 2'd1),
                                        digit4_char({8'd0, selected_price}, 2'd2),
                                        digit4_char({8'd0, selected_price}, 2'd3)};
                end

                UI_PAGE_SALE_DISPENSE: begin
                    top_row_chars = {"O","U","T","I","0","0","0", item_char(selected_item)};
                    bottom_row_chars = {"P","R","C"," ",
                                        digit4_char({8'd0, selected_price}, 2'd0),
                                        digit4_char({8'd0, selected_price}, 2'd1),
                                        digit4_char({8'd0, selected_price}, 2'd2),
                                        digit4_char({8'd0, selected_price}, 2'd3)};
                end

                UI_PAGE_SALE_WAIT_TAKE: begin
                    top_row_chars = {"T","A","K","E",
                                     digit4_char({13'd0, ui_countdown}, 2'd0),
                                     digit4_char({13'd0, ui_countdown}, 2'd1),
                                     digit4_char({13'd0, ui_countdown}, 2'd2),
                                     digit4_char({13'd0, ui_countdown}, 2'd3)};
                    bottom_row_chars = {"I","T","E","M",
                                        item_char(selected_item),
                                        "O",
                                        selected_enabled ? "N" : "F",
                                        selected_enabled ? " " : "F"};
                end

                UI_PAGE_SALE_SUCCESS: begin
                    top_row_chars = {"D","O","N","E"," "," "," "," "};
                    bottom_row_chars = {"P","A","I","D",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3)};
                end

                UI_PAGE_SALE_TIMEOUT: begin
                    top_row_chars = {"R","E","F","U","N","D"," "," "};
                    bottom_row_chars = {"R","T","N"," ",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3)};
                end

                UI_PAGE_AUTH_INPUT: begin
                    top_row_chars = {"P","A","S","S"," "," "," "," "};
                    bottom_row_chars = {"I","N"," ",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3),
                                        " "};
                end

                UI_PAGE_AUTH_SUCCESS: begin
                    top_row_chars    = {"P","A","S","S"," ","O","K"," "};
                    bottom_row_chars = {" "," "," "," "," "," "," "," "};
                end

                UI_PAGE_ADMIN_MENU: begin
                    case (selected_menu)
                        3'd1: top_row_chars = {"V","I","E","W"," "," "," "," "};
                        3'd2: top_row_chars = {"P","R","I","C","E"," "," "," "};
                        3'd3: top_row_chars = {"S","T","O","C","K"," "," "," "};
                        3'd4: top_row_chars = {"T","O","G","G","L","E"," "," "};
                        3'd5: top_row_chars = {"T","O","T","A","L"," "," "," "};
                        default: top_row_chars = {" "," "," "," "," "," "," "," "};
                    endcase
                    bottom_row_chars = {"S","E","L",
                                        digit4_char({13'd0, selected_menu}, 2'd0),
                                        digit4_char({13'd0, selected_menu}, 2'd1),
                                        digit4_char({13'd0, selected_menu}, 2'd2),
                                        digit4_char({13'd0, selected_menu}, 2'd3),
                                        " "};
                end

                UI_PAGE_ADMIN_PRICE_SELECT,
                UI_PAGE_ADMIN_PRICE_INPUT: begin
                    top_row_chars = {"P","R","I","C","E","0","0", item_char(selected_item)};
                    bottom_row_chars = (ui_page == UI_PAGE_ADMIN_PRICE_INPUT)
                                     ? {"N","E","W"," ",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3)}
                                     : {"P",
                                        digit3_char({2'd0, selected_price}, 2'd0),
                                        digit3_char({2'd0, selected_price}, 2'd1),
                                        digit3_char({2'd0, selected_price}, 2'd2),
                                        "S",
                                        digit3_char({5'd0, selected_stock}, 2'd0),
                                        digit3_char({5'd0, selected_stock}, 2'd1),
                                        digit3_char({5'd0, selected_stock}, 2'd2)};
                end

                UI_PAGE_ADMIN_PRICE_OK: begin
                    top_row_chars = {"U","P","D"," ","O","K"," "," "};
                    bottom_row_chars = {"N","E","W"," ",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3)};
                end

                UI_PAGE_ADMIN_STOCK_SELECT,
                UI_PAGE_ADMIN_STOCK_INPUT: begin
                    top_row_chars = {"S","T","O","C","0","0","0", item_char(selected_item)};
                    bottom_row_chars = (ui_page == UI_PAGE_ADMIN_STOCK_INPUT)
                                     ? {"A","D","D"," ",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3)}
                                     : {"P",
                                        digit3_char({2'd0, selected_price}, 2'd0),
                                        digit3_char({2'd0, selected_price}, 2'd1),
                                        digit3_char({2'd0, selected_price}, 2'd2),
                                        "S",
                                        digit3_char({5'd0, selected_stock}, 2'd0),
                                        digit3_char({5'd0, selected_stock}, 2'd1),
                                        digit3_char({5'd0, selected_stock}, 2'd2)};
                end

                UI_PAGE_ADMIN_STOCK_OK: begin
                    top_row_chars = {"A","D","D"," ","O","K"," "," "};
                    bottom_row_chars = {"A","D","D"," ",
                                        digit4_char(ui_input_value, 2'd0),
                                        digit4_char(ui_input_value, 2'd1),
                                        digit4_char(ui_input_value, 2'd2),
                                        digit4_char(ui_input_value, 2'd3)};
                end

                UI_PAGE_ADMIN_TOGGLE: begin
                    top_row_chars = {"T","O","G","G","L","E", item_char(selected_item), " "};
                    bottom_row_chars = selected_enabled
                                     ? {"S","T","A","T","E","O","N"," "}
                                     : {"S","T","A","T","E","O","F","F"};
                end

                UI_PAGE_ADMIN_TOGGLE_OK: begin
                    top_row_chars = {"T","O","G"," ","O","K"," "," "};
                    bottom_row_chars = selected_enabled
                                     ? {"S","T","A","T","E","O","N"," "}
                                     : {"S","T","A","T","E","O","F","F"};
                end

                UI_PAGE_ADMIN_TOTAL: begin
                    top_row_chars = {"T","O","T","A","L"," "," "," "};
                    bottom_row_chars = {" "," "," ",
                                        digit5_char_blanked(sales_total, 3'd0),
                                        digit5_char_blanked(sales_total, 3'd1),
                                        digit5_char_blanked(sales_total, 3'd2),
                                        digit5_char_blanked(sales_total, 3'd3),
                                        digit5_char_blanked(sales_total, 3'd4)};
                end

                UI_PAGE_SALE_ERROR: begin
                    top_row_chars = {"E","R","R"," ",
                                     digit4_char({12'd0, ui_error_code}, 2'd0),
                                     digit4_char({12'd0, ui_error_code}, 2'd1),
                                     digit4_char({12'd0, ui_error_code}, 2'd2),
                                     digit4_char({12'd0, ui_error_code}, 2'd3)};
                    bottom_row_chars = {"S","A","L","E"," "," "," "," "};
                end

                UI_PAGE_AUTH_FAIL,
                UI_PAGE_AUTH_ERROR: begin
                    top_row_chars = {"E","R","R"," ",
                                     digit4_char({12'd0, ui_error_code}, 2'd0),
                                     digit4_char({12'd0, ui_error_code}, 2'd1),
                                     digit4_char({12'd0, ui_error_code}, 2'd2),
                                     digit4_char({12'd0, ui_error_code}, 2'd3)};
                    bottom_row_chars = {"A","U","T","H"," "," "," "," "};
                end

                UI_PAGE_ERROR: begin
                    top_row_chars = {"E","R","R"," ",
                                     digit4_char({12'd0, ui_error_code}, 2'd0),
                                     digit4_char({12'd0, ui_error_code}, 2'd1),
                                     digit4_char({12'd0, ui_error_code}, 2'd2),
                                     digit4_char({12'd0, ui_error_code}, 2'd3)};
                    bottom_row_chars = {"M","A","I","N"," "," "," "," "};
                end

                default: begin
                    top_row_chars    = {" "," "," "," "," "," "," "," "};
                    bottom_row_chars = {" "," "," "," "," "," "," "," "};
                end
            endcase
        end
    end

    always @(*) begin
        seg_cs_pin     = 8'b0000_0001 << scan_idx;
        seg_data_0_pin = seg_encode(char_at(top_row_chars, scan_idx));
        seg_data_1_pin = seg_encode(char_at(bottom_row_chars, scan_idx));
    end

endmodule
