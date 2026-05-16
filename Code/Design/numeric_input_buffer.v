`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module numeric_input_buffer (
    input               clk,
    input               rst,
    input               event_valid,
    input       [2:0]   event_type,
    input       [3:0]   event_value,
    input       [2:0]   input_mode,
    input               load_req,
    input               clear_req,
    input               commit_req,
    output reg  [15:0]  current_value,
    output reg  [3:0]   digit_count,
    output reg          input_nonempty,
    output reg          input_done,
    output reg          input_error
);

    // Shared encodings are defined in admin_mode_defs.vh:
    // SINGLE_ID=0, AMOUNT=1, PRICE=2, STOCK=3, PASSWORD_BCD2=4, IDLE=7.
    // INPUT_MODE_AMOUNT is intentionally capped at 255 so the accumulated value
    // always fits in the downstream 8-bit payment path used by this project.

    function [3:0] mode_max_digits;
        input [2:0] mode;
        begin
            case (mode)
                `INPUT_MODE_SINGLE_ID:     mode_max_digits = 4'd1;
                `INPUT_MODE_AMOUNT:        mode_max_digits = 4'd3;
                `INPUT_MODE_PRICE:         mode_max_digits = 4'd2;
                `INPUT_MODE_STOCK:         mode_max_digits = 4'd2;
                `INPUT_MODE_PASSWORD_BCD2: mode_max_digits = 4'd2;
                default:                   mode_max_digits = 4'd0;
            endcase
        end
    endfunction

    function commit_valid;
        input [2:0]  mode;
        input [15:0] value;
        input [3:0]  count;
        begin
            case (mode)
                `INPUT_MODE_SINGLE_ID:
                    commit_valid = (count == 4'd1) &&
                                   (value >= 16'd1) &&
                                   (value <= 16'd4);
                `INPUT_MODE_AMOUNT:
                    commit_valid = (count >= 4'd1) &&
                                   (value <= 16'd255);
                `INPUT_MODE_PRICE:
                    commit_valid = (count >= 4'd1) &&
                                   (value >= 16'd1) &&
                                   (value <= 16'd15);
                `INPUT_MODE_STOCK:
                    commit_valid = (count >= 4'd1) &&
                                   (value >= 16'd1) &&
                                   (value <= 16'd15);
                `INPUT_MODE_PASSWORD_BCD2:
                    commit_valid = (count == 4'd2) &&
                                   (value[7:4] <= 4'd9) &&
                                   (value[3:0] <= 4'd9);
                default:
                    commit_valid = 1'b0;
            endcase
        end
    endfunction

    reg [15:0] next_numeric_value;
    reg [15:0] next_bcd_value;

    always @(*) begin
        next_numeric_value = (current_value * 16'd10) + {12'd0, event_value};
        next_bcd_value     = {current_value[11:0], event_value};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_value  <= 16'd0;
            digit_count    <= 4'd0;
            input_nonempty <= 1'b0;
            input_done     <= 1'b0;
            input_error    <= 1'b0;
        end else begin
            input_done  <= 1'b0;
            input_error <= 1'b0;

            if (load_req || clear_req) begin
                current_value  <= 16'd0;
                digit_count    <= 4'd0;
                input_nonempty <= 1'b0;
            end else begin
                if (event_valid &&
                    (event_type == `EV_DIGIT) &&
                    (input_mode != `INPUT_MODE_IDLE)) begin
                    if (digit_count < mode_max_digits(input_mode)) begin
                        if (input_mode == `INPUT_MODE_PASSWORD_BCD2) begin
                            current_value <= next_bcd_value;
                        end else begin
                            current_value <= next_numeric_value;
                        end
                        digit_count    <= digit_count + 4'd1;
                        input_nonempty <= 1'b1;
                    end else begin
                        input_error <= 1'b1;
                    end
                end

                if (commit_req && (input_mode != `INPUT_MODE_IDLE)) begin
                    if (commit_valid(input_mode, current_value, digit_count)) begin
                        input_done <= 1'b1;
                    end else begin
                        input_error <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
