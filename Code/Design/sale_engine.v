`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module sale_engine (
    input              clk,
    input              rst,
    input              mode_en,
    input              event_valid,
    input      [2:0]   event_type,
    input      [3:0]   event_value,
    input              tick_1s,
    input      [7:0]   price0,
    input      [7:0]   price1,
    input      [7:0]   price2,
    input      [7:0]   price3,
    input      [4:0]   stock0,
    input      [4:0]   stock1,
    input      [4:0]   stock2,
    input      [4:0]   stock3,
    input      [3:0]   enabled,
    input      [2:0]   remaining_sec,
    input              order_timeout,
    output reg [3:0]   sale_state,
    output reg [1:0]   selected_item,
    output reg [7:0]   latched_price,
    output reg [7:0]   paid_amount,
    output reg         sale_back_req,
    output reg         sale_home_req,
    output reg         order_timer_start,
    output reg         order_timer_stop,
    output reg         sale_stock_dec_req,
    output reg         sale_stock_inc_req,
    output reg         sale_total_add_req,
    output     [1:0]   sale_item_idx,
    output     [7:0]   sale_amount,
    output reg         error_req,
    output reg [3:0]   error_code
);

    reg         mode_en_d;
    reg [3:0]   error_return_state;
    reg [11:0]  next_paid_amount;

    assign sale_item_idx = selected_item;
    assign sale_amount   = latched_price;

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

    function [7:0] price_for_item;
        input [1:0] item_value;
        begin
            case (item_value)
                2'd0: price_for_item = price0;
                2'd1: price_for_item = price1;
                2'd2: price_for_item = price2;
                default: price_for_item = price3;
            endcase
        end
    endfunction

    function [4:0] stock_for_item;
        input [1:0] item_value;
        begin
            case (item_value)
                2'd0: stock_for_item = stock0;
                2'd1: stock_for_item = stock1;
                2'd2: stock_for_item = stock2;
                default: stock_for_item = stock3;
            endcase
        end
    endfunction

    function enabled_for_item;
        input [1:0] item_value;
        begin
            enabled_for_item = enabled[item_value];
        end
    endfunction

    always @(*) begin
        next_paid_amount = ({4'd0, paid_amount} * 12'd10) + {8'd0, event_value};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sale_state         <= `SALE_STATE_SHOW_LIST;
            selected_item      <= 2'd0;
            latched_price      <= 8'd0;
            paid_amount        <= 8'd0;
            sale_back_req      <= 1'b0;
            sale_home_req      <= 1'b0;
            order_timer_start  <= 1'b0;
            order_timer_stop   <= 1'b0;
            sale_stock_dec_req <= 1'b0;
            sale_stock_inc_req <= 1'b0;
            sale_total_add_req <= 1'b0;
            error_req          <= 1'b0;
            error_code         <= `ERR_NONE;
            mode_en_d          <= 1'b0;
            error_return_state <= `SALE_STATE_SHOW_LIST;
        end else begin
            sale_back_req      <= 1'b0;
            sale_home_req      <= 1'b0;
            order_timer_start  <= 1'b0;
            order_timer_stop   <= 1'b0;
            sale_stock_dec_req <= 1'b0;
            sale_stock_inc_req <= 1'b0;
            sale_total_add_req <= 1'b0;
            error_req          <= 1'b0;
            mode_en_d          <= mode_en;

            if (!mode_en) begin
                sale_state         <= `SALE_STATE_SHOW_LIST;
                selected_item      <= 2'd0;
                latched_price      <= 8'd0;
                paid_amount        <= 8'd0;
                error_code         <= `ERR_NONE;
                error_return_state <= `SALE_STATE_SHOW_LIST;
            end else begin
                if (!mode_en_d) begin
                    sale_state         <= `SALE_STATE_SHOW_LIST;
                    selected_item      <= 2'd0;
                    latched_price      <= 8'd0;
                    paid_amount        <= 8'd0;
                    error_code         <= `ERR_NONE;
                    error_return_state <= `SALE_STATE_SHOW_LIST;
                end else begin
                    case (sale_state)
                        `SALE_STATE_SHOW_LIST: begin
                            if (event_valid) begin
                                case (event_type)
                                    `EV_DIGIT: begin
                                        if ((event_value >= 4'd1) &&
                                            (event_value <= 4'd4)) begin
                                            selected_item <= digit_to_item(event_value);
                                        end else begin
                                            error_req          <= 1'b1;
                                            error_code         <= `ERR_INVALID_INPUT;
                                            error_return_state <= `SALE_STATE_SHOW_LIST;
                                            sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                        end
                                    end
                                    `EV_PREV: selected_item <= item_prev(selected_item);
                                    `EV_NEXT: selected_item <= item_next(selected_item);
                                    `EV_BACK: sale_back_req <= 1'b1;
                                    `EV_HOME: sale_home_req <= 1'b1;
                                    `EV_CONFIRM: begin
                                        if (!enabled_for_item(selected_item)) begin
                                            error_req          <= 1'b1;
                                            error_code         <= `ERR_ITEM_OFF;
                                            error_return_state <= `SALE_STATE_SHOW_LIST;
                                            sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                        end else if (stock_for_item(selected_item) == 5'd0) begin
                                            error_req          <= 1'b1;
                                            error_code         <= `ERR_NO_STOCK;
                                            error_return_state <= `SALE_STATE_SHOW_LIST;
                                            sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                        end else begin
                                            latched_price <= price_for_item(selected_item);
                                            paid_amount   <= 8'd0;
                                            sale_state    <= `SALE_STATE_INPUT_MONEY;
                                        end
                                    end
                                    default: begin
                                            error_req          <= 1'b1;
                                            error_code         <= `ERR_INVALID_INPUT;
                                            error_return_state <= `SALE_STATE_SHOW_LIST;
                                            sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                        end
                                endcase
                            end
                        end

                        `SALE_STATE_INPUT_MONEY: begin
                            if (event_valid) begin
                                case (event_type)
                                    `EV_DIGIT: begin
                                        if (next_paid_amount <= 12'd255) begin
                                            paid_amount <= next_paid_amount[7:0];
                                        end else begin
                                            error_req          <= 1'b1;
                                            error_code         <= `ERR_INVALID_INPUT;
                                            error_return_state <= `SALE_STATE_INPUT_MONEY;
                                            sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                        end
                                    end
                                    `EV_CLEAR: paid_amount <= 8'd0;
                                    `EV_BACK: begin
                                        paid_amount   <= 8'd0;
                                        latched_price <= 8'd0;
                                        sale_state    <= `SALE_STATE_SHOW_LIST;
                                    end
                                    `EV_HOME: begin
                                        paid_amount   <= 8'd0;
                                        latched_price <= 8'd0;
                                        sale_home_req <= 1'b1;
                                    end
                                    `EV_CONFIRM: begin
                                        if (paid_amount >= latched_price) begin
                                            sale_stock_dec_req <= 1'b1;
                                            sale_state         <= `SALE_STATE_DISPENSE;
                                        end else begin
                                            error_req          <= 1'b1;
                                            error_code         <= `ERR_NOT_ENOUGH;
                                            error_return_state <= `SALE_STATE_INPUT_MONEY;
                                            sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                        end
                                    end
                                    default: begin
                                        error_req          <= 1'b1;
                                        error_code         <= `ERR_INVALID_INPUT;
                                        error_return_state <= `SALE_STATE_INPUT_MONEY;
                                        sale_state         <= `SALE_STATE_ERROR_DISPLAY;
                                    end
                                endcase
                            end
                        end

                        `SALE_STATE_DISPENSE: begin
                            if (tick_1s) begin
                                order_timer_start <= 1'b1;
                                sale_state        <= `SALE_STATE_WAIT_TAKE;
                            end
                        end

                        `SALE_STATE_WAIT_TAKE: begin
                            if (order_timeout) begin
                                sale_stock_inc_req <= 1'b1;
                                order_timer_stop   <= 1'b1;
                                sale_state         <= `SALE_STATE_TIMEOUT_REFUND;
                            end else if (event_valid && (event_type == `EV_CONFIRM)) begin
                                sale_total_add_req <= 1'b1;
                                order_timer_stop   <= 1'b1;
                                sale_state         <= `SALE_STATE_SUCCESS;
                            end
                        end

                        `SALE_STATE_SUCCESS: begin
                            if (tick_1s) begin
                                paid_amount   <= 8'd0;
                                latched_price <= 8'd0;
                                error_code    <= `ERR_NONE;
                                sale_state    <= `SALE_STATE_SHOW_LIST;
                            end
                        end

                        `SALE_STATE_TIMEOUT_REFUND: begin
                            if (tick_1s) begin
                                paid_amount   <= 8'd0;
                                latched_price <= 8'd0;
                                error_code    <= `ERR_NONE;
                                sale_state    <= `SALE_STATE_SHOW_LIST;
                            end
                        end

                        `SALE_STATE_ERROR_DISPLAY: begin
                            if (tick_1s) begin
                                error_code <= `ERR_NONE;
                                sale_state <= error_return_state;
                            end
                        end

                        default: begin
                            sale_state <= `SALE_STATE_SHOW_LIST;
                        end
                    endcase
                end
            end
        end
    end

endmodule
