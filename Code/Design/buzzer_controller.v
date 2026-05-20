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

    reg [3:0] tone_ticks_left;

    function [3:0] tone_duration_ticks;
        input [2:0] requested_type;
        begin
            case (requested_type)
                `BEEP_TYPE_ERROR:     tone_duration_ticks = 4'd3;
                `BEEP_TYPE_SUCCESS:   tone_duration_ticks = 4'd2;
                `BEEP_TYPE_COUNTDOWN: tone_duration_ticks = 4'd1;
                `BEEP_TYPE_KEY:       tone_duration_ticks = 4'd1;
                default:              tone_duration_ticks = 4'd0;
            endcase
        end
    endfunction

    reg       request_valid;
    reg [2:0] request_type;

    always @(*) begin
        request_valid = 1'b0;
        request_type  = `BEEP_TYPE_NONE;

        if (error_beep_req) begin
            request_valid = 1'b1;
            request_type  = `BEEP_TYPE_ERROR;
        end else if (success_beep_req) begin
            request_valid = 1'b1;
            request_type  = `BEEP_TYPE_SUCCESS;
        end else if (countdown_beep_req) begin
            request_valid = 1'b1;
            request_type  = `BEEP_TYPE_COUNTDOWN;
        end else if (key_beep_req) begin
            request_valid = 1'b1;
            request_type  = `BEEP_TYPE_KEY;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            beep_enable     <= 1'b0;
            beep_type       <= `BEEP_TYPE_NONE;
            tone_ticks_left <= 4'd0;
        end else begin
            if (alarm_active) begin
                beep_enable     <= 1'b1;
                beep_type       <= `BEEP_TYPE_ALARM;
                tone_ticks_left <= 4'd0;
            end else if (request_valid) begin
                beep_enable     <= 1'b1;
                beep_type       <= request_type;
                tone_ticks_left <= tone_duration_ticks(request_type);
            end else if (beep_type == `BEEP_TYPE_ALARM) begin
                beep_enable     <= 1'b0;
                beep_type       <= `BEEP_TYPE_NONE;
                tone_ticks_left <= 4'd0;
            end else if (beep_enable && (beep_type != `BEEP_TYPE_NONE)) begin
                if (tick_100ms) begin
                    if (tone_ticks_left > 4'd1) begin
                        tone_ticks_left <= tone_ticks_left - 4'd1;
                    end else begin
                        tone_ticks_left <= 4'd0;
                        beep_enable     <= 1'b0;
                        beep_type       <= `BEEP_TYPE_NONE;
                    end
                end
            end else begin
                beep_enable     <= 1'b0;
                beep_type       <= `BEEP_TYPE_NONE;
                tone_ticks_left <= 4'd0;
            end
        end
    end

endmodule
