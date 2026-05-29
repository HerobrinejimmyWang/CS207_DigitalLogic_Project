`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module TopModule (
    input  wire        sys_clk_in,
    input  wire        sys_rst_n,
    inout  wire [7:0]  exp_io,
    output wire [15:0] led_pin,
    output wire [7:0]  seg_cs_pin,
    output wire [7:0]  seg_data_0_pin,
    output wire [7:0]  seg_data_1_pin,
    output wire        vga_hs_pin,
    output wire        vga_vs_pin,
    output wire [11:0] vga_data_pin,
    output wire        audio_pwm_o,
    output wire        audio_sd_o
);

    wire        clk;
    wire        rst;
    wire        tick_1ms;
    wire        tick_10ms;
    wire        tick_100ms;
    wire        tick_1s;
    wire        pix_en;

    wire [3:0]  row_active;
    wire [3:0]  col_in;
    wire        scan_key_valid;
    wire [1:0]  scan_key_row;
    wire [1:0]  scan_key_col;
    wire        key_valid;
    wire [3:0]  key_code;
    wire        event_valid;
    wire [2:0]  event_type;
    wire [3:0]  event_value;
    wire        core_event_valid;

    reg  [2:0]  main_selected_menu;
    reg         main_select_sale;
    reg         main_select_admin;
    reg         main_error_req;
    reg  [3:0]  main_error_code;

    wire [2:0]  current_mode;
    wire        sale_mode_en;
    wire        auth_mode_en;
    wire        admin_mode_en;
    wire        alarm_mode_en;

    wire [7:0]  price0;
    wire [7:0]  price1;
    wire [7:0]  price2;
    wire [7:0]  price3;
    wire [4:0]  stock0;
    wire [4:0]  stock1;
    wire [4:0]  stock2;
    wire [4:0]  stock3;
    wire [3:0]  enabled;
    wire [15:0] sales_total;

    wire [3:0]  sale_state;
    wire [1:0]  sale_selected_item;
    wire [7:0]  sale_latched_price;
    wire [7:0]  paid_amount;
    wire        sale_back_req;
    wire        sale_home_req;
    wire        order_timer_start;
    wire        order_timer_stop;
    wire        sale_stock_dec_req;
    wire        sale_stock_inc_req;
    wire        sale_total_add_req;
    wire [1:0]  sale_item_idx;
    wire [7:0]  sale_amount;
    wire        sale_error_req;
    wire [3:0]  sale_error_code;
    wire [2:0]  remaining_sec;
    wire        order_timeout;
    wire        order_timer_running;

    wire [2:0]  auth_state;
    wire [7:0]  password_value;
    wire [1:0]  wrong_count;
    wire        auth_ok;
    wire        auth_back_req;
    wire        auth_home_req;
    wire        alarm_trigger;
    wire        auth_error_req;
    wire [3:0]  auth_error_code;

    wire [3:0]  admin_state;
    wire [2:0]  admin_selected_func;
    wire [1:0]  admin_selected_item;
    wire [7:0]  admin_input_value;
    wire        admin_back_req;
    wire        admin_home_req;
    wire        admin_set_price_req;
    wire        admin_add_stock_req;
    wire        admin_toggle_enable_req;
    wire [1:0]  admin_item_idx;
    wire [7:0]  admin_value;
    wire        admin_error_req;
    wire [3:0]  admin_error_code;
    wire [15:0] buffer_current_value;
    wire [3:0]  buffer_digit_count;
    wire        buffer_input_nonempty;
    wire        buffer_input_done;
    wire        buffer_input_error;

    reg         alarm_done;
    reg  [2:0]  alarm_elapsed_sec;

    reg         error_req_mux;
    reg  [3:0]  error_code_mux;
    wire        error_active;
    wire [3:0]  display_error_code;
    wire [3:0]  error_return_target;
    wire        error_done;

    wire [1:0]  ui_selected_item_src;
    wire [2:0]  ui_selected_menu_src;
    wire [15:0] ui_input_value_src;
    wire [7:0]  auth_display_value;
    wire [4:0]  ui_page;
    wire [2:0]  ui_mode;
    wire [1:0]  ui_selected_item;
    wire [2:0]  ui_selected_menu;
    wire [15:0] ui_input_value;
    wire [3:0]  ui_error_code;
    wire [2:0]  ui_countdown;
    wire        ui_alarm_active;
    wire [127:0] ui_data_bus;
    wire [3:0]  ui_error_code_src;

    wire        beep_enable;
    wire [2:0]  beep_type;
    wire        key_beep_req;
    wire        error_beep_req;
    wire        success_beep_req;
    wire        countdown_beep_req;
    wire        alarm_beep_active;
    wire [3:0]  vga_r;
    wire [3:0]  vga_g;
    wire [3:0]  vga_b;

    assign clk = sys_clk_in;

    assign col_in = exp_io[7:4];
    assign exp_io[0] = row_active[0] ? 1'b0 : 1'bz;
    assign exp_io[1] = row_active[1] ? 1'b0 : 1'bz;
    assign exp_io[2] = row_active[2] ? 1'b0 : 1'bz;
    assign exp_io[3] = row_active[3] ? 1'b0 : 1'bz;
    assign exp_io[7:4] = 4'bzzzz;
    assign core_event_valid = event_valid && !error_active;

    assign ui_selected_item_src = sale_mode_en ? sale_selected_item : admin_selected_item;
    assign ui_selected_menu_src = admin_mode_en ? admin_selected_func : main_selected_menu;
    assign auth_display_value   = ({4'd0, password_value[7:4]} * 8'd10) +
                                  {4'd0, password_value[3:0]};
    assign ui_input_value_src   = sale_mode_en  ? {8'd0, paid_amount} :
                                  auth_mode_en  ? {8'd0, auth_display_value} :
                                  admin_mode_en ? {8'd0, admin_input_value} :
                                                  buffer_current_value;
    assign vga_data_pin = {vga_b, vga_g, vga_r};
    assign ui_error_code_src = error_active ? display_error_code :
                               (sale_state == `SALE_STATE_ERROR_DISPLAY) ? sale_error_code :
                               ((auth_state == `AUTH_STATE_FAIL_DISPLAY) ||
                                (auth_state == `AUTH_STATE_ERROR_DISPLAY)) ? auth_error_code :
                               `ERR_NONE;

    reset_sync u_reset_sync (
        .clk       (clk),
        .sys_rst_n (sys_rst_n),
        .rst       (rst)
    );

    tick_gen u_tick_gen (
        .clk        (clk),
        .rst        (rst),
        .tick_1ms   (tick_1ms),
        .tick_10ms  (tick_10ms),
        .tick_100ms (tick_100ms),
        .tick_1s    (tick_1s),
        .pix_en     (pix_en)
    );

    matrix_keypad_scanner u_matrix_keypad_scanner (
        .clk            (clk),
        .rst            (rst),
        .tick_1ms       (tick_1ms),
        .col_in         (col_in),
        .row_active     (row_active),
        .scan_key_valid (scan_key_valid),
        .scan_key_row   (scan_key_row),
        .scan_key_col   (scan_key_col)
    );

    key_decoder u_key_decoder (
        .scan_key_valid (scan_key_valid),
        .scan_key_row   (scan_key_row),
        .scan_key_col   (scan_key_col),
        .key_valid      (key_valid),
        .key_code       (key_code)
    );

    input_event_router u_input_event_router (
        .key_valid   (key_valid),
        .key_code    (key_code),
        .event_valid (event_valid),
        .event_type  (event_type),
        .event_value (event_value)
    );

    main_mode_fsm u_main_mode_fsm (
        .clk               (clk),
        .rst               (rst),
        .main_select_sale  (main_select_sale),
        .main_select_admin (main_select_admin),
        .sale_back_req     (sale_back_req),
        .sale_home_req     (sale_home_req),
        .auth_ok           (auth_ok),
        .auth_back_req     (auth_back_req),
        .auth_home_req     (auth_home_req),
        .alarm_trigger     (alarm_trigger),
        .admin_back_req    (admin_back_req),
        .admin_home_req    (admin_home_req),
        .alarm_done        (alarm_done),
        .current_mode      (current_mode),
        .sale_mode_en      (sale_mode_en),
        .auth_mode_en      (auth_mode_en),
        .admin_mode_en     (admin_mode_en),
        .alarm_mode_en     (alarm_mode_en)
    );

    sale_engine u_sale_engine (
        .clk                (clk),
        .rst                (rst),
        .mode_en            (sale_mode_en),
        .event_valid        (core_event_valid),
        .event_type         (event_type),
        .event_value        (event_value),
        .tick_1s            (tick_1s),
        .price0             (price0),
        .price1             (price1),
        .price2             (price2),
        .price3             (price3),
        .stock0             (stock0),
        .stock1             (stock1),
        .stock2             (stock2),
        .stock3             (stock3),
        .enabled            (enabled),
        .remaining_sec      (remaining_sec),
        .order_timeout      (order_timeout),
        .sale_state         (sale_state),
        .selected_item      (sale_selected_item),
        .latched_price      (sale_latched_price),
        .paid_amount        (paid_amount),
        .sale_back_req      (sale_back_req),
        .sale_home_req      (sale_home_req),
        .order_timer_start  (order_timer_start),
        .order_timer_stop   (order_timer_stop),
        .sale_stock_dec_req (sale_stock_dec_req),
        .sale_stock_inc_req (sale_stock_inc_req),
        .sale_total_add_req (sale_total_add_req),
        .sale_item_idx      (sale_item_idx),
        .sale_amount        (sale_amount),
        .error_req          (sale_error_req),
        .error_code         (sale_error_code)
    );

    order_timer u_order_timer (
        .clk           (clk),
        .rst           (rst),
        .tick_1s       (tick_1s),
        .start         (order_timer_start),
        .stop          (order_timer_stop),
        .remaining_sec (remaining_sec),
        .timeout       (order_timeout),
        .running       (order_timer_running)
    );

    admin_mode_subsystem u_admin_mode_subsystem (
        .clk                     (clk),
        .rst                     (rst),
        .tick_1s                 (tick_1s),
        .auth_mode_en            (auth_mode_en),
        .admin_mode_en           (admin_mode_en),
        .event_valid             (core_event_valid),
        .event_type              (event_type),
        .event_value             (event_value),
        .sale_stock_dec_req      (sale_stock_dec_req),
        .sale_stock_inc_req      (sale_stock_inc_req),
        .sale_total_add_req      (sale_total_add_req),
        .sale_item_idx           (sale_item_idx),
        .sale_amount             (sale_amount),
        .price0                  (price0),
        .price1                  (price1),
        .price2                  (price2),
        .price3                  (price3),
        .stock0                  (stock0),
        .stock1                  (stock1),
        .stock2                  (stock2),
        .stock3                  (stock3),
        .enabled                 (enabled),
        .sales_total             (sales_total),
        .auth_state              (auth_state),
        .password_value          (password_value),
        .wrong_count             (wrong_count),
        .auth_ok                 (auth_ok),
        .auth_back_req           (auth_back_req),
        .auth_home_req           (auth_home_req),
        .alarm_trigger           (alarm_trigger),
        .auth_error_req          (auth_error_req),
        .auth_error_code         (auth_error_code),
        .admin_state             (admin_state),
        .selected_func           (admin_selected_func),
        .selected_item           (admin_selected_item),
        .input_value             (admin_input_value),
        .admin_back_req          (admin_back_req),
        .admin_home_req          (admin_home_req),
        .admin_set_price_req     (admin_set_price_req),
        .admin_add_stock_req     (admin_add_stock_req),
        .admin_toggle_enable_req (admin_toggle_enable_req),
        .admin_item_idx          (admin_item_idx),
        .admin_value             (admin_value),
        .admin_error_req         (admin_error_req),
        .admin_error_code        (admin_error_code),
        .buffer_current_value    (buffer_current_value),
        .buffer_digit_count      (buffer_digit_count),
        .buffer_input_nonempty   (buffer_input_nonempty),
        .buffer_input_done       (buffer_input_done),
        .buffer_input_error      (buffer_input_error)
    );

    error_manager u_error_manager (
        .clk                (clk),
        .rst                (rst),
        .tick_1s            (tick_1s),
        .error_req          (error_req_mux),
        .error_code_in      (error_code_mux),
        .return_target_in   ({1'b0, current_mode}),
        .error_active       (error_active),
        .display_error_code (display_error_code),
        .return_target      (error_return_target),
        .error_done         (error_done)
    );

    ui_snapshot_packer u_ui_snapshot_packer (
        .current_mode     (current_mode),
        .sale_state       (sale_state),
        .admin_state      (admin_state),
        .auth_state       (auth_state),
        .selected_item    (ui_selected_item_src),
        .selected_menu    (ui_selected_menu_src),
        .input_value      (ui_input_value_src),
        .price0           (price0),
        .price1           (price1),
        .price2           (price2),
        .price3           (price3),
        .stock0           (stock0),
        .stock1           (stock1),
        .stock2           (stock2),
        .stock3           (stock3),
        .enabled          (enabled),
        .sales_total      (sales_total),
        .remaining_sec    (remaining_sec),
        .error_active     (error_active),
        .error_code       (ui_error_code_src),
        .alarm_active     (alarm_mode_en),
        .ui_page          (ui_page),
        .ui_mode          (ui_mode),
        .ui_selected_item (ui_selected_item),
        .ui_selected_menu (ui_selected_menu),
        .ui_input_value   (ui_input_value),
        .ui_error_code    (ui_error_code),
        .ui_countdown     (ui_countdown),
        .ui_alarm_active  (ui_alarm_active),
        .ui_data_bus      (ui_data_bus)
    );

    buzzer_request_adapter u_buzzer_request_adapter (
        .event_valid             (core_event_valid),
        .tick_1s                 (tick_1s),
        .sale_state              (sale_state),
        .remaining_sec           (remaining_sec),
        .sale_total_add_req      (sale_total_add_req),
        .sale_error_req          (sale_error_req),
        .auth_ok                 (auth_ok),
        .auth_error_req          (auth_error_req),
        .admin_set_price_req     (admin_set_price_req),
        .admin_add_stock_req     (admin_add_stock_req),
        .admin_toggle_enable_req (admin_toggle_enable_req),
        .admin_error_req         (admin_error_req),
        .alarm_mode_en           (alarm_mode_en),
        .key_beep_req            (key_beep_req),
        .error_beep_req          (error_beep_req),
        .success_beep_req        (success_beep_req),
        .countdown_beep_req      (countdown_beep_req),
        .alarm_active            (alarm_beep_active)
    );

    led_controller u_led_controller (
        .clk             (clk),
        .rst             (rst),
        .tick_100ms      (tick_100ms),
        .ui_page         (ui_page),
        .ui_mode         (ui_mode),
        .ui_error_code   (ui_error_code),
        .ui_alarm_active (ui_alarm_active),
        .led_pin         (led_pin)
    );

    sevenseg_controller u_sevenseg_controller (
        .clk             (clk),
        .rst             (rst),
        .tick_1ms        (tick_1ms),
        .ui_page         (ui_page),
        .ui_input_value  (ui_input_value),
        .ui_countdown    (ui_countdown),
        .ui_error_code   (ui_error_code),
        .ui_alarm_active (ui_alarm_active),
        .ui_data_bus     (ui_data_bus),
        .seg_cs_pin      (seg_cs_pin),
        .seg_data_0_pin  (seg_data_0_pin),
        .seg_data_1_pin  (seg_data_1_pin)
    );

    buzzer_controller u_buzzer_controller (
        .clk                (clk),
        .rst                (rst),
        .tick_100ms         (tick_100ms),
        .key_beep_req       (key_beep_req),
        .error_beep_req     (error_beep_req),
        .success_beep_req   (success_beep_req),
        .countdown_beep_req (countdown_beep_req),
        .alarm_active       (alarm_beep_active),
        .beep_enable        (beep_enable),
        .beep_type          (beep_type)
    );

    audio_pwm_driver u_audio_pwm_driver (
        .clk         (clk),
        .rst         (rst),
        .beep_enable (beep_enable),
        .beep_type   (beep_type),
        .audio_pwm_o (audio_pwm_o),
        .audio_sd_o  (audio_sd_o)
    );

    vga_system u_vga_system (
        .clk        (clk),
        .rst        (rst),
        .pix_en     (pix_en),
        .ui_page    (ui_page),
        .ui_data_bus(ui_data_bus),
        .vga_hsync  (vga_hs_pin),
        .vga_vsync  (vga_vs_pin),
        .vga_r      (vga_r),
        .vga_g      (vga_g),
        .vga_b      (vga_b)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            main_selected_menu <= 3'd1;
            main_select_sale   <= 1'b0;
            main_select_admin  <= 1'b0;
            main_error_req     <= 1'b0;
            main_error_code    <= `ERR_NONE;
        end else begin
            main_select_sale  <= 1'b0;
            main_select_admin <= 1'b0;
            main_error_req    <= 1'b0;
            main_error_code   <= `ERR_NONE;

            if ((current_mode == `MODE_MAIN_MENU) && core_event_valid) begin
                case (event_type)
                    `EV_DIGIT: begin
                        if ((event_value == 4'd1) || (event_value == 4'd2)) begin
                            main_selected_menu <= event_value[2:0];
                        end else begin
                            main_error_req  <= 1'b1;
                            main_error_code <= `ERR_INVALID_INPUT;
                        end
                    end
                    `EV_PREV,
                    `EV_NEXT: begin
                        main_selected_menu <= (main_selected_menu == 3'd1) ? 3'd2 : 3'd1;
                    end
                    `EV_CONFIRM: begin
                        if (main_selected_menu == 3'd1) begin
                            main_select_sale <= 1'b1;
                        end else begin
                            main_select_admin <= 1'b1;
                        end
                    end
                    default: begin
                        main_error_req  <= 1'b1;
                        main_error_code <= `ERR_INVALID_INPUT;
                    end
                endcase
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alarm_elapsed_sec <= 3'd0;
            alarm_done        <= 1'b0;
        end else begin
            alarm_done <= 1'b0;

            if (!alarm_mode_en) begin
                alarm_elapsed_sec <= 3'd0;
            end else if (tick_1s) begin
                if (alarm_elapsed_sec >= 3'd4) begin
                    alarm_elapsed_sec <= 3'd0;
                    alarm_done        <= 1'b1;
                end else begin
                    alarm_elapsed_sec <= alarm_elapsed_sec + 3'd1;
                end
            end
        end
    end

    always @(*) begin
        error_req_mux  = 1'b0;
        error_code_mux = `ERR_NONE;

        if (alarm_mode_en) begin
            error_req_mux  = 1'b0;
            error_code_mux = `ERR_NONE;
        end else if (main_error_req) begin
            error_req_mux  = 1'b1;
            error_code_mux = main_error_code;
        end else if (admin_error_req) begin
            error_req_mux  = 1'b1;
            error_code_mux = admin_error_code;
        end
    end

endmodule
