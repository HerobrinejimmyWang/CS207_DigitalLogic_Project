`timescale 1ns / 1ps

module matrix_keypad_scanner #(
    parameter DEBOUNCE_SAMPLES = 5,
    parameter RELEASE_SAMPLES  = 3
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1ms,
    input  wire [3:0] col_in,
    output reg  [3:0] row_active,
    output reg        scan_key_valid,
    output reg  [1:0] scan_key_row,
    output reg  [1:0] scan_key_col
);

    localparam ST_IDLE     = 2'd0;
    localparam ST_DEBOUNCE = 2'd1;
    localparam ST_HELD     = 2'd2;

    reg [1:0] state;
    reg [1:0] row_index;
    reg [1:0] cand_row;
    reg [1:0] cand_col;
    reg [1:0] held_row;
    reg [1:0] held_col;
    reg [3:0] debounce_count;
    reg [3:0] release_count;

    wire       key_seen;
    wire [1:0] sensed_col;

    assign key_seen = (col_in != 4'b1111);
    assign sensed_col = decode_col(col_in);

    function [1:0] decode_col;
        input [3:0] cols;
        begin
            if (!cols[0])
                decode_col = 2'd0;
            else if (!cols[1])
                decode_col = 2'd1;
            else if (!cols[2])
                decode_col = 2'd2;
            else
                decode_col = 2'd3;
        end
    endfunction

    function [3:0] onehot_row;
        input [1:0] row;
        begin
            case (row)
                2'd0: onehot_row = 4'b0001;
                2'd1: onehot_row = 4'b0010;
                2'd2: onehot_row = 4'b0100;
                default: onehot_row = 4'b1000;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state          <= ST_IDLE;
            row_index      <= 2'd0;
            row_active     <= 4'b0001;
            scan_key_valid <= 1'b0;
            scan_key_row   <= 2'd0;
            scan_key_col   <= 2'd0;
            cand_row       <= 2'd0;
            cand_col       <= 2'd0;
            held_row       <= 2'd0;
            held_col       <= 2'd0;
            debounce_count <= 4'd0;
            release_count  <= 4'd0;
        end else begin
            scan_key_valid <= 1'b0;

            if (tick_1ms) begin
                case (state)
                    ST_IDLE: begin
                        if (key_seen) begin
                            cand_row       <= row_index;
                            cand_col       <= sensed_col;
                            debounce_count <= 4'd1;
                            release_count  <= 4'd0;
                            state          <= ST_DEBOUNCE;
                        end
                    end

                    ST_DEBOUNCE: begin
                        if (row_index == cand_row) begin
                            if (key_seen && (sensed_col == cand_col)) begin
                                if (debounce_count >= (DEBOUNCE_SAMPLES - 1)) begin
                                    scan_key_valid <= 1'b1;
                                    scan_key_row   <= cand_row;
                                    scan_key_col   <= cand_col;
                                    held_row       <= cand_row;
                                    held_col       <= cand_col;
                                    debounce_count <= 4'd0;
                                    release_count  <= 4'd0;
                                    state          <= ST_HELD;
                                end else begin
                                    debounce_count <= debounce_count + 4'd1;
                                end
                            end else begin
                                debounce_count <= 4'd0;
                                state          <= ST_IDLE;
                            end
                        end
                    end

                    ST_HELD: begin
                        if (row_index == held_row) begin
                            if (key_seen && (sensed_col == held_col)) begin
                                release_count <= 4'd0;
                            end else if (release_count >= (RELEASE_SAMPLES - 1)) begin
                                release_count <= 4'd0;
                                state         <= ST_IDLE;
                            end else begin
                                release_count <= release_count + 4'd1;
                            end
                        end
                    end

                    default: begin
                        state          <= ST_IDLE;
                        debounce_count <= 4'd0;
                        release_count  <= 4'd0;
                    end
                endcase

                row_index  <= row_index + 2'd1;
                row_active <= onehot_row(row_index + 2'd1);
            end
        end
    end

endmodule
