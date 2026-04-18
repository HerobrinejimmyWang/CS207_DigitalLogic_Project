module price_rom (
    input  wire [1:0] product_sel,
    output reg  [3:0] price
);
    always @(*) begin
        case (product_sel)
            2'b00: price = 4'd3;
            2'b01: price = 4'd5;
            2'b10: price = 4'd7;
            2'b11: price = 4'd9;
            default: price = 4'd0;
        endcase
    end
endmodule
