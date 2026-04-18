module seg7_driver #(
    parameter integer SCAN_DIV_BITS = 16,
    parameter         SEG_ACTIVE_LOW = 1,
    parameter         AN_ACTIVE_LOW  = 1
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] digits,
    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output wire        dp
);
    reg [SCAN_DIV_BITS-1:0] scan_div;
    reg [1:0] digit_sel;
    reg [3:0] nibble;
    reg [6:0] seg_raw;
    reg [3:0] an_raw;

    assign dp = SEG_ACTIVE_LOW ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_div <= {SCAN_DIV_BITS{1'b0}};
        end else begin
            scan_div <= scan_div + 1'b1;
        end
    end

    always @(*) begin
        digit_sel = scan_div[SCAN_DIV_BITS-1:SCAN_DIV_BITS-2];

        case (digit_sel)
            2'b00: begin
                nibble = digits[3:0];
                an_raw = 4'b1110;
            end
            2'b01: begin
                nibble = digits[7:4];
                an_raw = 4'b1101;
            end
            2'b10: begin
                nibble = digits[11:8];
                an_raw = 4'b1011;
            end
            default: begin
                nibble = digits[15:12];
                an_raw = 4'b0111;
            end
        endcase

        case (nibble)
            4'h0: seg_raw = 7'b0111111;
            4'h1: seg_raw = 7'b0000110;
            4'h2: seg_raw = 7'b1011011;
            4'h3: seg_raw = 7'b1001111;
            4'h4: seg_raw = 7'b1100110;
            4'h5: seg_raw = 7'b1101101;
            4'h6: seg_raw = 7'b1111101;
            4'h7: seg_raw = 7'b0000111;
            4'h8: seg_raw = 7'b1111111;
            4'h9: seg_raw = 7'b1101111;
            4'hA: seg_raw = 7'b1110111;
            4'hB: seg_raw = 7'b1111100;
            4'hC: seg_raw = 7'b0111001;
            4'hD: seg_raw = 7'b1011110;
            4'hE: seg_raw = 7'b1111001;
            4'hF: seg_raw = 7'b1110001;
            default: seg_raw = 7'b0000000;
        endcase
    end

    always @(*) begin
        seg = SEG_ACTIVE_LOW ? ~seg_raw : seg_raw;
        an  = AN_ACTIVE_LOW  ? an_raw   : ~an_raw;
    end
endmodule
