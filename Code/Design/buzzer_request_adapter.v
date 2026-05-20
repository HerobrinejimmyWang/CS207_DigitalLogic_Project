`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module buzzer_request_adapter (
    input             event_valid,
    input             tick_1s,
    input      [3:0]  sale_state,
    input      [2:0]  remaining_sec,
    input             sale_total_add_req,
    input             sale_error_req,
    input             auth_ok,
    input             auth_error_req,
    input             admin_set_price_req,
    input             admin_add_stock_req,
    input             admin_toggle_enable_req,
    input             admin_error_req,
    input             alarm_mode_en,
    output wire       key_beep_req,
    output wire       error_beep_req,
    output wire       success_beep_req,
    output wire       countdown_beep_req,
    output wire       alarm_active
);

    assign key_beep_req       = event_valid;
    assign error_beep_req     = sale_error_req | auth_error_req | admin_error_req;
    assign success_beep_req   = sale_total_add_req |
                                auth_ok |
                                admin_set_price_req |
                                admin_add_stock_req |
                                admin_toggle_enable_req;
    assign countdown_beep_req = tick_1s &&
                                (sale_state == `SALE_STATE_WAIT_TAKE) &&
                                (remaining_sec != 3'd0);
    assign alarm_active       = alarm_mode_en;

endmodule
