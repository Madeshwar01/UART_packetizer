`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH      = 1 << ADDR_WIDTH
) (
    input                       wr_clk,
    input                       wr_rst,
    input  [DATA_WIDTH-1:0]     wr_data_in,
    input                       wr_en,
    output reg                  fifo_full,

    input                       rd_clk,
    input                       rd_rst,
    input                       rd_en,
    output [DATA_WIDTH-1:0]     rd_data_out,
    output reg                  fifo_empty,
    output reg                  data_out_valid
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR_WIDTH:0] wr_ptr_bin_ff, rd_ptr_bin_ff;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] sync_wr_ptr_gray, sync_wr_ptr_gray_s1;
    reg [ADDR_WIDTH:0] sync_rd_ptr_gray, sync_rd_ptr_gray_s1;

    wire [ADDR_WIDTH:0] wr_ptr_bin_next, rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;
    wire                wr_push, rd_pop;
    wire                rd_ptr_is_empty;
    wire                wr_ptr_gray_next_is_full;

    function [ADDR_WIDTH:0] bin_to_gray(input [ADDR_WIDTH:0] bin);
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    function [ADDR_WIDTH:0] gray_to_bin(input [ADDR_WIDTH:0] gray);
        integer i;
        begin
            gray_to_bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1)
                gray_to_bin[i] = gray[i] ^ gray_to_bin[i + 1];
        end
    endfunction

    assign wr_push = wr_en && !fifo_full;
    assign wr_ptr_bin_next = wr_push ? wr_ptr_bin_ff + 1 : wr_ptr_bin_ff;
    assign wr_ptr_gray_next = bin_to_gray(wr_ptr_bin_next);

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_bin_ff <= 0;
            wr_ptr_gray   <= 0;
        end else begin
            wr_ptr_bin_ff <= wr_ptr_bin_next;
            wr_ptr_gray   <= wr_ptr_gray_next;
        end
    end

    assign rd_pop = rd_en && !fifo_empty;
    assign rd_ptr_bin_next = rd_pop ? rd_ptr_bin_ff + 1 : rd_ptr_bin_ff;

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_bin_ff <= 0;
            rd_ptr_gray   <= 0;
        end else begin
            rd_ptr_bin_ff <= rd_ptr_bin_next;
            rd_ptr_gray   <= bin_to_gray(rd_ptr_bin_next);
        end
    end

    always @(posedge wr_clk) begin
        if (wr_push)
            mem[wr_ptr_bin_ff[ADDR_WIDTH-1:0]] <= wr_data_in;
    end

    assign rd_data_out = mem[rd_ptr_bin_ff[ADDR_WIDTH-1:0]];

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            sync_wr_ptr_gray_s1 <= 0;
            sync_wr_ptr_gray    <= 0;
        end else begin
            sync_wr_ptr_gray_s1 <= wr_ptr_gray;
            sync_wr_ptr_gray    <= sync_wr_ptr_gray_s1;
        end
    end

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            sync_rd_ptr_gray_s1 <= 0;
            sync_rd_ptr_gray    <= 0;
        end else begin
            sync_rd_ptr_gray_s1 <= rd_ptr_gray;
            sync_rd_ptr_gray    <= sync_rd_ptr_gray_s1;
        end
    end

    assign rd_ptr_is_empty = (rd_ptr_gray == sync_wr_ptr_gray);

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst)
            fifo_empty <= 1'b1;
        else
            fifo_empty <= rd_ptr_is_empty;
    end

    assign wr_ptr_gray_next_is_full = 
        (wr_ptr_gray_next[ADDR_WIDTH] != sync_rd_ptr_gray[ADDR_WIDTH]) &&
        (wr_ptr_gray_next[ADDR_WIDTH-1:0] == sync_rd_ptr_gray[ADDR_WIDTH-1:0]);

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst)
            fifo_full <= 1'b0;
        else
            fifo_full <= wr_ptr_gray_next_is_full;
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst)
            data_out_valid <= 1'b0;
        else
            data_out_valid <= rd_pop;
    end

endmodule

