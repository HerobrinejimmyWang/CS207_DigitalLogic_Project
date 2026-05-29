`timescale 1ns / 1ps

module order_timer (
    input             clk,
    input             rst,
    input             tick_1s,
    input             start,
    input             stop,
    output reg [2:0] remaining_sec,
    output reg        timeout,
    output reg        running
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            remaining_sec <= 3'd0;
            timeout       <= 1'b0;
            running       <= 1'b0;
        end else begin
            timeout <= 1'b0;

            if (stop) begin
                remaining_sec <= 3'd0;
                running       <= 1'b0;
            end else if (start) begin
                remaining_sec <= 3'd5;
                running       <= 1'b1;
            end else if (running && tick_1s) begin
                if (remaining_sec > 3'd1) begin
                    remaining_sec <= remaining_sec - 3'd1;
                end else begin
                    remaining_sec <= 3'd0;
                    running       <= 1'b0;
                    timeout       <= 1'b1;
                end
            end
        end
    end

endmodule
