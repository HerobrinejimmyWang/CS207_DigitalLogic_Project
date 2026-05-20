`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module ui_snapshot_packer (
    input       [2:0]   current_mode,
    input       [3:0]   sale_state,
    input       [3:0]   admin_state,
    input       [2:0]   auth_state,
    input       [1:0]   selected_item,
    input       [2:0]   selected_menu,
    input       [15:0]  input_value,
    input       [7:0]   price0,
    input       [7:0]   price1,
    input       [7:0]   price2,
    input       [7:0]   price3,
    input       [4:0]   stock0,
    input       [4:0]   stock1,
    input       [4:0]   stock2,
    input       [4:0]   stock3,
    input       [3:0]   enabled,
    input       [15:0]  sales_total,
    input       [2:0]   remaining_sec,
    input               error_active,
    input       [3:0]   error_code,
    input               alarm_active,
    output reg  [4:0]   ui_page,
    output reg  [2:0]   ui_mode,
    output reg  [1:0]   ui_selected_item,
    output reg  [2:0]   ui_selected_menu,
    output reg  [15:0]  ui_input_value,
    output reg  [3:0]   ui_error_code,
    output reg  [2:0]   ui_countdown,
    output reg          ui_alarm_active,
    output reg  [127:0] ui_data_bus
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

    always @(*) begin
        ui_mode          = current_mode;
        ui_selected_item = selected_item;
        ui_selected_menu = selected_menu;
        ui_input_value   = input_value;
        ui_error_code    = error_code;
        ui_countdown     = remaining_sec;
        ui_alarm_active  = alarm_active || (current_mode == `MODE_ALARM);
        ui_page          = UI_PAGE_MAIN_MENU;

        if (ui_alarm_active) begin
            ui_page = UI_PAGE_ALARM;
        end else if (error_active) begin
            ui_page = UI_PAGE_ERROR;
        end else begin
            case (current_mode)
                `MODE_MAIN_MENU: begin
                    ui_page = UI_PAGE_MAIN_MENU;
                end

                `MODE_SALE: begin
                    case (sale_state)
                        `SALE_STATE_SHOW_LIST:      ui_page = UI_PAGE_SALE_LIST;
                        `SALE_STATE_INPUT_MONEY:    ui_page = UI_PAGE_SALE_PAY;
                        `SALE_STATE_DISPENSE:       ui_page = UI_PAGE_SALE_DISPENSE;
                        `SALE_STATE_WAIT_TAKE:      ui_page = UI_PAGE_SALE_WAIT_TAKE;
                        `SALE_STATE_SUCCESS:        ui_page = UI_PAGE_SALE_SUCCESS;
                        `SALE_STATE_TIMEOUT_REFUND: ui_page = UI_PAGE_SALE_TIMEOUT;
                        `SALE_STATE_ERROR_DISPLAY:  ui_page = UI_PAGE_SALE_ERROR;
                        default:                    ui_page = UI_PAGE_SALE_LIST;
                    endcase
                end

                `MODE_AUTH: begin
                    case (auth_state)
                        `AUTH_STATE_INPUT:         ui_page = UI_PAGE_AUTH_INPUT;
                        `AUTH_STATE_CHECK:         ui_page = UI_PAGE_AUTH_INPUT;
                        `AUTH_STATE_FAIL_DISPLAY:  ui_page = UI_PAGE_AUTH_FAIL;
                        `AUTH_STATE_SUCCESS:       ui_page = UI_PAGE_AUTH_SUCCESS;
                        `AUTH_STATE_ERROR_DISPLAY: ui_page = UI_PAGE_AUTH_ERROR;
                        default:                   ui_page = UI_PAGE_AUTH_INPUT;
                    endcase
                end

                `MODE_ADMIN: begin
                    case (admin_state)
                        `ADMIN_STATE_MENU:                  ui_page = UI_PAGE_ADMIN_MENU;
                        `ADMIN_STATE_VIEW_ITEMS:            ui_page = UI_PAGE_ADMIN_VIEW;
                        `ADMIN_STATE_SET_PRICE_SELECT_ITEM: ui_page = UI_PAGE_ADMIN_PRICE_SELECT;
                        `ADMIN_STATE_SET_PRICE_INPUT:       ui_page = UI_PAGE_ADMIN_PRICE_INPUT;
                        `ADMIN_STATE_SET_PRICE_SUCCESS:     ui_page = UI_PAGE_ADMIN_PRICE_OK;
                        `ADMIN_STATE_ADD_STOCK_SELECT_ITEM: ui_page = UI_PAGE_ADMIN_STOCK_SELECT;
                        `ADMIN_STATE_ADD_STOCK_INPUT:       ui_page = UI_PAGE_ADMIN_STOCK_INPUT;
                        `ADMIN_STATE_ADD_STOCK_SUCCESS:     ui_page = UI_PAGE_ADMIN_STOCK_OK;
                        `ADMIN_STATE_TOGGLE_SELECT_ITEM:    ui_page = UI_PAGE_ADMIN_TOGGLE;
                        `ADMIN_STATE_TOGGLE_SUCCESS:        ui_page = UI_PAGE_ADMIN_TOGGLE_OK;
                        `ADMIN_STATE_VIEW_TOTAL:            ui_page = UI_PAGE_ADMIN_TOTAL;
                        default:                            ui_page = UI_PAGE_ADMIN_MENU;
                    endcase
                end

                `MODE_ALARM: begin
                    ui_page = UI_PAGE_ALARM;
                end

                default: begin
                    ui_page = UI_PAGE_MAIN_MENU;
                end
            endcase
        end

        ui_data_bus             = 128'd0;
        ui_data_bus[2:0]        = ui_mode;
        ui_data_bus[7:3]        = ui_page;
        ui_data_bus[9:8]        = ui_selected_item;
        ui_data_bus[12:10]      = ui_selected_menu;
        ui_data_bus[28:13]      = ui_input_value;
        ui_data_bus[32:29]      = ui_error_code;
        ui_data_bus[35:33]      = ui_countdown;
        ui_data_bus[36]         = ui_alarm_active;
        ui_data_bus[44:37]      = price0;
        ui_data_bus[52:45]      = price1;
        ui_data_bus[60:53]      = price2;
        ui_data_bus[68:61]      = price3;
        ui_data_bus[73:69]      = stock0;
        ui_data_bus[78:74]      = stock1;
        ui_data_bus[83:79]      = stock2;
        ui_data_bus[88:84]      = stock3;
        ui_data_bus[92:89]      = enabled;
        ui_data_bus[108:93]     = sales_total;
        ui_data_bus[112:109]    = sale_state;
        ui_data_bus[116:113]    = admin_state;
        ui_data_bus[119:117]    = auth_state;
        ui_data_bus[127:120]    = 8'h51;
    end

endmodule
