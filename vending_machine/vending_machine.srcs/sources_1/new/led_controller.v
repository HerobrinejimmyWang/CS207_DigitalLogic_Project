`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module led_controller (
    input               clk,
    input               rst,
    input               tick_100ms,
    input       [4:0]   ui_page,
    input       [2:0]   ui_mode,
    input       [3:0]   ui_error_code,
    input               ui_alarm_active,
    output reg  [15:0]  led_pin
);

    localparam [4:0] UI_PAGE_SALE_WAIT_TAKE = 5'd4;

    reg [7:0] running_light;
    reg       alarm_flash_on;

    reg [3:0] mode_leds;
    reg [7:0] anim_leds;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running_light  <= 8'b0000_0001;
            alarm_flash_on <= 1'b0;
        end else if (ui_alarm_active) begin
            running_light <= 8'b0000_0001;

            if (tick_100ms) begin
                alarm_flash_on <= ~alarm_flash_on;
            end
        end else if (ui_page == UI_PAGE_SALE_WAIT_TAKE) begin
            alarm_flash_on <= 1'b0;

            if (tick_100ms) begin
                running_light <= {running_light[6:0], running_light[7]};
            end
        end else begin
            running_light  <= 8'b0000_0001;
            alarm_flash_on <= 1'b0;
        end
    end

    always @(*) begin
        mode_leds = 4'b0000;
        anim_leds = 8'b0000_0000;

        if (!ui_alarm_active && (ui_mode != `MODE_ALARM)) begin
            case (ui_mode)
                `MODE_MAIN_MENU: mode_leds = 4'b1000;
                `MODE_SALE:      mode_leds = 4'b0100;
                `MODE_AUTH:      mode_leds = 4'b0010;
                `MODE_ADMIN:     mode_leds = 4'b0001;
                default:         mode_leds = 4'b0000;
            endcase
        end

        if (ui_alarm_active) begin
            anim_leds = alarm_flash_on ? 8'hFF : 8'h00;
        end else if (ui_page == UI_PAGE_SALE_WAIT_TAKE) begin
            anim_leds = running_light;
        end

        led_pin[15:12] = mode_leds;
        led_pin[11:8]  = ui_error_code;
        led_pin[7:0]   = anim_leds;
    end

endmodule
