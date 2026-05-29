`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module main_mode_fsm (
    input             clk,
    input             rst,
    input             main_select_sale,
    input             main_select_admin,
    input             sale_back_req,
    input             sale_home_req,
    input             auth_ok,
    input             auth_back_req,
    input             auth_home_req,
    input             alarm_trigger,
    input             admin_back_req,
    input             admin_home_req,
    input             alarm_done,
    output reg [2:0] current_mode,
    output            sale_mode_en,
    output            auth_mode_en,
    output            admin_mode_en,
    output            alarm_mode_en
);

    assign sale_mode_en  = (current_mode == `MODE_SALE);
    assign auth_mode_en  = (current_mode == `MODE_AUTH);
    assign admin_mode_en = (current_mode == `MODE_ADMIN);
    assign alarm_mode_en = (current_mode == `MODE_ALARM);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_mode <= `MODE_MAIN_MENU;
        end else begin
            case (current_mode)
                `MODE_MAIN_MENU: begin
                    if (main_select_sale) begin
                        current_mode <= `MODE_SALE;
                    end else if (main_select_admin) begin
                        current_mode <= `MODE_AUTH;
                    end
                end

                `MODE_SALE: begin
                    if (sale_back_req || sale_home_req) begin
                        current_mode <= `MODE_MAIN_MENU;
                    end
                end

                `MODE_AUTH: begin
                    if (alarm_trigger) begin
                        current_mode <= `MODE_ALARM;
                    end else if (auth_ok) begin
                        current_mode <= `MODE_ADMIN;
                    end else if (auth_back_req || auth_home_req) begin
                        current_mode <= `MODE_MAIN_MENU;
                    end
                end

                `MODE_ADMIN: begin
                    if (admin_back_req || admin_home_req) begin
                        current_mode <= `MODE_MAIN_MENU;
                    end
                end

                `MODE_ALARM: begin
                    if (alarm_done) begin
                        current_mode <= `MODE_MAIN_MENU;
                    end
                end

                default: begin
                    current_mode <= `MODE_MAIN_MENU;
                end
            endcase
        end
    end

endmodule
