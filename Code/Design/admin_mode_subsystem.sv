`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module admin_mode_subsystem (
    input  logic        clk,
    input  logic        rst,
    input  logic        tick_1s,
    input  logic        auth_mode_en,
    input  logic        admin_mode_en,
    input  logic        event_valid,
    input  logic [2:0]  event_type,
    input  logic [3:0]  event_value,
    input  logic        sale_stock_dec_req,
    input  logic        sale_stock_inc_req,
    input  logic        sale_total_add_req,
    input  logic [1:0]  sale_item_idx,
    input  logic [7:0]  sale_amount,
    output logic [7:0]  price0,
    output logic [7:0]  price1,
    output logic [7:0]  price2,
    output logic [7:0]  price3,
    output logic [4:0]  stock0,
    output logic [4:0]  stock1,
    output logic [4:0]  stock2,
    output logic [4:0]  stock3,
    output logic [3:0]  enabled,
    output logic [15:0] sales_total,
    output logic [2:0]  auth_state,
    output logic [7:0]  password_value,
    output logic [1:0]  wrong_count,
    output logic        auth_ok,
    output logic        auth_back_req,
    output logic        auth_home_req,
    output logic        alarm_trigger,
    output logic        auth_error_req,
    output logic [3:0]  auth_error_code,
    output logic [3:0]  admin_state,
    output logic [2:0]  selected_func,
    output logic [1:0]  selected_item,
    output logic [7:0]  input_value,
    output logic        admin_back_req,
    output logic        admin_home_req,
    output logic        admin_set_price_req,
    output logic        admin_add_stock_req,
    output logic        admin_toggle_enable_req,
    output logic [1:0]  admin_item_idx,
    output logic [7:0]  admin_value,
    output logic        admin_error_req,
    output logic [3:0]  admin_error_code,
    output logic [15:0] buffer_current_value,
    output logic [3:0]  buffer_digit_count,
    output logic        buffer_input_nonempty,
    output logic        buffer_input_done,
    output logic        buffer_input_error
);

    // Shared encodings are defined in admin_mode_defs.vh and reused by all
    // instantiated modules so state/event values remain identical end-to-end.

    logic [2:0] auth_buf_input_mode;
    logic       auth_buf_load_req;
    logic       auth_buf_clear_req;
    logic       auth_buf_commit_req;

    logic [2:0] admin_buf_input_mode;
    logic       admin_buf_load_req;
    logic       admin_buf_clear_req;
    logic       admin_buf_commit_req;

    logic [2:0] shared_buf_input_mode;
    logic       shared_buf_load_req;
    logic       shared_buf_clear_req;
    logic       shared_buf_commit_req;

    always_comb begin
        shared_buf_input_mode = `INPUT_MODE_IDLE;
        shared_buf_load_req   = 1'b0;
        shared_buf_clear_req  = 1'b0;
        shared_buf_commit_req = 1'b0;

        if (auth_mode_en) begin
            shared_buf_input_mode = auth_buf_input_mode;
            shared_buf_load_req   = auth_buf_load_req;
            shared_buf_clear_req  = auth_buf_clear_req;
            shared_buf_commit_req = auth_buf_commit_req;
        end else if (admin_mode_en) begin
            shared_buf_input_mode = admin_buf_input_mode;
            shared_buf_load_req   = admin_buf_load_req;
            shared_buf_clear_req  = admin_buf_clear_req;
            shared_buf_commit_req = admin_buf_commit_req;
        end else begin
            shared_buf_clear_req = 1'b1;
        end
    end

    numeric_input_buffer u_numeric_input_buffer (
        .clk            (clk),
        .rst            (rst),
        .event_valid    (event_valid),
        .event_type     (event_type),
        .event_value    (event_value),
        .input_mode     (shared_buf_input_mode),
        .load_req       (shared_buf_load_req),
        .clear_req      (shared_buf_clear_req),
        .commit_req     (shared_buf_commit_req),
        .current_value  (buffer_current_value),
        .digit_count    (buffer_digit_count),
        .input_nonempty (buffer_input_nonempty),
        .input_done     (buffer_input_done),
        .input_error    (buffer_input_error)
    );

    data_manager u_data_manager (
        .clk                     (clk),
        .rst                     (rst),
        .sale_stock_dec_req      (sale_stock_dec_req),
        .sale_stock_inc_req      (sale_stock_inc_req),
        .sale_total_add_req      (sale_total_add_req),
        .sale_item_idx           (sale_item_idx),
        .sale_amount             (sale_amount),
        .admin_set_price_req     (admin_set_price_req),
        .admin_add_stock_req     (admin_add_stock_req),
        .admin_toggle_enable_req (admin_toggle_enable_req),
        .admin_item_idx          (admin_item_idx),
        .admin_value             (admin_value),
        .price0                  (price0),
        .price1                  (price1),
        .price2                  (price2),
        .price3                  (price3),
        .stock0                  (stock0),
        .stock1                  (stock1),
        .stock2                  (stock2),
        .stock3                  (stock3),
        .enabled                 (enabled),
        .sales_total             (sales_total)
    );

    auth_engine u_auth_engine (
        .clk               (clk),
        .rst               (rst),
        .mode_en           (auth_mode_en),
        .event_valid       (event_valid),
        .event_type        (event_type),
        .event_value       (event_value),
        .tick_1s           (tick_1s),
        .buf_current_value (buffer_current_value),
        .buf_input_nonempty(buffer_input_nonempty),
        .buf_input_done    (buffer_input_done),
        .buf_input_error   (buffer_input_error),
        .auth_state        (auth_state),
        .password_value    (password_value),
        .wrong_count       (wrong_count),
        .auth_ok           (auth_ok),
        .auth_back_req     (auth_back_req),
        .auth_home_req     (auth_home_req),
        .alarm_trigger     (alarm_trigger),
        .error_req         (auth_error_req),
        .error_code        (auth_error_code),
        .buf_input_mode    (auth_buf_input_mode),
        .buf_load_req      (auth_buf_load_req),
        .buf_clear_req     (auth_buf_clear_req),
        .buf_commit_req    (auth_buf_commit_req)
    );

    admin_engine u_admin_engine (
        .clk                    (clk),
        .rst                    (rst),
        .mode_en                (admin_mode_en),
        .event_valid            (event_valid),
        .event_type             (event_type),
        .event_value            (event_value),
        .tick_1s                (tick_1s),
        .price0                 (price0),
        .price1                 (price1),
        .price2                 (price2),
        .price3                 (price3),
        .stock0                 (stock0),
        .stock1                 (stock1),
        .stock2                 (stock2),
        .stock3                 (stock3),
        .enabled                (enabled),
        .sales_total            (sales_total),
        .buf_current_value      (buffer_current_value),
        .buf_input_nonempty     (buffer_input_nonempty),
        .buf_input_done         (buffer_input_done),
        .buf_input_error        (buffer_input_error),
        .admin_state            (admin_state),
        .selected_func          (selected_func),
        .selected_item          (selected_item),
        .input_value            (input_value),
        .admin_back_req         (admin_back_req),
        .admin_home_req         (admin_home_req),
        .admin_set_price_req    (admin_set_price_req),
        .admin_add_stock_req    (admin_add_stock_req),
        .admin_toggle_enable_req(admin_toggle_enable_req),
        .admin_item_idx         (admin_item_idx),
        .admin_value            (admin_value),
        .error_req              (admin_error_req),
        .error_code             (admin_error_code),
        .buf_input_mode         (admin_buf_input_mode),
        .buf_load_req           (admin_buf_load_req),
        .buf_clear_req          (admin_buf_clear_req),
        .buf_commit_req         (admin_buf_commit_req)
    );

endmodule
