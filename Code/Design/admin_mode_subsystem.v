`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module admin_mode_subsystem (
    input               clk,
    input               rst,
    input               tick_1s,
    input               auth_mode_en,
    input               admin_mode_en,
    input               event_valid,
    input       [2:0]   event_type,
    input       [3:0]   event_value,
    input               sale_stock_dec_req,
    input               sale_stock_inc_req,
    input               sale_total_add_req,
    input       [1:0]   sale_item_idx,
    input       [7:0]   sale_amount,
    output      [7:0]   price0,
    output      [7:0]   price1,
    output      [7:0]   price2,
    output      [7:0]   price3,
    output      [4:0]   stock0,
    output      [4:0]   stock1,
    output      [4:0]   stock2,
    output      [4:0]   stock3,
    output      [3:0]   enabled,
    output      [15:0]  sales_total,
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
    output      [15:0]  buffer_current_value,
    output      [3:0]   buffer_digit_count,
    output              buffer_input_nonempty,
    output              buffer_input_done,
    output              buffer_input_error
);

    // Shared encodings are defined in admin_mode_defs.vh and reused by all
    // instantiated modules so state/event values remain identical end-to-end.

    reg [2:0]   auth_buf_input_mode;
    reg         auth_buf_load_req;
    reg         auth_buf_clear_req;
    reg         auth_buf_commit_req;

    reg [2:0]   admin_buf_input_mode;
    reg         admin_buf_load_req;
    reg         admin_buf_clear_req;
    reg         admin_buf_commit_req;

    reg [2:0]   shared_buf_input_mode;
    reg         shared_buf_load_req;
    reg         shared_buf_clear_req;
    reg         shared_buf_commit_req;
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

    always @(*) begin
        mode_switch_clear_pulse = 1'b0;
        if (active_buf_owner != active_buf_owner_d) begin
            mode_switch_clear_pulse = 1'b1;
        end
    end

    always @(*) begin
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
        end

        if (mode_switch_clear_pulse) begin
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
