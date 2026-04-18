module debounce #(
    parameter integer COUNTER_MAX = 100_000
) (
    input  wire clk,
    input  wire rst_n,
    input  wire noisy_in,
    output reg  stable_out
);
    localparam integer COUNTER_WIDTH = (COUNTER_MAX <= 1) ? 1 : $clog2(COUNTER_MAX + 1);

    reg sync_ff0;
    reg sync_ff1;
    reg [COUNTER_WIDTH-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff0   <= 1'b0;
            sync_ff1   <= 1'b0;
            stable_out <= 1'b0;
            counter    <= {COUNTER_WIDTH{1'b0}};
        end else begin
            sync_ff0 <= noisy_in;
            sync_ff1 <= sync_ff0;

            if (sync_ff1 == stable_out) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                if (counter == COUNTER_MAX - 1) begin
                    stable_out <= sync_ff1;
                    counter    <= {COUNTER_WIDTH{1'b0}};
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end
endmodule
