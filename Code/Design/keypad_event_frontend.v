`timescale 1ns / 1ps

module keypad_event_frontend #(
    parameter DEBOUNCE_SAMPLES = 5,
    parameter RELEASE_SAMPLES  = 3
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1ms,
    input  wire [3:0] col_in,
    output wire [3:0] row_active,
    output wire       event_valid,
    output wire [2:0] event_type,
    output wire [3:0] event_value
);

    wire       scan_key_valid;
    wire [1:0] scan_key_row;
    wire [1:0] scan_key_col;
    wire       key_valid;
    wire [3:0] key_code;

    matrix_keypad_scanner #(
        .DEBOUNCE_SAMPLES(DEBOUNCE_SAMPLES),
        .RELEASE_SAMPLES (RELEASE_SAMPLES)
    ) u_matrix_keypad_scanner (
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

endmodule
