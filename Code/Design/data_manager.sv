`timescale 1ns / 1ps

module data_manager (
    input  logic        clk,
    input  logic        rst,
    input  logic        sale_stock_dec_req,
    input  logic        sale_stock_inc_req,
    input  logic        sale_total_add_req,
    input  logic [1:0]  sale_item_idx,
    input  logic [7:0]  sale_amount,
    input  logic        admin_set_price_req,
    input  logic        admin_add_stock_req,
    input  logic        admin_toggle_enable_req,
    input  logic [1:0]  admin_item_idx,
    input  logic [7:0]  admin_value,
    output logic [7:0]  price0,
    output logic [7:0]  price1,
    output logic [7:0]  price2,
    output logic [7:0]  price3,
    output logic [4:0]  stock0,
    output logic [4:0]  stock1,
    output logic [4:0]  stock2,
    output logic [4:0]  stock3,
    output logic [3:0]  enabled,
    output logic [15:0] sales_total
);

    logic [7:0]  next_price0, next_price1, next_price2, next_price3;
    logic [4:0]  next_stock0, next_stock1, next_stock2, next_stock3;
    logic [3:0]  next_enabled;
    logic [15:0] next_sales_total;

    function automatic [4:0] sat_stock_add(
        input logic [4:0] base_value,
        input logic [7:0] add_value
    );
        integer sum_value;
        begin
            sum_value = base_value + add_value;
            if (sum_value > 15) begin
                sat_stock_add = 5'd15;
            end else begin
                sat_stock_add = sum_value[4:0];
            end
        end
    endfunction

    always_comb begin
        next_price0      = price0;
        next_price1      = price1;
        next_price2      = price2;
        next_price3      = price3;
        next_stock0      = stock0;
        next_stock1      = stock1;
        next_stock2      = stock2;
        next_stock3      = stock3;
        next_enabled     = enabled;
        next_sales_total = sales_total;

        if (sale_stock_dec_req) begin
            case (sale_item_idx)
                2'd0: if (next_stock0 != 5'd0) next_stock0 = next_stock0 - 5'd1;
                2'd1: if (next_stock1 != 5'd0) next_stock1 = next_stock1 - 5'd1;
                2'd2: if (next_stock2 != 5'd0) next_stock2 = next_stock2 - 5'd1;
                2'd3: if (next_stock3 != 5'd0) next_stock3 = next_stock3 - 5'd1;
                default: ;
            endcase
        end

        if (sale_stock_inc_req) begin
            case (sale_item_idx)
                2'd0: next_stock0 = sat_stock_add(next_stock0, 8'd1);
                2'd1: next_stock1 = sat_stock_add(next_stock1, 8'd1);
                2'd2: next_stock2 = sat_stock_add(next_stock2, 8'd1);
                2'd3: next_stock3 = sat_stock_add(next_stock3, 8'd1);
                default: ;
            endcase
        end

        if (sale_total_add_req) begin
            next_sales_total = sales_total + {8'd0, sale_amount};
        end

        if (admin_set_price_req &&
            (admin_value >= 8'd1) &&
            (admin_value <= 8'd15)) begin
            case (admin_item_idx)
                2'd0: next_price0 = admin_value;
                2'd1: next_price1 = admin_value;
                2'd2: next_price2 = admin_value;
                2'd3: next_price3 = admin_value;
                default: ;
            endcase
        end

        if (admin_add_stock_req &&
            (admin_value >= 8'd1) &&
            (admin_value <= 8'd15)) begin
            case (admin_item_idx)
                2'd0: next_stock0 = sat_stock_add(next_stock0, admin_value);
                2'd1: next_stock1 = sat_stock_add(next_stock1, admin_value);
                2'd2: next_stock2 = sat_stock_add(next_stock2, admin_value);
                2'd3: next_stock3 = sat_stock_add(next_stock3, admin_value);
                default: ;
            endcase
        end

        if (admin_toggle_enable_req) begin
            case (admin_item_idx)
                2'd0: next_enabled[0] = ~enabled[0];
                2'd1: next_enabled[1] = ~enabled[1];
                2'd2: next_enabled[2] = ~enabled[2];
                2'd3: next_enabled[3] = ~enabled[3];
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            price0      <= 8'd5;
            price1      <= 8'd6;
            price2      <= 8'd7;
            price3      <= 8'd3;
            stock0      <= 5'd5;
            stock1      <= 5'd5;
            stock2      <= 5'd5;
            stock3      <= 5'd5;
            enabled     <= 4'b1111;
            sales_total <= 16'd0;
        end else begin
            price0      <= next_price0;
            price1      <= next_price1;
            price2      <= next_price2;
            price3      <= next_price3;
            stock0      <= next_stock0;
            stock1      <= next_stock1;
            stock2      <= next_stock2;
            stock3      <= next_stock3;
            enabled     <= next_enabled;
            sales_total <= next_sales_total;
        end
    end

endmodule
