`timescale 1ns / 1ps

`include "admin_flow_tb_pkg.vh"

// Verification-side integration harness for the admin/auth chain.
//
// Expected design-side modules under Code/Design:
//   main_mode_fsm
//   numeric_input_buffer
//   auth_engine
//   admin_engine
//   data_manager
//
// Expected extra ports beyond the original v5.1 I/O table:
//   auth_engine:
//     input  [15:0] buf_current_value
//     input         buf_input_nonempty
//     input         buf_input_done
//     input         buf_input_error
//     output [2:0]  buf_input_mode
//     output        buf_load_req
//     output        buf_clear_req
//     output        buf_commit_req
//
//   admin_engine:
//     input         tick_1s
//     input  [15:0] buf_current_value
//     input         buf_input_nonempty
//     input         buf_input_done
//     input         buf_input_error
//     output [2:0]  buf_input_mode
//     output        buf_load_req
//     output        buf_clear_req
//     output        buf_commit_req

module admin_flow_env (
    input               clk,
    input               rst,
    input               tick_1s,
    input               tb_event_valid,
    input       [2:0]   tb_event_type,
    input       [3:0]   tb_event_value,
    input               tb_main_select_admin,
    input               tb_alarm_done,

    output reg  [2:0]   current_mode,
    output reg          auth_mode_en,
    output reg          admin_mode_en,
    output reg          alarm_mode_en,

    output      [2:0]   auth_state,
    output      [7:0]   password_value,
    output      [1:0]   wrong_count,
    output              auth_ok,
    output              auth_back_req,
    output              auth_home_req,
    output              alarm_trigger,
    output              auth_error_req,
    output      [3:0]   auth_error_code,

    output      [3:0]   admin_state,
    output      [2:0]   selected_func,
    output      [1:0]   selected_item,
    output      [7:0]   input_value,
    output              admin_back_req,
    output              admin_home_req,
    output              admin_set_price_req,
    output              admin_add_stock_req,
    output              admin_toggle_enable_req,
    output      [1:0]   admin_item_idx,
    output      [7:0]   admin_value,
    output              admin_error_req,
    output      [3:0]   admin_error_code,

    output      [15:0]  buf_current_value,
    output      [3:0]   buf_digit_count,
    output              buf_input_nonempty,
    output              buf_input_done,
    output              buf_input_error,
    output reg  [2:0]   buf_input_mode_mux,
    output reg          buf_load_req_mux,
    output reg          buf_clear_req_mux,
    output reg          buf_commit_req_mux,

    output      [7:0]   price0,
    output      [7:0]   price1,
    output      [7:0]   price2,
    output      [7:0]   price3,
    output      [4:0]   stock0,
    output      [4:0]   stock1,
    output      [4:0]   stock2,
    output      [4:0]   stock3,
    output      [3:0]   enabled,
    output      [15:0]  sales_total
);
    reg [2:0]   auth_buf_input_mode;
    reg         auth_buf_load_req;
    reg         auth_buf_clear_req;
    reg         auth_buf_commit_req;

    reg [2:0]   admin_buf_input_mode;
    reg         admin_buf_load_req;
    reg         admin_buf_clear_req;
    reg         admin_buf_commit_req;

    reg [1:0]   active_buf_owner;
    reg [1:0]   active_buf_owner_d;
    reg         mode_switch_clear_pulse;

    always @(*) begin
        if (auth_mode_en) begin
            active_buf_owner = 2'd1;
        end else if (admin_mode_en) begin
            active_buf_owner = 2'd2;
        end else begin
            active_buf_owner = 2'd0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_buf_owner_d <= 2'd0;
        end else begin
            active_buf_owner_d <= active_buf_owner;
        end
    end

    assign mode_switch_clear_pulse = (active_buf_owner != active_buf_owner_d);

    always @(*) begin
        case (active_buf_owner)
            2'd1: begin
                buf_input_mode_mux = auth_buf_input_mode;
                buf_load_req_mux   = auth_buf_load_req;
                buf_clear_req_mux  = auth_buf_clear_req | mode_switch_clear_pulse;
                buf_commit_req_mux = auth_buf_commit_req;
            end
            2'd2: begin
                buf_input_mode_mux = admin_buf_input_mode;
                buf_load_req_mux   = admin_buf_load_req;
                buf_clear_req_mux  = admin_buf_clear_req | mode_switch_clear_pulse;
                buf_commit_req_mux = admin_buf_commit_req;
            end
            default: begin
                buf_input_mode_mux = BUF_MODE_SINGLE_ID;
                buf_load_req_mux   = 1'b0;
                buf_clear_req_mux  = mode_switch_clear_pulse;
                buf_commit_req_mux = 1'b0;
            end
        endcase
    end

    main_mode_fsm u_main_mode_fsm (
        .clk(clk),
        .rst(rst),
        .main_select_sale(1'b0),
        .main_select_admin(tb_main_select_admin),
        .sale_back_req(1'b0),
        .sale_home_req(1'b0),
        .auth_ok(auth_ok),
        .auth_back_req(auth_back_req),
        .auth_home_req(auth_home_req),
        .alarm_trigger(alarm_trigger),
        .admin_back_req(admin_back_req),
        .admin_home_req(admin_home_req),
        .alarm_done(tb_alarm_done),
        .current_mode(current_mode),
        .sale_mode_en(),
        .auth_mode_en(auth_mode_en),
        .admin_mode_en(admin_mode_en),
        .alarm_mode_en(alarm_mode_en)
    );

    numeric_input_buffer u_numeric_input_buffer (
        .clk(clk),
        .rst(rst),
        .event_valid(tb_event_valid & (auth_mode_en | admin_mode_en)),
        .event_type(tb_event_type),
        .event_value(tb_event_value),
        .input_mode(buf_input_mode_mux),
        .load_req(buf_load_req_mux),
        .clear_req(buf_clear_req_mux),
        .commit_req(buf_commit_req_mux),
        .current_value(buf_current_value),
        .digit_count(buf_digit_count),
        .input_nonempty(buf_input_nonempty),
        .input_done(buf_input_done),
        .input_error(buf_input_error)
    );

    data_manager u_data_manager (
        .clk(clk),
        .rst(rst),
        .sale_stock_dec_req(1'b0),
        .sale_stock_inc_req(1'b0),
        .sale_total_add_req(1'b0),
        .sale_item_idx(2'd0),
        .sale_amount(8'd0),
        .admin_set_price_req(admin_set_price_req),
        .admin_add_stock_req(admin_add_stock_req),
        .admin_toggle_enable_req(admin_toggle_enable_req),
        .admin_item_idx(admin_item_idx),
        .admin_value(admin_value),
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

    auth_engine u_auth_engine (
        .clk(clk),
        .rst(rst),
        .mode_en(auth_mode_en),
        .event_valid(tb_event_valid),
        .event_type(tb_event_type),
        .event_value(tb_event_value),
        .tick_1s(tick_1s),
        .buf_current_value(buf_current_value),
        .buf_input_nonempty(buf_input_nonempty),
        .buf_input_done(buf_input_done),
        .buf_input_error(buf_input_error),
        .auth_state(auth_state),
        .password_value(password_value),
        .wrong_count(wrong_count),
        .auth_ok(auth_ok),
        .auth_back_req(auth_back_req),
        .auth_home_req(auth_home_req),
        .alarm_trigger(alarm_trigger),
        .error_req(auth_error_req),
        .error_code(auth_error_code),
        .buf_input_mode(auth_buf_input_mode),
        .buf_load_req(auth_buf_load_req),
        .buf_clear_req(auth_buf_clear_req),
        .buf_commit_req(auth_buf_commit_req)
    );

    admin_engine u_admin_engine (
        .clk(clk),
        .rst(rst),
        .mode_en(admin_mode_en),
        .event_valid(tb_event_valid),
        .event_type(tb_event_type),
        .event_value(tb_event_value),
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
        .sales_total(sales_total),
        .buf_current_value(buf_current_value),
        .buf_input_nonempty(buf_input_nonempty),
        .buf_input_done(buf_input_done),
        .buf_input_error(buf_input_error),
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
        .error_req(admin_error_req),
        .error_code(admin_error_code),
        .buf_input_mode(admin_buf_input_mode),
        .buf_load_req(admin_buf_load_req),
        .buf_clear_req(admin_buf_clear_req),
        .buf_commit_req(admin_buf_commit_req)
    );
endmodule
