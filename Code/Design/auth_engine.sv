`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module auth_engine (
    input  logic        clk,
    input  logic        rst,
    input  logic        mode_en,
    input  logic        event_valid,
    input  logic [2:0]  event_type,
    input  logic [3:0]  event_value,
    input  logic        tick_1s,
    input  logic [15:0] buf_current_value,
    input  logic        buf_input_nonempty,
    input  logic        buf_input_done,
    input  logic        buf_input_error,
    output logic [2:0]  auth_state,
    output logic [7:0]  password_value,
    output logic [1:0]  wrong_count,
    output logic        auth_ok,
    output logic        auth_back_req,
    output logic        auth_home_req,
    output logic        alarm_trigger,
    output logic        error_req,
    output logic [3:0]  error_code,
    output logic [2:0]  buf_input_mode,
    output logic        buf_load_req,
    output logic        buf_clear_req,
    output logic        buf_commit_req
);

    // Shared encodings in admin_mode_defs.vh:
    // AUTH_INPUT=0, AUTH_CHECK=1, AUTH_FAIL_DISPLAY=2, AUTH_SUCCESS=3,
    // AUTH_ERROR_DISPLAY=4. Password input mode is PASSWORD_BCD2=4.

    logic       mode_en_d;
    logic [7:0] pending_password;

    assign buf_input_mode = mode_en ? `INPUT_MODE_PASSWORD_BCD2
                                    : `INPUT_MODE_IDLE;
    assign password_value = (auth_state == `AUTH_STATE_INPUT)
                          ? buf_current_value[7:0]
                          : pending_password;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            auth_state       <= `AUTH_STATE_INPUT;
            pending_password <= 8'd0;
            wrong_count      <= 2'd0;
            auth_ok          <= 1'b0;
            auth_back_req    <= 1'b0;
            auth_home_req    <= 1'b0;
            alarm_trigger    <= 1'b0;
            error_req        <= 1'b0;
            error_code       <= `ERR_NONE;
            buf_load_req     <= 1'b0;
            buf_clear_req    <= 1'b0;
            buf_commit_req   <= 1'b0;
            mode_en_d        <= 1'b0;
        end else begin
            auth_ok        <= 1'b0;
            auth_back_req  <= 1'b0;
            auth_home_req  <= 1'b0;
            alarm_trigger  <= 1'b0;
            error_req      <= 1'b0;
            error_code     <= `ERR_NONE;
            buf_load_req   <= 1'b0;
            buf_clear_req  <= 1'b0;
            buf_commit_req <= 1'b0;
            mode_en_d      <= mode_en;

            if (!mode_en) begin
                auth_state       <= `AUTH_STATE_INPUT;
                pending_password <= 8'd0;
                wrong_count      <= 2'd0;
            end else begin
                if (!mode_en_d) begin
                    auth_state       <= `AUTH_STATE_INPUT;
                    pending_password <= 8'd0;
                    wrong_count      <= 2'd0;
                    buf_load_req     <= 1'b1;
                end else begin
                    case (auth_state)
                        `AUTH_STATE_INPUT: begin
                            if (buf_input_done) begin
                                pending_password <= buf_current_value[7:0];
                                buf_clear_req    <= 1'b1;
                                auth_state       <= `AUTH_STATE_CHECK;
                            end else if (buf_input_error) begin
                                error_req  <= 1'b1;
                                error_code <= `ERR_INVALID_INPUT;
                                auth_state <= `AUTH_STATE_ERROR_DISPLAY;
                            end else if (event_valid) begin
                                case (event_type)
                                    `EV_BACK: begin
                                        auth_back_req <= 1'b1;
                                        wrong_count   <= 2'd0;
                                        buf_clear_req <= 1'b1;
                                    end
                                    `EV_HOME: begin
                                        auth_home_req <= 1'b1;
                                        wrong_count   <= 2'd0;
                                        buf_clear_req <= 1'b1;
                                    end
                                    `EV_PREV,
                                    `EV_NEXT: begin
                                        error_req  <= 1'b1;
                                        error_code <= `ERR_INVALID_INPUT;
                                        auth_state <= `AUTH_STATE_ERROR_DISPLAY;
                                    end
                                    `EV_CLEAR: begin
                                        buf_clear_req <= 1'b1;
                                    end
                                    `EV_CONFIRM: begin
                                        buf_commit_req <= 1'b1;
                                    end
                                    default: begin
                                        // Digits are consumed by numeric_input_buffer.
                                    end
                                endcase
                            end
                        end

                        `AUTH_STATE_CHECK: begin
                            if (pending_password == 8'h42) begin
                                auth_ok     <= 1'b1;
                                wrong_count <= 2'd0;
                                auth_state  <= `AUTH_STATE_SUCCESS;
                            end else begin
                                error_req  <= 1'b1;
                                error_code <= `ERR_WRONG_PASSWORD;
                                auth_state <= `AUTH_STATE_FAIL_DISPLAY;
                                if (wrong_count == 2'd2) begin
                                    wrong_count   <= 2'd3;
                                    alarm_trigger <= 1'b1;
                                end else begin
                                    wrong_count <= wrong_count + 2'd1;
                                end
                            end
                        end

                        `AUTH_STATE_FAIL_DISPLAY: begin
                            if (tick_1s) begin
                                auth_state   <= `AUTH_STATE_INPUT;
                                buf_load_req <= 1'b1;
                            end
                        end

                        `AUTH_STATE_SUCCESS: begin
                            auth_state       <= `AUTH_STATE_INPUT;
                            pending_password <= 8'd0;
                            buf_load_req     <= 1'b1;
                        end

                        `AUTH_STATE_ERROR_DISPLAY: begin
                            if (tick_1s) begin
                                auth_state   <= `AUTH_STATE_INPUT;
                                buf_load_req <= 1'b1;
                            end
                        end

                        default: begin
                            auth_state <= `AUTH_STATE_INPUT;
                        end
                    endcase
                end
            end
        end
    end

endmodule
