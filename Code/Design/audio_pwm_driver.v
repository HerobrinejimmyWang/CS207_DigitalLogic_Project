`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module audio_pwm_driver #(
    parameter KEY_HALF_PERIOD       = 32'd25000,   // 2 kHz at 100 MHz
    parameter ERROR_HALF_PERIOD     = 32'd125000,  // 400 Hz at 100 MHz
    parameter SUCCESS_HALF_PERIOD   = 32'd50000,   // 1 kHz at 100 MHz
    parameter COUNTDOWN_HALF_PERIOD = 32'd33333,   // about 1.5 kHz at 100 MHz
    parameter ALARM_HALF_PERIOD     = 32'd62500    // 800 Hz at 100 MHz
) (
    input            clk,
    input            rst,
    input            beep_enable,
    input      [2:0] beep_type,
    output reg       audio_pwm_o,
    output reg       audio_sd_o
);

    reg [31:0] tone_counter;
    reg [2:0]  active_beep_type;

    function [31:0] half_period_for_type;
        input [2:0] requested_type;
        begin
            case (requested_type)
                `BEEP_TYPE_KEY:       half_period_for_type = KEY_HALF_PERIOD;
                `BEEP_TYPE_ERROR:     half_period_for_type = ERROR_HALF_PERIOD;
                `BEEP_TYPE_SUCCESS:   half_period_for_type = SUCCESS_HALF_PERIOD;
                `BEEP_TYPE_COUNTDOWN: half_period_for_type = COUNTDOWN_HALF_PERIOD;
                `BEEP_TYPE_ALARM:     half_period_for_type = ALARM_HALF_PERIOD;
                default:              half_period_for_type = 32'd0;
            endcase
        end
    endfunction

    wire [31:0] selected_half_period = half_period_for_type(beep_type);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            audio_pwm_o     <= 1'b0;
            audio_sd_o      <= 1'b0;
            tone_counter    <= 32'd0;
            active_beep_type <= `BEEP_TYPE_NONE;
        end else begin
            if (!beep_enable ||
                (beep_type == `BEEP_TYPE_NONE) ||
                (selected_half_period == 32'd0)) begin
                audio_pwm_o      <= 1'b0;
                audio_sd_o       <= 1'b0;
                tone_counter     <= 32'd0;
                active_beep_type <= `BEEP_TYPE_NONE;
            end else begin
                audio_sd_o <= 1'b1;

                if (active_beep_type != beep_type) begin
                    active_beep_type <= beep_type;
                    audio_pwm_o      <= 1'b0;
                    tone_counter     <= selected_half_period - 32'd1;
                end else if (tone_counter == 32'd0) begin
                    audio_pwm_o  <= ~audio_pwm_o;
                    tone_counter <= selected_half_period - 32'd1;
                end else begin
                    tone_counter <= tone_counter - 32'd1;
                end
            end
        end
    end

endmodule
