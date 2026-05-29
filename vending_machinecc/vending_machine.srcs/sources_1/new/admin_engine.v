`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module admin_engine (
    input               clk,
    input               rst,
    input               mode_en,
    input               event_valid,
    input       [2:0]   event_type,
    input       [3:0]   event_value,
    input               tick_1s,
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
    input       [15:0]  buf_current_value,
    input               buf_input_nonempty,
    input               buf_input_done,
    input               buf_input_error,
    output reg  [3:0]   admin_state,
    output reg  [2:0]   selected_func,
    output reg  [1:0]   selected_item,
    output      [7:0]   input_value,
    output reg          admin_back_req,
    output reg          admin_home_req,
    output reg          admin_set_price_req,
    output reg          admin_add_stock_req,
    output reg          admin_toggle_enable_req,
    output      [1:0]   admin_item_idx,
    output      [7:0]   admin_value,
    output reg          error_req,
    output reg  [3:0]   error_code,
    output reg  [2:0]   buf_input_mode,
    output reg          buf_load_req,
    output reg          buf_clear_req,
    output reg          buf_commit_req
);

    // Shared encodings in admin_mode_defs.vh:
    // ADMIN_MENU=0, VIEW_ITEMS=1, SET_PRICE_SELECT_ITEM=2, SET_PRICE_INPUT=3,
    // SET_PRICE_SUCCESS=4, ADD_STOCK_SELECT_ITEM=5, ADD_STOCK_INPUT=6,
    // ADD_STOCK_SUCCESS=7, TOGGLE_SELECT_ITEM=8, TOGGLE_SUCCESS=9, VIEW_TOTAL=10.

    reg         mode_en_d;
    reg [7:0]   committed_value;

    function [2:0] func_prev;
        input [2:0] func_value;
        begin
            case (func_value)
                `ADMIN_FUNC_VIEW_ITEMS: func_prev = `ADMIN_FUNC_VIEW_TOTAL;
                `ADMIN_FUNC_SET_PRICE:  func_prev = `ADMIN_FUNC_VIEW_ITEMS;
                `ADMIN_FUNC_ADD_STOCK:  func_prev = `ADMIN_FUNC_SET_PRICE;
                `ADMIN_FUNC_TOGGLE:     func_prev = `ADMIN_FUNC_ADD_STOCK;
                default:                func_prev = `ADMIN_FUNC_TOGGLE;
            endcase
        end
    endfunction

    function [2:0] func_next;
        input [2:0] func_value;
        begin
            case (func_value)
                `ADMIN_FUNC_VIEW_ITEMS: func_next = `ADMIN_FUNC_SET_PRICE;
                `ADMIN_FUNC_SET_PRICE:  func_next = `ADMIN_FUNC_ADD_STOCK;
                `ADMIN_FUNC_ADD_STOCK:  func_next = `ADMIN_FUNC_TOGGLE;
                `ADMIN_FUNC_TOGGLE:     func_next = `ADMIN_FUNC_VIEW_TOTAL;
                default:                func_next = `ADMIN_FUNC_VIEW_ITEMS;
            endcase
        end
    endfunction

    function [1:0] item_prev;
        input [1:0] item_value;
        begin
            case (item_value)
                2'd0: item_prev = 2'd3;
                2'd1: item_prev = 2'd0;
                2'd2: item_prev = 2'd1;
                default: item_prev = 2'd2;
            endcase
        end
    endfunction

    function [1:0] item_next;
        input [1:0] item_value;
        begin
            case (item_value)
                2'd0: item_next = 2'd1;
                2'd1: item_next = 2'd2;
                2'd2: item_next = 2'd3;
                default: item_next = 2'd0;
            endcase
        end
    endfunction

    function [1:0] digit_to_item;
        input [3:0] digit_value;
        begin
            case (digit_value)
                4'd1: digit_to_item = 2'd0;
                4'd2: digit_to_item = 2'd1;
                4'd3: digit_to_item = 2'd2;
                4'd4: digit_to_item = 2'd3;
                default: digit_to_item = 2'd0;
            endcase
        end
    endfunction

    assign admin_item_idx = selected_item;
    assign admin_value    = committed_value;
    assign input_value    = ((admin_state == `ADMIN_STATE_SET_PRICE_INPUT) ||
                             (admin_state == `ADMIN_STATE_ADD_STOCK_INPUT))
                          ? buf_current_value[7:0]
                          : committed_value;

    always @(*) begin
        case (admin_state)
            `ADMIN_STATE_SET_PRICE_INPUT: buf_input_mode = `INPUT_MODE_PRICE;
            `ADMIN_STATE_ADD_STOCK_INPUT: buf_input_mode = `INPUT_MODE_STOCK;
            default:                      buf_input_mode = `INPUT_MODE_IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            admin_state             <= `ADMIN_STATE_MENU;
            selected_func           <= `ADMIN_FUNC_VIEW_ITEMS;
            selected_item           <= 2'd0;
            committed_value         <= 8'd0;
            admin_back_req          <= 1'b0;
            admin_home_req          <= 1'b0;
            admin_set_price_req     <= 1'b0;
            admin_add_stock_req     <= 1'b0;
            admin_toggle_enable_req <= 1'b0;
            error_req               <= 1'b0;
            error_code              <= `ERR_NONE;
            buf_load_req            <= 1'b0;
            buf_clear_req           <= 1'b0;
            buf_commit_req          <= 1'b0;
            mode_en_d               <= 1'b0;
        end else begin
            admin_back_req          <= 1'b0;
            admin_home_req          <= 1'b0;
            admin_set_price_req     <= 1'b0;
            admin_add_stock_req     <= 1'b0;
            admin_toggle_enable_req <= 1'b0;
            error_req               <= 1'b0;
            error_code              <= `ERR_NONE;
            buf_load_req            <= 1'b0;
            buf_clear_req           <= 1'b0;
            buf_commit_req          <= 1'b0;
            mode_en_d               <= mode_en;

            if (!mode_en) begin
                admin_state     <= `ADMIN_STATE_MENU;
                selected_func   <= `ADMIN_FUNC_VIEW_ITEMS;
                selected_item   <= 2'd0;
                committed_value <= 8'd0;
            end else begin
                if (!mode_en_d) begin
                    admin_state   <= `ADMIN_STATE_MENU;
                    selected_func <= `ADMIN_FUNC_VIEW_ITEMS;
                    selected_item <= 2'd0;
                    buf_clear_req <= 1'b1;
                end else begin
                    case (admin_state)
                        `ADMIN_STATE_MENU: begin
                            if (event_valid) begin
                                case (event_type)
                                    `EV_DIGIT: begin
                                        if ((event_value >= 4'd1) &&
                                            (event_value <= 4'd5)) begin
                                            selected_func <= event_value[2:0];
                                        end else begin
                                            error_req  <= 1'b1;
                                            error_code <= `ERR_INVALID_INPUT;
                                        end
                                    end
                                    `EV_PREV: selected_func <= func_prev(selected_func);
                                    `EV_NEXT: selected_func <= func_next(selected_func);
                                    `EV_BACK: admin_back_req <= 1'b1;
                                    `EV_HOME: admin_home_req <= 1'b1;
                                    `EV_CONFIRM: begin
                                        case (selected_func)
                                            `ADMIN_FUNC_VIEW_ITEMS:
                                                admin_state <= `ADMIN_STATE_VIEW_ITEMS;
                                            `ADMIN_FUNC_SET_PRICE:
                                                admin_state <= `ADMIN_STATE_SET_PRICE_SELECT_ITEM;
                                            `ADMIN_FUNC_ADD_STOCK:
                                                admin_state <= `ADMIN_STATE_ADD_STOCK_SELECT_ITEM;
                                            `ADMIN_FUNC_TOGGLE:
                                                admin_state <= `ADMIN_STATE_TOGGLE_SELECT_ITEM;
                                            `ADMIN_FUNC_VIEW_TOTAL:
                                                admin_state <= `ADMIN_STATE_VIEW_TOTAL;
                                            default: begin
                                                error_req  <= 1'b1;
                                                error_code <= `ERR_INVALID_INPUT;
                                            end
                                        endcase
                                    end
                                    default: begin
                                        error_req  <= 1'b1;
                                        error_code <= `ERR_INVALID_INPUT;
                                    end
                                endcase
                            end
                        end

                        `ADMIN_STATE_VIEW_ITEMS: begin
                            if (event_valid) begin
                                case (event_type)
                                    `EV_PREV: selected_item <= item_prev(selected_item);
                                    `EV_NEXT: selected_item <= item_next(selected_item);
                                    `EV_BACK: admin_state   <= `ADMIN_STATE_MENU;
                                    `EV_HOME: admin_home_req <= 1'b1;
                                    default: begin
                                        error_req  <= 1'b1;
                                        error_code <= `ERR_INVALID_INPUT;
                                    end
                                endcase
                            end
                        end

                        `ADMIN_STATE_SET_PRICE_SELECT_ITEM,
                        `ADMIN_STATE_ADD_STOCK_SELECT_ITEM,
                        `ADMIN_STATE_TOGGLE_SELECT_ITEM: begin
                            if (event_valid) begin
                                case (event_type)
                                    `EV_DIGIT: begin
                                        if ((event_value >= 4'd1) &&
                                            (event_value <= 4'd4)) begin
                                            selected_item <= digit_to_item(event_value);
                                        end else begin
                                            error_req  <= 1'b1;
                                            error_code <= `ERR_INVALID_INPUT;
                                        end
                                    end
                                    `EV_PREV: selected_item <= item_prev(selected_item);
                                    `EV_NEXT: selected_item <= item_next(selected_item);
                                    `EV_BACK: admin_state   <= `ADMIN_STATE_MENU;
                                    `EV_HOME: admin_home_req <= 1'b1;
                                    `EV_CONFIRM: begin
                                        if (admin_state == `ADMIN_STATE_TOGGLE_SELECT_ITEM) begin
                                            admin_toggle_enable_req <= 1'b1;
                                            admin_state             <= `ADMIN_STATE_TOGGLE_SUCCESS;
                                        end else if (admin_state == `ADMIN_STATE_SET_PRICE_SELECT_ITEM) begin
                                            admin_state <= `ADMIN_STATE_SET_PRICE_INPUT;
                                            buf_load_req <= 1'b1;
                                        end else begin
                                            admin_state <= `ADMIN_STATE_ADD_STOCK_INPUT;
                                            buf_load_req <= 1'b1;
                                        end
                                    end
                                    default: begin
                                        error_req  <= 1'b1;
                                        error_code <= `ERR_INVALID_INPUT;
                                    end
                                endcase
                            end
                        end

                        `ADMIN_STATE_SET_PRICE_INPUT,
                        `ADMIN_STATE_ADD_STOCK_INPUT: begin
                            if (buf_input_done) begin
                                committed_value <= buf_current_value[7:0];
                                buf_clear_req   <= 1'b1;
                                if (admin_state == `ADMIN_STATE_SET_PRICE_INPUT) begin
                                    admin_set_price_req <= 1'b1;
                                    admin_state         <= `ADMIN_STATE_SET_PRICE_SUCCESS;
                                end else begin
                                    admin_add_stock_req <= 1'b1;
                                    admin_state         <= `ADMIN_STATE_ADD_STOCK_SUCCESS;
                                end
                            end else if (buf_input_error) begin
                                error_req  <= 1'b1;
                                error_code <= `ERR_INVALID_INPUT;
                            end else if (event_valid) begin
                                case (event_type)
                                    `EV_BACK: begin
                                        admin_state   <= (admin_state == `ADMIN_STATE_SET_PRICE_INPUT)
                                                       ? `ADMIN_STATE_SET_PRICE_SELECT_ITEM
                                                       : `ADMIN_STATE_ADD_STOCK_SELECT_ITEM;
                                        buf_clear_req <= 1'b1;
                                    end
                                    `EV_HOME: begin
                                        admin_home_req <= 1'b1;
                                        buf_clear_req  <= 1'b1;
                                    end
                                    `EV_CLEAR: begin
                                        buf_clear_req <= 1'b1;
                                    end
                                    `EV_CONFIRM: begin
                                        buf_commit_req <= 1'b1;
                                    end
                                    `EV_PREV,
                                    `EV_NEXT: begin
                                        error_req  <= 1'b1;
                                        error_code <= `ERR_INVALID_INPUT;
                                    end
                                    default: begin
                                        // Digits are consumed by numeric_input_buffer.
                                    end
                                endcase
                            end
                        end

                        `ADMIN_STATE_SET_PRICE_SUCCESS: begin
                            if (tick_1s) begin
                                admin_state <= `ADMIN_STATE_SET_PRICE_SELECT_ITEM;
                            end
                        end

                        `ADMIN_STATE_ADD_STOCK_SUCCESS: begin
                            if (tick_1s) begin
                                admin_state <= `ADMIN_STATE_ADD_STOCK_SELECT_ITEM;
                            end
                        end

                        `ADMIN_STATE_TOGGLE_SUCCESS: begin
                            if (tick_1s) begin
                                admin_state <= `ADMIN_STATE_TOGGLE_SELECT_ITEM;
                            end
                        end

                        `ADMIN_STATE_VIEW_TOTAL: begin
                            if (event_valid) begin
                                case (event_type)
                                    `EV_BACK: admin_state    <= `ADMIN_STATE_MENU;
                                    `EV_HOME: admin_home_req <= 1'b1;
                                    default: begin
                                        error_req  <= 1'b1;
                                        error_code <= `ERR_INVALID_INPUT;
                                    end
                                endcase
                            end
                        end

                        default: begin
                            admin_state <= `ADMIN_STATE_MENU;
                        end
                    endcase
                end
            end
        end
    end

endmodule
