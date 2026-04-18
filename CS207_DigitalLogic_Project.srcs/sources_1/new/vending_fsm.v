`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/18 16:35:54
// Design Name: 
// Module Name: vending_fsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vending_fsm #(
    parameter integer HOLD_CYCLES = 20
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [1:0] btn_sel,
    input  wire       coin_1_pulse,
    input  wire       coin_2_pulse,
    input  wire       coin_5_pulse,
    input  wire       confirm_pulse,
    input  wire       cancel_pulse,
    input  wire [3:0] selected_price,
    input  wire [3:0] selected_stock,
    input  wire [4:0] current_amount,
    input  wire [4:0] change_amount,
    output reg  [1:0] selected_product,
    output reg  [1:0] status_code,
    output reg  [4:0] display_amount,
    output reg        clear_amount,
    output reg        vend_success,
    output reg        dispense_pulse
);
    localparam [2:0] ST_IDLE     = 3'd0;
    localparam [2:0] ST_SELECT   = 3'd1;
    localparam [2:0] ST_COIN_IN  = 3'd2;
    localparam [2:0] ST_CHECK    = 3'd3;
    localparam [2:0] ST_DISPENSE = 3'd4;
    localparam [2:0] ST_CHANGE   = 3'd5;
    localparam [2:0] ST_SOLD_OUT = 3'd6;
    localparam [2:0] ST_CANCEL   = 3'd7;

    reg [2:0] state;
    reg [2:0] next_state;
    reg [7:0] hold_counter;
    reg insufficient_flag;
    wire coin_pulse;

    assign coin_pulse = coin_1_pulse | coin_2_pulse | coin_5_pulse;

    always @(*) begin
        next_state = state;

        case (state)
            ST_IDLE: begin
                if (cancel_pulse && (current_amount != 5'd0)) begin
                    next_state = ST_CANCEL;
                end else if (coin_pulse) begin
                    next_state = ST_COIN_IN;
                end else if (confirm_pulse) begin
                    next_state = ST_CHECK;
                end else begin
                    next_state = ST_SELECT;
                end
            end
            ST_SELECT: begin
                if (cancel_pulse && (current_amount != 5'd0)) begin
                    next_state = ST_CANCEL;
                end else if (coin_pulse) begin
                    next_state = ST_COIN_IN;
                end else if (confirm_pulse) begin
                    next_state = ST_CHECK;
                end
            end
            ST_COIN_IN: begin
                if (cancel_pulse && (current_amount != 5'd0)) begin
                    next_state = ST_CANCEL;
                end else if (confirm_pulse) begin
                    next_state = ST_CHECK;
                end
            end
            ST_CHECK: begin
                if (selected_stock == 4'd0) begin
                    next_state = ST_SOLD_OUT;
                end else if (current_amount >= {1'b0, selected_price}) begin
                    next_state = ST_DISPENSE;
                end else begin
                    next_state = ST_COIN_IN;
                end
            end
            ST_DISPENSE: begin
                next_state = ST_CHANGE;
            end
            ST_CHANGE: begin
                if (hold_counter >= HOLD_CYCLES - 1) begin
                    next_state = ST_IDLE;
                end
            end
            ST_SOLD_OUT: begin
                if (hold_counter >= HOLD_CYCLES - 1) begin
                    next_state = ST_SELECT;
                end
            end
            ST_CANCEL: begin
                if (hold_counter >= HOLD_CYCLES - 1) begin
                    next_state = ST_IDLE;
                end
            end
            default: next_state = ST_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_IDLE;
            selected_product <= 2'b00;
            status_code      <= 2'b00;
            display_amount   <= 5'd0;
            clear_amount     <= 1'b0;
            vend_success     <= 1'b0;
            dispense_pulse   <= 1'b0;
            hold_counter     <= 8'd0;
            insufficient_flag <= 1'b0;
        end else begin
            state          <= next_state;
            clear_amount   <= 1'b0;
            vend_success   <= 1'b0;
            dispense_pulse <= 1'b0;

            if ((state == ST_IDLE) || (state == ST_SELECT) || (state == ST_COIN_IN) || (state == ST_CHECK)) begin
                selected_product <= btn_sel;
            end

            if (coin_pulse || cancel_pulse) begin
                insufficient_flag <= 1'b0;
            end

            if ((state != next_state) && ((next_state == ST_CHANGE) || (next_state == ST_SOLD_OUT) || (next_state == ST_CANCEL))) begin
                hold_counter <= 8'd0;
            end else if ((state == ST_CHANGE) || (state == ST_SOLD_OUT) || (state == ST_CANCEL)) begin
                hold_counter <= hold_counter + 1'b1;
            end else begin
                hold_counter <= 8'd0;
            end

            case (state)
                ST_IDLE: begin
                    status_code    <= insufficient_flag ? 2'b01 : 2'b00;
                    display_amount <= current_amount;
                end
                ST_SELECT: begin
                    status_code    <= insufficient_flag ? 2'b01 : 2'b00;
                    display_amount <= current_amount;
                end
                ST_COIN_IN: begin
                    status_code    <= insufficient_flag ? 2'b01 : 2'b00;
                    display_amount <= current_amount;
                end
                ST_CHECK: begin
                    if (selected_stock == 4'd0) begin
                        status_code    <= 2'b10;
                        display_amount <= current_amount;
                        insufficient_flag <= 1'b0;
                    end else if (current_amount >= {1'b0, selected_price}) begin
                        status_code    <= 2'b11;
                        display_amount <= change_amount;
                        insufficient_flag <= 1'b0;
                    end else begin
                        status_code    <= 2'b01;
                        display_amount <= current_amount;
                        insufficient_flag <= 1'b1;
                    end
                end
                ST_DISPENSE: begin
                    status_code    <= 2'b11;
                    display_amount <= change_amount;
                    clear_amount   <= 1'b1;
                    vend_success   <= 1'b1;
                    dispense_pulse <= 1'b1;
                    insufficient_flag <= 1'b0;
                end
                ST_CHANGE: begin
                    status_code    <= 2'b11;
                    display_amount <= display_amount;
                end
                ST_SOLD_OUT: begin
                    status_code    <= 2'b10;
                    display_amount <= current_amount;
                end
                ST_CANCEL: begin
                    status_code    <= 2'b01;
                    display_amount <= current_amount;
                    clear_amount   <= 1'b1;
                    insufficient_flag <= 1'b0;
                end
                default: begin
                    status_code    <= 2'b00;
                    display_amount <= current_amount;
                    insufficient_flag <= 1'b0;
                end
            endcase
        end
    end
endmodule
