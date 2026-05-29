`timescale 1ns / 1ps

module reset_sync (
    input  wire clk,
    input  wire sys_rst_n,
    output wire rst
);

    reg [1:0] sync_ff;

    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sync_ff <= 2'b11;
        end else begin
            sync_ff <= {sync_ff[0], 1'b0};
        end
    end

    assign rst = sync_ff[1];

endmodule
