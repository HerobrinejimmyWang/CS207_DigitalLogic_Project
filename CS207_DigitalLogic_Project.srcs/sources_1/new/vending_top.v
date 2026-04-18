module vending_top #(
    parameter integer DEBOUNCE_CYCLES = 100_000,
    parameter integer HOLD_CYCLES     = 20,
    parameter integer SCAN_DIV_BITS   = 16
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       btn_coin_1,
    input  wire       btn_coin_2,
    input  wire       btn_coin_5,
    input  wire [1:0] btn_sel,
    input  wire       btn_confirm,
    input  wire       btn_cancel,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire       dp,
    output wire [7:0] led,
    output wire       dispense_pulse
);
    wire db_coin_1;
    wire db_coin_2;
    wire db_coin_5;
    wire db_confirm;
    wire db_cancel;

    wire coin_1_pulse;
    wire coin_2_pulse;
    wire coin_5_pulse;
    wire confirm_pulse;
    wire cancel_pulse;

    wire [3:0] selected_price;
    wire [3:0] selected_stock;
    wire [15:0] all_stocks;
    wire [4:0] current_amount;
    wire [4:0] change_amount;

    wire [1:0] selected_product;
    wire [1:0] status_code;
    wire [4:0] display_amount;
    wire clear_amount;
    wire vend_success;

    wire [3:0] amount_ones;
    wire [3:0] amount_tens;
    wire [15:0] digits_bus;

    debounce #(.COUNTER_MAX(DEBOUNCE_CYCLES)) u_db_coin_1 (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_coin_1),
        .stable_out(db_coin_1)
    );

    debounce #(.COUNTER_MAX(DEBOUNCE_CYCLES)) u_db_coin_2 (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_coin_2),
        .stable_out(db_coin_2)
    );

    debounce #(.COUNTER_MAX(DEBOUNCE_CYCLES)) u_db_coin_5 (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_coin_5),
        .stable_out(db_coin_5)
    );

    debounce #(.COUNTER_MAX(DEBOUNCE_CYCLES)) u_db_confirm (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_confirm),
        .stable_out(db_confirm)
    );

    debounce #(.COUNTER_MAX(DEBOUNCE_CYCLES)) u_db_cancel (
        .clk(clk),
        .rst_n(rst_n),
        .noisy_in(btn_cancel),
        .stable_out(db_cancel)
    );

    edge_detect u_ed_coin_1 (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(db_coin_1),
        .pulse_out(coin_1_pulse)
    );

    edge_detect u_ed_coin_2 (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(db_coin_2),
        .pulse_out(coin_2_pulse)
    );

    edge_detect u_ed_coin_5 (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(db_coin_5),
        .pulse_out(coin_5_pulse)
    );

    edge_detect u_ed_confirm (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(db_confirm),
        .pulse_out(confirm_pulse)
    );

    edge_detect u_ed_cancel (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(db_cancel),
        .pulse_out(cancel_pulse)
    );

    price_rom u_price_rom (
        .product_sel(selected_product),
        .price(selected_price)
    );

    money_counter u_money_counter (
        .clk(clk),
        .rst_n(rst_n),
        .coin_1_pulse(coin_1_pulse),
        .coin_2_pulse(coin_2_pulse),
        .coin_5_pulse(coin_5_pulse),
        .clear_amount(clear_amount),
        .current_amount(current_amount)
    );

    change_calc u_change_calc (
        .amount(current_amount),
        .price(selected_price),
        .change(change_amount)
    );

    inventory_mgr u_inventory_mgr (
        .clk(clk),
        .rst_n(rst_n),
        .product_sel(selected_product),
        .vend_success(vend_success),
        .selected_stock(selected_stock),
        .stocks_flat(all_stocks)
    );

    vending_fsm #(.HOLD_CYCLES(HOLD_CYCLES)) u_vending_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .btn_sel(btn_sel),
        .coin_1_pulse(coin_1_pulse),
        .coin_2_pulse(coin_2_pulse),
        .coin_5_pulse(coin_5_pulse),
        .confirm_pulse(confirm_pulse),
        .cancel_pulse(cancel_pulse),
        .selected_price(selected_price),
        .selected_stock(selected_stock),
        .current_amount(current_amount),
        .change_amount(change_amount),
        .selected_product(selected_product),
        .status_code(status_code),
        .display_amount(display_amount),
        .clear_amount(clear_amount),
        .vend_success(vend_success),
        .dispense_pulse(dispense_pulse)
    );

    status_led u_status_led (
        .status_code(status_code),
        .selected_stock(selected_stock),
        .dispense_pulse(dispense_pulse),
        .led(led)
    );

    assign amount_tens = display_amount / 10;
    assign amount_ones = display_amount % 10;
    assign digits_bus  = {2'b00, status_code, 2'b00, selected_product, amount_tens, amount_ones};

    seg7_driver #(
        .SCAN_DIV_BITS(SCAN_DIV_BITS),
        .SEG_ACTIVE_LOW(0),
        .AN_ACTIVE_LOW(0)
    ) u_seg7_driver (
        .clk(clk),
        .rst_n(rst_n),
        .digits(digits_bus),
        .seg(seg),
        .an(an),
        .dp(dp)
    );
endmodule
