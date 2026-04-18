module money_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       coin_1_pulse,
    input  wire       coin_2_pulse,
    input  wire       coin_5_pulse,
    input  wire       clear_amount,
    output reg  [4:0] current_amount
);
    reg [4:0] next_amount;

    always @(*) begin
        next_amount = current_amount;

        if (coin_1_pulse) begin
            next_amount = next_amount + 5'd1;
        end
        if (coin_2_pulse) begin
            next_amount = next_amount + 5'd2;
        end
        if (coin_5_pulse) begin
            next_amount = next_amount + 5'd5;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_amount <= 5'd0;
        end else if (clear_amount) begin
            current_amount <= 5'd0;
        end else begin
            current_amount <= next_amount;
        end
    end
endmodule
