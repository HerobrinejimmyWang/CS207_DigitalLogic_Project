`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module buzzer_controller (
    input            clk,
    input            rst,
    input            tick_100ms,
    input            key_beep_req,
    input            error_beep_req,
    input            success_beep_req,
    input            countdown_beep_req,
    input            alarm_active,
    output reg       beep_enable,
    output reg [2:0] beep_type
);

    reg [1:0] ticks_remaining;
    reg [2:0] requested_type;
    reg       requested_valid;

    function [2:0] request_priority;
        input [2:0] type_value;
        begin
            case (type_value)
                `BEEP_TYPE_KEY:       request_priority = 3'd1;
                `BEEP_TYPE_COUNTDOWN: request_priority = 3'd2;
                `BEEP_TYPE_SUCCESS:   request_priority = 3'd3;
                `BEEP_TYPE_ERROR:     request_priority = 3'd4;
                default:              request_priority = 3'd0;
            endcase
        end
    endfunction

    function [1:0] request_duration;
        input [2:0] type_value;
        begin
            case (type_value)
                `BEEP_TYPE_ERROR:     request_duration = 2'd3;
                `BEEP_TYPE_SUCCESS:   request_duration = 2'd2;
                `BEEP_TYPE_KEY,
                `BEEP_TYPE_COUNTDOWN: request_duration = 2'd1;
                default:              request_duration = 2'd0;
            endcase
        end
    endfunction

    always @(*) begin
        requested_valid = 1'b1;
        requested_type  = `BEEP_TYPE_ERROR;

        if (error_beep_req) begin
            requested_type = `BEEP_TYPE_ERROR;
        end else if (success_beep_req) begin
            requested_type = `BEEP_TYPE_SUCCESS;
        end else if (countdown_beep_req) begin
            requested_type = `BEEP_TYPE_COUNTDOWN;
        end else if (key_beep_req) begin
            requested_type = `BEEP_TYPE_KEY;
        end else begin
            requested_valid = 1'b0;
            requested_type  = `BEEP_TYPE_NONE;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            beep_enable     <= 1'b0;
            beep_type       <= `BEEP_TYPE_NONE;
            ticks_remaining <= 2'd0;
        end else if (alarm_active) begin
            beep_enable     <= 1'b1;
            beep_type       <= `BEEP_TYPE_ALARM;
            ticks_remaining <= 2'd0;
        end else begin
            if (requested_valid &&
                ((!beep_enable) ||
                 (beep_type == `BEEP_TYPE_ALARM) ||
                 (request_priority(requested_type) > request_priority(beep_type)))) begin
                beep_enable     <= 1'b1;
                beep_type       <= requested_type;
                ticks_remaining <= request_duration(requested_type);
            end else if (beep_enable && (beep_type != `BEEP_TYPE_ALARM)) begin
                if (tick_100ms) begin
                    if (ticks_remaining <= 2'd1) begin
                        beep_enable     <= 1'b0;
                        beep_type       <= `BEEP_TYPE_NONE;
                        ticks_remaining <= 2'd0;
                    end else begin
                        ticks_remaining <= ticks_remaining - 2'd1;
                    end
                end
            end else begin
                beep_enable     <= 1'b0;
                beep_type       <= `BEEP_TYPE_NONE;
                ticks_remaining <= 2'd0;
            end
        end
    end

endmodule
