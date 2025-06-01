`timescale 1ns / 1ps
module uart_packetizer_top (
    input                       clk,            // System clock (50 MHz)
    input                       rst,            // Active-high synchronous reset
    input      [7:0]            data_in,        // Incoming data byte
    input                       data_valid,     // Pulse when new data is valid
    input                       tx_ready,       // External receiver ready
    output                      serial_out,     // Serial output line
    output                      fifo_full,      // FIFO is full
    output                      tx_busy         // Transmission in progress
);

    // FIFO Parameters
    localparam FIFO_DATA_WIDTH = 8;
    localparam FIFO_ADDR_WIDTH = 4; // For Depth = 16

    // UART Parameters
    localparam BAUD_RATE = 115200; // Example, can be overridden if top has params
    localparam CLK_FREQ  = 50_000_000;

    // Internal Wires for Inter-module Connections
    wire fifo_data_out_w;
    wire                       fifo_empty_w;
    wire                       fifo_rd_en_w;
    wire                       data_out_valid_w; // From FIFO

    wire                       uart_start_tx_w;
    wire uart_data_to_tx_w;
    wire                       uart_tx_done_w;

    // Instantiate Asynchronous FIFO
    // Assuming data_valid is synchronous to clk and acts as write enable.
    // wr_clk and rd_clk are connected to the same system clk here,
    // but the FIFO is designed to be asynchronous.
    async_fifo #(
       .DATA_WIDTH(FIFO_DATA_WIDTH),
       .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) fifo_inst (
       .wr_clk(clk),
       .wr_rst(rst),
       .wr_data_in(data_in),
       .wr_en(data_valid), // data_valid acts as write enable
       .fifo_full(fifo_full),

       .rd_clk(clk),
       .rd_rst(rst),
       .rd_en(fifo_rd_en_w),
       .rd_data_out(fifo_data_out_w),
       .fifo_empty(fifo_empty_w),
       .data_out_valid(data_out_valid_w)
    );

    // Instantiate Packetizer FSM
    packetizer_fsm fsm_inst (
       .clk(clk),
       .rst(rst),
       .fifo_empty(fifo_empty_w),
       .fifo_data_out(fifo_data_out_w),
       .fifo_rd_en(fifo_rd_en_w),
       .uart_start_tx(uart_start_tx_w),
       .uart_data_to_tx(uart_data_to_tx_w),
       .uart_tx_done(uart_tx_done_w),
       .tx_ready(tx_ready),
       .tx_busy(tx_busy)
    );

    // Instantiate UART TX
    uart_tx #(
       .BAUD_RATE(BAUD_RATE),
       .CLK_FREQ(CLK_FREQ),
       .DATA_BITS(FIFO_DATA_WIDTH)
    ) uart_tx_inst (
       .clk(clk),
       .rst(rst),
       .start_tx(uart_start_tx_w),
       .data_in(uart_data_to_tx_w),
       .serial_out(serial_out),
       .tx_done(uart_tx_done_w)
    );

endmodule
