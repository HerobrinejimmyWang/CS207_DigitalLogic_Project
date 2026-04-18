module inventory_mgr #(
    parameter [3:0] INITIAL_STOCK = 4'd5
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [1:0] product_sel,
    input  wire       vend_success,
    output reg  [3:0] selected_stock,
    output wire [15:0] stocks_flat
);
    reg [3:0] stock0;
    reg [3:0] stock1;
    reg [3:0] stock2;
    reg [3:0] stock3;

    assign stocks_flat = {stock3, stock2, stock1, stock0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stock0 <= INITIAL_STOCK;
            stock1 <= INITIAL_STOCK;
            stock2 <= INITIAL_STOCK;
            stock3 <= INITIAL_STOCK;
        end else if (vend_success) begin
            case (product_sel)
                2'b00: if (stock0 != 4'd0) stock0 <= stock0 - 1'b1;
                2'b01: if (stock1 != 4'd0) stock1 <= stock1 - 1'b1;
                2'b10: if (stock2 != 4'd0) stock2 <= stock2 - 1'b1;
                2'b11: if (stock3 != 4'd0) stock3 <= stock3 - 1'b1;
                default: begin end
            endcase
        end
    end

    always @(*) begin
        case (product_sel)
            2'b00: selected_stock = stock0;
            2'b01: selected_stock = stock1;
            2'b10: selected_stock = stock2;
            2'b11: selected_stock = stock3;
            default: selected_stock = 4'd0;
        endcase
    end
endmodule
