`timescale 1ns / 1ps

module tick_gen (
    input  wire clk,
    input  wire rst,
    output reg  tick_1ms,
    output reg  tick_10ms,
    output reg  tick_100ms,
    output reg  tick_1s,
    output reg  pix_en
);

    localparam integer COUNT_1MS   = 100_000;
    localparam integer COUNT_10MS  = 1_000_000;
    localparam integer COUNT_100MS = 10_000_000;
    localparam integer COUNT_1S    = 100_000_000;

    reg [16:0] cnt_1ms;
    reg [19:0] cnt_10ms;
    reg [23:0] cnt_100ms;
    reg [26:0] cnt_1s;
    reg [1:0]  pix_div;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1ms    <= 17'd0;
            cnt_10ms   <= 20'd0;
            cnt_100ms  <= 24'd0;
            cnt_1s     <= 27'd0;
            pix_div    <= 2'd0;
            tick_1ms   <= 1'b0;
            tick_10ms  <= 1'b0;
            tick_100ms <= 1'b0;
            tick_1s    <= 1'b0;
            pix_en     <= 1'b0;
        end else begin
            tick_1ms   <= 1'b0;
            tick_10ms  <= 1'b0;
            tick_100ms <= 1'b0;
            tick_1s    <= 1'b0;
            pix_en     <= 1'b0;

            if (cnt_1ms == COUNT_1MS - 1) begin
                cnt_1ms  <= 17'd0;
                tick_1ms <= 1'b1;
            end else begin
                cnt_1ms <= cnt_1ms + 17'd1;
            end

            if (cnt_10ms == COUNT_10MS - 1) begin
                cnt_10ms  <= 20'd0;
                tick_10ms <= 1'b1;
            end else begin
                cnt_10ms <= cnt_10ms + 20'd1;
            end

            if (cnt_100ms == COUNT_100MS - 1) begin
                cnt_100ms  <= 24'd0;
                tick_100ms <= 1'b1;
            end else begin
                cnt_100ms <= cnt_100ms + 24'd1;
            end

            if (cnt_1s == COUNT_1S - 1) begin
                cnt_1s  <= 27'd0;
                tick_1s <= 1'b1;
            end else begin
                cnt_1s <= cnt_1s + 27'd1;
            end

            if (pix_div == 2'd3) begin
                pix_div <= 2'd0;
                pix_en  <= 1'b1;
            end else begin
                pix_div <= pix_div + 2'd1;
            end
        end
    end

endmodule
