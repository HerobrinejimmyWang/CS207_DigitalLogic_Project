`timescale 1ns / 1ps

module error_manager (
    input            clk,
    input            rst,
    input            tick_1s,
    input            error_req,
    input      [3:0] error_code_in,
    input      [3:0] return_target_in,
    output reg       error_active,
    output reg [3:0] display_error_code,
    output reg [3:0] return_target,
    output reg       error_done
);

    reg display_first_sec;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            error_active       <= 1'b0;
            display_error_code <= 4'd0;
            return_target      <= 4'd0;
            error_done         <= 1'b0;
            display_first_sec  <= 1'b0;
        end else begin
            error_done <= 1'b0;

            if (error_active) begin
                if (tick_1s) begin
                    if (display_first_sec) begin
                        error_active       <= 1'b0;
                        display_error_code <= 4'd0;
                        error_done         <= 1'b1;
                        display_first_sec  <= 1'b0;
                    end else begin
                        display_first_sec <= 1'b1;
                    end
                end
            end else if (error_req) begin
                error_active       <= 1'b1;
                display_error_code <= error_code_in;
                return_target      <= return_target_in;
                display_first_sec  <= 1'b0;
            end else begin
                display_first_sec <= 1'b0;
            end
        end
    end

endmodule
