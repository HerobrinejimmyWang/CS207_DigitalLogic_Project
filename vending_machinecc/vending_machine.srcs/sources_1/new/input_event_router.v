`timescale 1ns / 1ps
`include "admin_mode_defs.vh"

module input_event_router(
    input  wire       key_valid,
    input  wire [3:0] key_code,
    output reg        event_valid,
    output reg  [2:0] event_type,
    output reg  [3:0] event_value
);

    always @(*) begin
        event_valid = key_valid;
        event_type  = `EV_DIGIT;
        event_value = 4'd0;
 
        if (key_valid) begin
            if (key_code <= 4'd9) begin
                event_type  = `EV_DIGIT;
                event_value = key_code;
            end else begin
                case (key_code)
                    4'hA: event_type = `EV_PREV;
                    4'hB: event_type = `EV_BACK;
                    4'hC: event_type = `EV_HOME;
                    4'hD: event_type = `EV_NEXT;
                    4'hE: event_type = `EV_CLEAR;
                    4'hF: event_type = `EV_CONFIRM;
                    default: begin
                        event_valid = 1'b0;
                        event_type  = `EV_DIGIT;
                    end
                endcase
            end
        end
    end

endmodule
