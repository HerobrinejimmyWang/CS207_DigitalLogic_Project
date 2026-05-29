`timescale 1ns / 1ps

module key_decoder(
    input  wire       scan_key_valid,
    input  wire [1:0] scan_key_row,
    input  wire [1:0] scan_key_col,
    output reg        key_valid,
    output reg  [3:0] key_code
);

    always @(*) begin
        key_valid = scan_key_valid;
        key_code  = 4'h0;

        case ({scan_key_row, scan_key_col})
            4'b0000: key_code = 4'h1;
            4'b0001: key_code = 4'h2;
            4'b0010: key_code = 4'h3;
            4'b0011: key_code = 4'hA;

            4'b0100: key_code = 4'h4;
            4'b0101: key_code = 4'h5;
            4'b0110: key_code = 4'h6;
            4'b0111: key_code = 4'hB;

            4'b1000: key_code = 4'h7;
            4'b1001: key_code = 4'h8;
            4'b1010: key_code = 4'h9;
            4'b1011: key_code = 4'hC;

            4'b1100: key_code = 4'hE; // *
            4'b1101: key_code = 4'h0;
            4'b1110: key_code = 4'hF; // #
            4'b1111: key_code = 4'hD;
            default: begin
                key_valid = 1'b0;
                key_code  = 4'h0;
            end
        endcase
    end

endmodule
