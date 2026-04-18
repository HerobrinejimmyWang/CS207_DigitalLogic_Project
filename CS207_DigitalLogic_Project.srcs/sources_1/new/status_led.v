module status_led (
    input  wire [1:0] status_code,
    input  wire [3:0] selected_stock,
    input  wire       dispense_pulse,
    output reg  [7:0] led
);
    always @(*) begin
        led       = 8'h00;
        led[3:0]  = selected_stock;
        led[4]    = (status_code == 2'b11);
        led[5]    = (status_code == 2'b10);
        led[6]    = (status_code == 2'b01);
        led[7]    = dispense_pulse;
    end
endmodule
