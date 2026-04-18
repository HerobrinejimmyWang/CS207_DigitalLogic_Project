module change_calc (
    input  wire [4:0] amount,
    input  wire [3:0] price,
    output wire [4:0] change
);
    assign change = (amount >= price) ? (amount - price) : 5'd0;
endmodule
