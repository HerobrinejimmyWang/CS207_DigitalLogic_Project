`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module vga_system (
    input              clk,
    input              rst,
    input              pix_en,
    input      [4:0]   ui_page,
    input      [127:0] ui_data_bus,
    output reg         vga_hsync,
    output reg         vga_vsync,
    output reg [3:0]   vga_r,
    output reg [3:0]   vga_g,
    output reg [3:0]   vga_b
);

    localparam H_VISIBLE = 10'd640;
    localparam H_FRONT   = 10'd16;
    localparam H_SYNC    = 10'd96;
    localparam H_TOTAL   = 10'd800;
    localparam V_VISIBLE = 10'd480;
    localparam V_FRONT   = 10'd10;
    localparam V_SYNC    = 10'd2;
    localparam V_TOTAL   = 10'd525;

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

    localparam [7:0] WORD_VENDING  = 8'd0;
    localparam [7:0] WORD_MACHINE  = 8'd1;
    localparam [7:0] WORD_MAIN     = 8'd2;
    localparam [7:0] WORD_MENU     = 8'd3;
    localparam [7:0] WORD_SALE     = 8'd4;
    localparam [7:0] WORD_ADMIN    = 8'd5;
    localparam [7:0] WORD_ITEM     = 8'd6;
    localparam [7:0] WORD_PRICE    = 8'd7;
    localparam [7:0] WORD_STOCK    = 8'd8;
    localparam [7:0] WORD_ON       = 8'd9;
    localparam [7:0] WORD_OFF      = 8'd10;
    localparam [7:0] WORD_PAY      = 8'd11;
    localparam [7:0] WORD_PAID     = 8'd12;
    localparam [7:0] WORD_TAKE     = 8'd13;
    localparam [7:0] WORD_SEC      = 8'd14;
    localparam [7:0] WORD_DISPENSE = 8'd15;
    localparam [7:0] WORD_SUCCESS  = 8'd16;
    localparam [7:0] WORD_REFUND   = 8'd17;
    localparam [7:0] WORD_AUTH     = 8'd18;
    localparam [7:0] WORD_PASSWORD = 8'd19;
    localparam [7:0] WORD_WRONG    = 8'd20;
    localparam [7:0] WORD_ERROR    = 8'd21;
    localparam [7:0] WORD_ALARM    = 8'd22;
    localparam [7:0] WORD_VIEW     = 8'd23;
    localparam [7:0] WORD_SET      = 8'd24;
    localparam [7:0] WORD_ADD      = 8'd25;
    localparam [7:0] WORD_TOGGLE   = 8'd26;
    localparam [7:0] WORD_TOTAL    = 8'd27;
    localparam [7:0] WORD_INPUT    = 8'd28;
    localparam [7:0] WORD_OK       = 8'd29;
    localparam [7:0] WORD_WAIT     = 8'd30;
    localparam [7:0] WORD_COLA     = 8'd31;
    localparam [7:0] WORD_TEA      = 8'd32;
    localparam [7:0] WORD_JUICE    = 8'd33;
    localparam [7:0] WORD_WATER    = 8'd34;

    reg  [9:0] h_count;
    reg  [9:0] v_count;
    reg  [3:0] next_r;
    reg  [3:0] next_g;
    reg  [3:0] next_b;

    wire        visible       = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    wire [6:0]  char_col      = h_count[9:3];
    wire [5:0]  char_row      = v_count[8:3];
    wire [2:0]  glyph_x       = h_count[2:0];
    wire [2:0]  glyph_y       = v_count[2:0];
    wire [7:0]  current_char  = text_char(char_row, char_col);
    wire [7:0]  glyph_bits    = font_row(current_char, glyph_y);
    wire        text_pixel    = glyph_bits[3'd7 - glyph_x];
    wire        header_band   = visible && (v_count < 10'd56);
    wire        footer_band   = visible && (v_count >= 10'd440);
    wire        active_error  = (ui_page == UI_PAGE_ERROR) ||
                                (ui_page == UI_PAGE_SALE_ERROR) ||
                                (ui_page == UI_PAGE_AUTH_FAIL) ||
                                (ui_page == UI_PAGE_AUTH_ERROR);
    wire        active_alarm  = ui_data_bus[36] || (ui_page == UI_PAGE_ALARM);

    wire [1:0]  selected_item = ui_data_bus[9:8];
    wire [2:0]  selected_menu = ui_data_bus[12:10];
    wire [15:0] input_value   = ui_data_bus[28:13];
    wire [3:0]  error_code    = ui_data_bus[32:29];
    wire [2:0]  countdown     = ui_data_bus[35:33];
    wire [7:0]  price0        = ui_data_bus[44:37];
    wire [7:0]  price1        = ui_data_bus[52:45];
    wire [7:0]  price2        = ui_data_bus[60:53];
    wire [7:0]  price3        = ui_data_bus[68:61];
    wire [4:0]  stock0        = ui_data_bus[73:69];
    wire [4:0]  stock1        = ui_data_bus[78:74];
    wire [4:0]  stock2        = ui_data_bus[83:79];
    wire [4:0]  stock3        = ui_data_bus[88:84];
    wire [3:0]  enabled       = ui_data_bus[92:89];
    wire [15:0] sales_total   = ui_data_bus[108:93];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count   <= 10'd0;
            v_count   <= 10'd0;
            vga_hsync <= 1'b1;
            vga_vsync <= 1'b1;
            vga_r     <= 4'd0;
            vga_g     <= 4'd0;
            vga_b     <= 4'd0;
        end else if (pix_en) begin
            if (h_count == H_TOTAL - 10'd1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 10'd1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 10'd1;
                end
            end else begin
                h_count <= h_count + 10'd1;
            end

            vga_hsync <= ~((h_count >= H_VISIBLE + H_FRONT) &&
                           (h_count <  H_VISIBLE + H_FRONT + H_SYNC));
            vga_vsync <= ~((v_count >= V_VISIBLE + V_FRONT) &&
                           (v_count <  V_VISIBLE + V_FRONT + V_SYNC));
            vga_r <= next_r;
            vga_g <= next_g;
            vga_b <= next_b;
        end
    end

    always @(*) begin
        next_r = 4'h0;
        next_g = 4'h1;
        next_b = 4'h2;

        if (!visible) begin
            next_r = 4'h0;
            next_g = 4'h0;
            next_b = 4'h0;
        end else begin
            if (header_band) begin
                next_r = active_alarm ? 4'h5 : 4'h0;
                next_g = active_error ? 4'h1 : 4'h2;
                next_b = active_error ? 4'h1 : 4'h4;
            end else if (footer_band) begin
                next_r = 4'h1;
                next_g = 4'h1;
                next_b = 4'h1;
            end

            if (text_pixel) begin
                if (active_alarm) begin
                    next_r = 4'hf;
                    next_g = 4'h4;
                    next_b = 4'h1;
                end else if (active_error) begin
                    next_r = 4'hf;
                    next_g = 4'hd;
                    next_b = 4'h4;
                end else if (char_row < 6'd7) begin
                    next_r = 4'hf;
                    next_g = 4'hf;
                    next_b = 4'hf;
                end else begin
                    next_r = 4'he;
                    next_g = 4'he;
                    next_b = 4'hc;
                end
            end
        end
    end

    function [7:0] word_char;
        input [7:0] word_id;
        input [4:0] pos;
        reg [8*16-1:0] text;
        begin
            case (word_id)
                WORD_VENDING:  text = "VENDING         ";
                WORD_MACHINE:  text = "MACHINE         ";
                WORD_MAIN:     text = "MAIN            ";
                WORD_MENU:     text = "MENU            ";
                WORD_SALE:     text = "SALE            ";
                WORD_ADMIN:    text = "ADMIN           ";
                WORD_ITEM:     text = "ITEM            ";
                WORD_PRICE:    text = "PRICE           ";
                WORD_STOCK:    text = "STOCK           ";
                WORD_ON:       text = "ON              ";
                WORD_OFF:      text = "OFF             ";
                WORD_PAY:      text = "PAY             ";
                WORD_PAID:     text = "PAID            ";
                WORD_TAKE:     text = "TAKE            ";
                WORD_SEC:      text = "SEC             ";
                WORD_DISPENSE: text = "DISPENSE        ";
                WORD_SUCCESS:  text = "SUCCESS         ";
                WORD_REFUND:   text = "REFUND          ";
                WORD_AUTH:     text = "AUTH            ";
                WORD_PASSWORD: text = "PASSWORD        ";
                WORD_WRONG:    text = "WRONG           ";
                WORD_ERROR:    text = "ERROR           ";
                WORD_ALARM:    text = "ALARM           ";
                WORD_VIEW:     text = "VIEW            ";
                WORD_SET:      text = "SET             ";
                WORD_ADD:      text = "ADD             ";
                WORD_TOGGLE:   text = "TOGGLE          ";
                WORD_TOTAL:    text = "TOTAL           ";
                WORD_INPUT:    text = "INPUT           ";
                WORD_OK:       text = "OK              ";
                WORD_WAIT:     text = "WAIT            ";
                WORD_COLA:     text = "COLA            ";
                WORD_TEA:      text = "TEA             ";
                WORD_JUICE:    text = "JUICE           ";
                WORD_WATER:    text = "WATER           ";
                default:       text = "                ";
            endcase
            word_char = text[(15 - pos) * 8 +: 8];
        end
    endfunction

    function [7:0] item_char;
        input [1:0] item_id;
        input [4:0] pos;
        begin
            case (item_id)
                2'd0: item_char = word_char(WORD_COLA, pos);
                2'd1: item_char = word_char(WORD_TEA, pos);
                2'd2: item_char = word_char(WORD_JUICE, pos);
                default: item_char = word_char(WORD_WATER, pos);
            endcase
        end
    endfunction

    function [7:0] error_detail_char;
        input [3:0] error_value;
        input [4:0] pos;
        reg [8*16-1:0] text;
        begin
            case (error_value)
                `ERR_INVALID_INPUT:  text = "INPUT ERROR     ";
                `ERR_WRONG_PASSWORD: text = "PASSWORD ERROR  ";
                `ERR_ITEM_OFF:       text = "ITEM OFF ERROR  ";
                `ERR_NO_STOCK:       text = "NO STOCK ERROR  ";
                `ERR_NOT_ENOUGH:     text = "PAYMENT ERROR   ";
                default:             text = "UNKNOWN ERROR   ";
            endcase
            error_detail_char = text[(15 - pos) * 8 +: 8];
        end
    endfunction

    function [7:0] dec3_char;
        input [15:0] value;
        input [1:0]  pos;
        reg [15:0] bounded;
        reg [3:0] digit;
        begin
            bounded = (value > 16'd999) ? 16'd999 : value;
            case (pos)
                2'd0: digit = bounded / 16'd100;
                2'd1: digit = (bounded / 16'd10) % 16'd10;
                default: digit = bounded % 16'd10;
            endcase
            if ((pos == 2'd0) && (digit == 4'd0)) begin
                dec3_char = " ";
            end else if ((pos == 2'd1) && (bounded < 16'd10)) begin
                dec3_char = " ";
            end else begin
                dec3_char = "0" + digit;
            end
        end
    endfunction

    function [7:0] dec5_char;
        input [15:0] value;
        input [2:0]  pos;
        reg [15:0] divisor;
        reg [3:0] digit;
        begin
            case (pos)
                3'd0: divisor = 16'd10000;
                3'd1: divisor = 16'd1000;
                3'd2: divisor = 16'd100;
                3'd3: divisor = 16'd10;
                default: divisor = 16'd1;
            endcase
            digit = (value / divisor) % 16'd10;
            if (((pos == 3'd0) && (value < 16'd10000)) ||
                ((pos == 3'd1) && (value < 16'd1000)) ||
                ((pos == 3'd2) && (value < 16'd100)) ||
                ((pos == 3'd3) && (value < 16'd10))) begin
                dec5_char = " ";
            end else begin
                dec5_char = "0" + digit;
            end
        end
    endfunction

    function [7:0] page_name_char;
        input [4:0] page_id;
        input [4:0] pos;
        begin
            case (page_id)
                UI_PAGE_MAIN_MENU:          page_name_char = (pos < 5'd8) ? word_char(WORD_MAIN, pos) : word_char(WORD_MENU, pos - 5'd8);
                UI_PAGE_SALE_LIST:          page_name_char = (pos < 5'd8) ? word_char(WORD_SALE, pos) : word_char(WORD_ITEM, pos - 5'd8);
                UI_PAGE_SALE_PAY:           page_name_char = (pos < 5'd8) ? word_char(WORD_PAY, pos) : word_char(WORD_INPUT, pos - 5'd8);
                UI_PAGE_SALE_DISPENSE:      page_name_char = word_char(WORD_DISPENSE, pos);
                UI_PAGE_SALE_WAIT_TAKE:     page_name_char = (pos < 5'd8) ? word_char(WORD_WAIT, pos) : word_char(WORD_TAKE, pos - 5'd8);
                UI_PAGE_SALE_SUCCESS:       page_name_char = word_char(WORD_SUCCESS, pos);
                UI_PAGE_SALE_TIMEOUT:       page_name_char = word_char(WORD_REFUND, pos);
                UI_PAGE_AUTH_INPUT:         page_name_char = word_char(WORD_AUTH, pos);
                UI_PAGE_AUTH_FAIL:          page_name_char = (pos < 5'd8) ? word_char(WORD_WRONG, pos) : word_char(WORD_PASSWORD, pos - 5'd8);
                UI_PAGE_AUTH_SUCCESS:       page_name_char = (pos < 5'd8) ? word_char(WORD_AUTH, pos) : word_char(WORD_OK, pos - 5'd8);
                UI_PAGE_ADMIN_MENU:         page_name_char = (pos < 5'd8) ? word_char(WORD_ADMIN, pos) : word_char(WORD_MENU, pos - 5'd8);
                UI_PAGE_ADMIN_VIEW:         page_name_char = (pos < 5'd8) ? word_char(WORD_VIEW, pos) : word_char(WORD_ITEM, pos - 5'd8);
                UI_PAGE_ADMIN_PRICE_SELECT: page_name_char = (pos < 5'd8) ? word_char(WORD_SET, pos) : word_char(WORD_PRICE, pos - 5'd8);
                UI_PAGE_ADMIN_PRICE_INPUT:  page_name_char = (pos < 5'd8) ? word_char(WORD_PRICE, pos) : word_char(WORD_INPUT, pos - 5'd8);
                UI_PAGE_ADMIN_PRICE_OK:     page_name_char = (pos < 5'd8) ? word_char(WORD_PRICE, pos) : word_char(WORD_OK, pos - 5'd8);
                UI_PAGE_ADMIN_STOCK_SELECT: page_name_char = (pos < 5'd8) ? word_char(WORD_ADD, pos) : word_char(WORD_STOCK, pos - 5'd8);
                UI_PAGE_ADMIN_STOCK_INPUT:  page_name_char = (pos < 5'd8) ? word_char(WORD_STOCK, pos) : word_char(WORD_INPUT, pos - 5'd8);
                UI_PAGE_ADMIN_STOCK_OK:     page_name_char = (pos < 5'd8) ? word_char(WORD_STOCK, pos) : word_char(WORD_OK, pos - 5'd8);
                UI_PAGE_ADMIN_TOGGLE:       page_name_char = word_char(WORD_TOGGLE, pos);
                UI_PAGE_ADMIN_TOGGLE_OK:    page_name_char = (pos < 5'd8) ? word_char(WORD_TOGGLE, pos) : word_char(WORD_OK, pos - 5'd8);
                UI_PAGE_ADMIN_TOTAL:        page_name_char = (pos < 5'd8) ? word_char(WORD_VIEW, pos) : word_char(WORD_TOTAL, pos - 5'd8);
                UI_PAGE_ALARM:              page_name_char = word_char(WORD_ALARM, pos);
                default:                    page_name_char = word_char(WORD_ERROR, pos);
            endcase
        end
    endfunction

    function [7:0] item_line_char;
        input [5:0] row;
        input [6:0] col;
        input [1:0] item_id;
        input [7:0] price;
        input [4:0] stock;
        input       item_enabled;
        reg [5:0] line_row;
        begin
            line_row = 6'd14 + {3'd0, item_id, 1'b0};
            item_line_char = " ";
            if (row == line_row) begin
                if (col == 7'd8) begin
                    item_line_char = (selected_item == item_id) ? ">" : " ";
                end else if (col == 7'd10) begin
                    item_line_char = "1" + item_id;
                end else if ((col >= 7'd13) && (col < 7'd29)) begin
                    item_line_char = item_char(item_id, col - 7'd13);
                end else if (col == 7'd32) begin
                    item_line_char = "P";
                end else if (col == 7'd33) begin
                    item_line_char = ":";
                end else if ((col >= 7'd35) && (col < 7'd38)) begin
                    item_line_char = dec3_char({8'd0, price}, col - 7'd35);
                end else if (col == 7'd42) begin
                    item_line_char = "S";
                end else if (col == 7'd43) begin
                    item_line_char = ":";
                end else if ((col >= 7'd45) && (col < 7'd48)) begin
                    item_line_char = dec3_char({11'd0, stock}, col - 7'd45);
                end else if ((col >= 7'd52) && (col < 7'd68)) begin
                    item_line_char = item_enabled ? word_char(WORD_ON, col - 7'd52)
                                                  : word_char(WORD_OFF, col - 7'd52);
                end
            end
        end
    endfunction

    function [7:0] footer_char;
        input [4:0] page_id;
        input [6:0] col;
        begin
            footer_char = " ";

            case (page_id)
                UI_PAGE_MAIN_MENU: begin
                    if (col == 7'd8) begin
                        footer_char = "A";
                    end else if (col == 7'd9) begin
                        footer_char = "/";
                    end else if (col == 7'd10) begin
                        footer_char = "D";
                    end else if ((col >= 7'd12) && (col < 7'd28)) begin
                        footer_char = word_char(WORD_MENU, col - 7'd12);
                    end else if (col == 7'd30) begin
                        footer_char = "1";
                    end else if (col == 7'd31) begin
                        footer_char = "/";
                    end else if (col == 7'd32) begin
                        footer_char = "2";
                    end else if (col == 7'd34) begin
                        footer_char = "S";
                    end else if (col == 7'd35) begin
                        footer_char = "E";
                    end else if (col == 7'd36) begin
                        footer_char = "L";
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_SALE_LIST: begin
                    if (col == 7'd8) begin
                        footer_char = "A";
                    end else if (col == 7'd9) begin
                        footer_char = "/";
                    end else if (col == 7'd10) begin
                        footer_char = "D";
                    end else if ((col >= 7'd12) && (col < 7'd28)) begin
                        footer_char = word_char(WORD_ITEM, col - 7'd12);
                    end else if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_MAIN, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_SALE_PAY: begin
                    if (col == 7'd8) begin
                        footer_char = "*";
                    end else if (col == 7'd10) begin
                        footer_char = "C";
                    end else if (col == 7'd11) begin
                        footer_char = "L";
                    end else if (col == 7'd12) begin
                        footer_char = "R";
                    end else if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_ITEM, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_SALE_WAIT_TAKE: begin
                    if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_TAKE, col - 7'd54);
                    end
                end

                UI_PAGE_AUTH_INPUT: begin
                    if (col == 7'd8) begin
                        footer_char = "*";
                    end else if (col == 7'd10) begin
                        footer_char = "C";
                    end else if (col == 7'd11) begin
                        footer_char = "L";
                    end else if (col == 7'd12) begin
                        footer_char = "R";
                    end else if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_MAIN, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_ADMIN_MENU: begin
                    if (col == 7'd8) begin
                        footer_char = "A";
                    end else if (col == 7'd9) begin
                        footer_char = "/";
                    end else if (col == 7'd10) begin
                        footer_char = "D";
                    end else if ((col >= 7'd12) && (col < 7'd28)) begin
                        footer_char = word_char(WORD_MENU, col - 7'd12);
                    end else if (col == 7'd30) begin
                        footer_char = "1";
                    end else if (col == 7'd31) begin
                        footer_char = "-";
                    end else if (col == 7'd32) begin
                        footer_char = "5";
                    end else if (col == 7'd34) begin
                        footer_char = "S";
                    end else if (col == 7'd35) begin
                        footer_char = "E";
                    end else if (col == 7'd36) begin
                        footer_char = "L";
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_ADMIN_VIEW: begin
                    if (col == 7'd8) begin
                        footer_char = "A";
                    end else if (col == 7'd9) begin
                        footer_char = "/";
                    end else if (col == 7'd10) begin
                        footer_char = "D";
                    end else if ((col >= 7'd12) && (col < 7'd28)) begin
                        footer_char = word_char(WORD_ITEM, col - 7'd12);
                    end else if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_MENU, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "C";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_MAIN, col - 7'd54);
                    end
                end

                UI_PAGE_ADMIN_PRICE_SELECT,
                UI_PAGE_ADMIN_STOCK_SELECT,
                UI_PAGE_ADMIN_TOGGLE: begin
                    if (col == 7'd8) begin
                        footer_char = "A";
                    end else if (col == 7'd9) begin
                        footer_char = "/";
                    end else if (col == 7'd10) begin
                        footer_char = "D";
                    end else if ((col >= 7'd12) && (col < 7'd28)) begin
                        footer_char = word_char(WORD_ITEM, col - 7'd12);
                    end else if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_MENU, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_ADMIN_PRICE_INPUT,
                UI_PAGE_ADMIN_STOCK_INPUT: begin
                    if (col == 7'd8) begin
                        footer_char = "*";
                    end else if (col == 7'd10) begin
                        footer_char = "C";
                    end else if (col == 7'd11) begin
                        footer_char = "L";
                    end else if (col == 7'd12) begin
                        footer_char = "R";
                    end else if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_ITEM, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "#";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_OK, col - 7'd54);
                    end
                end

                UI_PAGE_ADMIN_TOTAL: begin
                    if (col == 7'd30) begin
                        footer_char = "B";
                    end else if ((col >= 7'd32) && (col < 7'd48)) begin
                        footer_char = word_char(WORD_MENU, col - 7'd32);
                    end else if (col == 7'd52) begin
                        footer_char = "C";
                    end else if ((col >= 7'd54) && (col < 7'd70)) begin
                        footer_char = word_char(WORD_MAIN, col - 7'd54);
                    end
                end

                default: begin
                    footer_char = " ";
                end
            endcase
        end
    endfunction

    function [7:0] text_char;
        input [5:0] row;
        input [6:0] col;
        reg [7:0] ch;
        begin
            ch = " ";

            if ((row == 6'd2) && (col >= 7'd24) && (col < 7'd40)) begin
                ch = word_char(WORD_VENDING, col - 7'd24);
            end else if ((row == 6'd2) && (col >= 7'd40) && (col < 7'd56)) begin
                ch = word_char(WORD_MACHINE, col - 7'd40);
            end else if ((row == 6'd5) && (col >= 7'd28) && (col < 7'd44)) begin
                ch = page_name_char(ui_page, col - 7'd28);
            end else if (row == 6'd55) begin
                ch = footer_char(ui_page, col);
            end else begin
                case (ui_page)
                    UI_PAGE_MAIN_MENU: begin
                        if (row == 6'd14) begin
                            if (col == 7'd24) ch = (selected_menu == 3'd1) ? ">" : " ";
                            if (col == 7'd27) ch = "1";
                            if ((col >= 7'd30) && (col < 7'd46)) ch = word_char(WORD_SALE, col - 7'd30);
                        end else if (row == 6'd17) begin
                            if (col == 7'd24) ch = (selected_menu == 3'd2) ? ">" : " ";
                            if (col == 7'd27) ch = "2";
                            if ((col >= 7'd30) && (col < 7'd46)) ch = word_char(WORD_ADMIN, col - 7'd30);
                        end
                    end

                    UI_PAGE_SALE_LIST,
                    UI_PAGE_ADMIN_VIEW,
                    UI_PAGE_ADMIN_PRICE_SELECT,
                    UI_PAGE_ADMIN_STOCK_SELECT,
                    UI_PAGE_ADMIN_TOGGLE: begin
                        ch = item_line_char(row, col, 2'd0, price0, stock0, enabled[0]);
                        if (ch == " ") ch = item_line_char(row, col, 2'd1, price1, stock1, enabled[1]);
                        if (ch == " ") ch = item_line_char(row, col, 2'd2, price2, stock2, enabled[2]);
                        if (ch == " ") ch = item_line_char(row, col, 2'd3, price3, stock3, enabled[3]);
                    end

                    UI_PAGE_SALE_PAY,
                    UI_PAGE_ADMIN_PRICE_INPUT,
                    UI_PAGE_ADMIN_STOCK_INPUT: begin
                        if ((row == 6'd16) && (col >= 7'd24) && (col < 7'd40)) begin
                            ch = word_char(WORD_INPUT, col - 7'd24);
                        end else if ((row == 6'd16) && (col >= 7'd42) && (col < 7'd47)) begin
                            ch = dec5_char(input_value, col - 7'd42);
                        end else if ((row == 6'd20) && (col >= 7'd24) && (col < 7'd40)) begin
                            ch = word_char(WORD_ITEM, col - 7'd24);
                        end else if ((row == 6'd20) && (col >= 7'd42) && (col < 7'd58)) begin
                            ch = item_char(selected_item, col - 7'd42);
                        end
                    end

                    UI_PAGE_AUTH_INPUT: begin
                        if ((row == 6'd16) && (col >= 7'd24) && (col < 7'd40)) begin
                            ch = word_char(WORD_PASSWORD, col - 7'd24);
                        end else if ((row == 6'd20) && (col >= 7'd24) && (col < 7'd40)) begin
                            ch = word_char(WORD_INPUT, col - 7'd24);
                        end else if ((row == 6'd20) && (col >= 7'd42) && (col < 7'd47)) begin
                            ch = dec5_char(input_value, col - 7'd42);
                        end
                    end

                    UI_PAGE_SALE_WAIT_TAKE: begin
                        if ((row == 6'd16) && (col >= 7'd24) && (col < 7'd40)) ch = word_char(WORD_TAKE, col - 7'd24);
                        if ((row == 6'd18) && (col >= 7'd24) && (col < 7'd40)) ch = word_char(WORD_SEC, col - 7'd24);
                        if (row == 6'd18 && col == 7'd42) ch = "0" + countdown;
                    end

                    UI_PAGE_ADMIN_MENU: begin
                        if (row == 6'd12) begin
                            if (col == 7'd20) ch = (selected_menu == 3'd1) ? ">" : " ";
                            if (col == 7'd23) ch = "1";
                            if ((col >= 7'd26) && (col < 7'd42)) ch = word_char(WORD_VIEW, col - 7'd26);
                        end else if (row == 6'd15) begin
                            if (col == 7'd20) ch = (selected_menu == 3'd2) ? ">" : " ";
                            if (col == 7'd23) ch = "2";
                            if ((col >= 7'd26) && (col < 7'd42)) ch = word_char(WORD_SET, col - 7'd26);
                            if ((col >= 7'd34) && (col < 7'd50)) ch = word_char(WORD_PRICE, col - 7'd34);
                        end else if (row == 6'd18) begin
                            if (col == 7'd20) ch = (selected_menu == 3'd3) ? ">" : " ";
                            if (col == 7'd23) ch = "3";
                            if ((col >= 7'd26) && (col < 7'd42)) ch = word_char(WORD_ADD, col - 7'd26);
                            if ((col >= 7'd34) && (col < 7'd50)) ch = word_char(WORD_STOCK, col - 7'd34);
                        end else if (row == 6'd21) begin
                            if (col == 7'd20) ch = (selected_menu == 3'd4) ? ">" : " ";
                            if (col == 7'd23) ch = "4";
                            if ((col >= 7'd26) && (col < 7'd42)) ch = word_char(WORD_TOGGLE, col - 7'd26);
                        end else if (row == 6'd24) begin
                            if (col == 7'd20) ch = (selected_menu == 3'd5) ? ">" : " ";
                            if (col == 7'd23) ch = "5";
                            if ((col >= 7'd26) && (col < 7'd42)) ch = word_char(WORD_TOTAL, col - 7'd26);
                        end
                    end

                    UI_PAGE_ADMIN_TOTAL: begin
                        if ((row == 6'd16) && (col >= 7'd24) && (col < 7'd40)) ch = word_char(WORD_TOTAL, col - 7'd24);
                        if ((row == 6'd16) && (col >= 7'd42) && (col < 7'd47)) ch = dec5_char(sales_total, col - 7'd42);
                    end

                    UI_PAGE_SALE_DISPENSE,
                    UI_PAGE_SALE_SUCCESS,
                    UI_PAGE_SALE_TIMEOUT,
                    UI_PAGE_ADMIN_PRICE_OK,
                    UI_PAGE_ADMIN_STOCK_OK,
                    UI_PAGE_ADMIN_TOGGLE_OK,
                    UI_PAGE_AUTH_SUCCESS: begin
                        if ((row == 6'd18) && (col >= 7'd30) && (col < 7'd46)) ch = page_name_char(ui_page, col - 7'd30);
                    end

                    UI_PAGE_ERROR,
                    UI_PAGE_SALE_ERROR,
                    UI_PAGE_AUTH_FAIL,
                    UI_PAGE_AUTH_ERROR: begin
                        if ((row == 6'd16) && (col >= 7'd28) && (col < 7'd44)) ch = word_char(WORD_ERROR, col - 7'd28);
                        if ((row == 6'd19) && (col >= 7'd28) && (col < 7'd32)) ch = "C";
                        if (row == 6'd19 && col == 7'd32) ch = "O";
                        if (row == 6'd19 && col == 7'd33) ch = "D";
                        if (row == 6'd19 && col == 7'd34) ch = "E";
                        if (row == 6'd19 && col == 7'd36) ch = dec3_char({12'd0, error_code}, 2'd2);
                        if ((row == 6'd22) &&
                            (col >= 7'd28) &&
                            (col < 7'd44)) begin
                            ch = error_detail_char(error_code, col - 7'd28);
                        end
                    end

                    UI_PAGE_ALARM: begin
                        if ((row == 6'd17) && (col >= 7'd30) && (col < 7'd46)) ch = word_char(WORD_ALARM, col - 7'd30);
                        if ((row == 6'd20) && (col >= 7'd26) && (col < 7'd42)) ch = word_char(WORD_PASSWORD, col - 7'd26);
                        if ((row == 6'd20) && (col >= 7'd38) && (col < 7'd54)) ch = word_char(WORD_ERROR, col - 7'd38);
                    end

                    default: ;
                endcase
            end

            text_char = ch;
        end
    endfunction

    function [7:0] font_row;
        input [7:0] ch;
        input [2:0] row;
        begin
            font_row = 8'h00;
            case (ch)
                "0": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h6e; 3'd3: font_row=8'h76; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "1": case (row) 3'd0: font_row=8'h18; 3'd1: font_row=8'h38; 3'd2: font_row=8'h18; 3'd3: font_row=8'h18; 3'd4: font_row=8'h18; 3'd5: font_row=8'h18; 3'd6: font_row=8'h7e; default: font_row=8'h00; endcase
                "2": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h06; 3'd3: font_row=8'h1c; 3'd4: font_row=8'h30; 3'd5: font_row=8'h60; 3'd6: font_row=8'h7e; default: font_row=8'h00; endcase
                "3": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h06; 3'd3: font_row=8'h1c; 3'd4: font_row=8'h06; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "4": case (row) 3'd0: font_row=8'h0c; 3'd1: font_row=8'h1c; 3'd2: font_row=8'h3c; 3'd3: font_row=8'h6c; 3'd4: font_row=8'h7e; 3'd5: font_row=8'h0c; 3'd6: font_row=8'h0c; default: font_row=8'h00; endcase
                "5": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h60; 3'd2: font_row=8'h7c; 3'd3: font_row=8'h06; 3'd4: font_row=8'h06; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "6": case (row) 3'd0: font_row=8'h1c; 3'd1: font_row=8'h30; 3'd2: font_row=8'h60; 3'd3: font_row=8'h7c; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "7": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h06; 3'd2: font_row=8'h0c; 3'd3: font_row=8'h18; 3'd4: font_row=8'h30; 3'd5: font_row=8'h30; 3'd6: font_row=8'h30; default: font_row=8'h00; endcase
                "8": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h3c; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "9": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h3e; 3'd4: font_row=8'h06; 3'd5: font_row=8'h0c; 3'd6: font_row=8'h38; default: font_row=8'h00; endcase
                "A": case (row) 3'd0: font_row=8'h18; 3'd1: font_row=8'h24; 3'd2: font_row=8'h42; 3'd3: font_row=8'h7e; 3'd4: font_row=8'h42; 3'd5: font_row=8'h42; 3'd6: font_row=8'h42; default: font_row=8'h00; endcase
                "B": case (row) 3'd0: font_row=8'h7c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h7c; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h7c; default: font_row=8'h00; endcase
                "C": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h60; 3'd3: font_row=8'h60; 3'd4: font_row=8'h60; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "D": case (row) 3'd0: font_row=8'h78; 3'd1: font_row=8'h6c; 3'd2: font_row=8'h66; 3'd3: font_row=8'h66; 3'd4: font_row=8'h66; 3'd5: font_row=8'h6c; 3'd6: font_row=8'h78; default: font_row=8'h00; endcase
                "E": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h60; 3'd2: font_row=8'h60; 3'd3: font_row=8'h7c; 3'd4: font_row=8'h60; 3'd5: font_row=8'h60; 3'd6: font_row=8'h7e; default: font_row=8'h00; endcase
                "F": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h60; 3'd2: font_row=8'h60; 3'd3: font_row=8'h7c; 3'd4: font_row=8'h60; 3'd5: font_row=8'h60; 3'd6: font_row=8'h60; default: font_row=8'h00; endcase
                "G": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h60; 3'd3: font_row=8'h6e; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "H": case (row) 3'd0: font_row=8'h66; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h7e; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h66; default: font_row=8'h00; endcase
                "I": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h18; 3'd2: font_row=8'h18; 3'd3: font_row=8'h18; 3'd4: font_row=8'h18; 3'd5: font_row=8'h18; 3'd6: font_row=8'h7e; default: font_row=8'h00; endcase
                "J": case (row) 3'd0: font_row=8'h1e; 3'd1: font_row=8'h0c; 3'd2: font_row=8'h0c; 3'd3: font_row=8'h0c; 3'd4: font_row=8'h6c; 3'd5: font_row=8'h6c; 3'd6: font_row=8'h38; default: font_row=8'h00; endcase
                "K": case (row) 3'd0: font_row=8'h66; 3'd1: font_row=8'h6c; 3'd2: font_row=8'h78; 3'd3: font_row=8'h70; 3'd4: font_row=8'h78; 3'd5: font_row=8'h6c; 3'd6: font_row=8'h66; default: font_row=8'h00; endcase
                "L": case (row) 3'd0: font_row=8'h60; 3'd1: font_row=8'h60; 3'd2: font_row=8'h60; 3'd3: font_row=8'h60; 3'd4: font_row=8'h60; 3'd5: font_row=8'h60; 3'd6: font_row=8'h7e; default: font_row=8'h00; endcase
                "M": case (row) 3'd0: font_row=8'h42; 3'd1: font_row=8'h66; 3'd2: font_row=8'h7e; 3'd3: font_row=8'h5a; 3'd4: font_row=8'h42; 3'd5: font_row=8'h42; 3'd6: font_row=8'h42; default: font_row=8'h00; endcase
                "N": case (row) 3'd0: font_row=8'h62; 3'd1: font_row=8'h72; 3'd2: font_row=8'h7a; 3'd3: font_row=8'h5e; 3'd4: font_row=8'h4e; 3'd5: font_row=8'h46; 3'd6: font_row=8'h42; default: font_row=8'h00; endcase
                "O": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h66; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "P": case (row) 3'd0: font_row=8'h7c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h7c; 3'd4: font_row=8'h60; 3'd5: font_row=8'h60; 3'd6: font_row=8'h60; default: font_row=8'h00; endcase
                "Q": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h66; 3'd4: font_row=8'h6a; 3'd5: font_row=8'h6c; 3'd6: font_row=8'h36; default: font_row=8'h00; endcase
                "R": case (row) 3'd0: font_row=8'h7c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h7c; 3'd4: font_row=8'h78; 3'd5: font_row=8'h6c; 3'd6: font_row=8'h66; default: font_row=8'h00; endcase
                "S": case (row) 3'd0: font_row=8'h3c; 3'd1: font_row=8'h66; 3'd2: font_row=8'h60; 3'd3: font_row=8'h3c; 3'd4: font_row=8'h06; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "T": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h18; 3'd2: font_row=8'h18; 3'd3: font_row=8'h18; 3'd4: font_row=8'h18; 3'd5: font_row=8'h18; 3'd6: font_row=8'h18; default: font_row=8'h00; endcase
                "U": case (row) 3'd0: font_row=8'h66; 3'd1: font_row=8'h66; 3'd2: font_row=8'h66; 3'd3: font_row=8'h66; 3'd4: font_row=8'h66; 3'd5: font_row=8'h66; 3'd6: font_row=8'h3c; default: font_row=8'h00; endcase
                "V": case (row) 3'd0: font_row=8'h42; 3'd1: font_row=8'h42; 3'd2: font_row=8'h42; 3'd3: font_row=8'h42; 3'd4: font_row=8'h42; 3'd5: font_row=8'h24; 3'd6: font_row=8'h18; default: font_row=8'h00; endcase
                "W": case (row) 3'd0: font_row=8'h42; 3'd1: font_row=8'h42; 3'd2: font_row=8'h42; 3'd3: font_row=8'h5a; 3'd4: font_row=8'h7e; 3'd5: font_row=8'h66; 3'd6: font_row=8'h42; default: font_row=8'h00; endcase
                "X": case (row) 3'd0: font_row=8'h42; 3'd1: font_row=8'h66; 3'd2: font_row=8'h3c; 3'd3: font_row=8'h18; 3'd4: font_row=8'h3c; 3'd5: font_row=8'h66; 3'd6: font_row=8'h42; default: font_row=8'h00; endcase
                "Y": case (row) 3'd0: font_row=8'h42; 3'd1: font_row=8'h66; 3'd2: font_row=8'h3c; 3'd3: font_row=8'h18; 3'd4: font_row=8'h18; 3'd5: font_row=8'h18; 3'd6: font_row=8'h18; default: font_row=8'h00; endcase
                "Z": case (row) 3'd0: font_row=8'h7e; 3'd1: font_row=8'h06; 3'd2: font_row=8'h0c; 3'd3: font_row=8'h18; 3'd4: font_row=8'h30; 3'd5: font_row=8'h60; 3'd6: font_row=8'h7e; default: font_row=8'h00; endcase
                ":": case (row) 3'd1: font_row=8'h18; 3'd2: font_row=8'h18; 3'd4: font_row=8'h18; 3'd5: font_row=8'h18; default: font_row=8'h00; endcase
                "/": case (row) 3'd0: font_row=8'h06; 3'd1: font_row=8'h0c; 3'd2: font_row=8'h18; 3'd3: font_row=8'h30; 3'd4: font_row=8'h60; default: font_row=8'h00; endcase
                "#": case (row) 3'd1: font_row=8'h24; 3'd2: font_row=8'h7e; 3'd3: font_row=8'h24; 3'd4: font_row=8'h7e; 3'd5: font_row=8'h24; default: font_row=8'h00; endcase
                "*": case (row) 3'd1: font_row=8'h24; 3'd2: font_row=8'h18; 3'd3: font_row=8'h7e; 3'd4: font_row=8'h18; 3'd5: font_row=8'h24; default: font_row=8'h00; endcase
                ">": case (row) 3'd1: font_row=8'h40; 3'd2: font_row=8'h20; 3'd3: font_row=8'h10; 3'd4: font_row=8'h20; 3'd5: font_row=8'h40; default: font_row=8'h00; endcase
                default: font_row = 8'h00;
            endcase
        end
    endfunction

endmodule
