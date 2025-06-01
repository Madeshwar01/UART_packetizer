// UPDATED uart_tx.v WITH OUTPUT SMOOTHING REGISTER
`timescale 1ns / 1ps

module uart_tx #(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ  = 50_000_000,
    parameter DATA_BITS = 8
) (
    input                       clk,
    input                       rst,
    input                       start_tx,
    input      [DATA_BITS-1:0]  data_in,
    output reg                  serial_out,
    output reg                  tx_done
);

    localparam BAUD_DIVISOR = (CLK_FREQ / BAUD_RATE);
    localparam SAFE_BAUD_DIVISOR = (BAUD_DIVISOR == 0) ? 1 : BAUD_DIVISOR;
    localparam BITS_TO_SEND = 1 + DATA_BITS + 1; // Start + Data + Stop

    localparam BAUD_COUNTER_WIDTH = ($clog2(SAFE_BAUD_DIVISOR) == 0) ? 1 : $clog2(SAFE_BAUD_DIVISOR);
    reg [BAUD_COUNTER_WIDTH-1:0] baud_counter;
    reg                          baud_tick;

    localparam BIT_INDEX_WIDTH = $clog2(BITS_TO_SEND);
    reg [(BIT_INDEX_WIDTH == 0 ? 0 : BIT_INDEX_WIDTH-1):0] bit_index;

    reg [DATA_BITS+1:0]          tx_shift_reg;
    reg                          tx_active;
    reg                          serial_out_next; // NEW: intermediate value

    // Baud tick generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_counter <= 0;
            baud_tick    <= 1'b0;
        end else begin
            if (tx_active) begin
                if (baud_counter == SAFE_BAUD_DIVISOR - 1) begin
                    baud_counter <= 0;
                    baud_tick    <= 1'b1;
                end else begin
                    baud_counter <= baud_counter + 1;
                    baud_tick    <= 1'b0;
                end
            end else begin
                baud_counter <= 0;
                baud_tick    <= 1'b0;
            end
        end
    end

    // TX FSM & data logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_active        <= 1'b0;
            tx_done          <= 1'b0;
            serial_out_next  <= 1'b1;
            serial_out       <= 1'b1;
            tx_shift_reg     <= 0;
            bit_index        <= 0;
        end else begin
            tx_done <= 1'b0;

            if (start_tx && !tx_active) begin
                tx_shift_reg     <= {1'b1, data_in, 1'b0};
                tx_active        <= 1'b1;
                bit_index        <= 0;
                serial_out_next  <= 1'b0; // Start bit
            end else if (tx_active && baud_tick) begin
                serial_out_next  <= tx_shift_reg[0];
                tx_shift_reg     <= {1'b1, tx_shift_reg[DATA_BITS+1:1]};

                if (bit_index == BITS_TO_SEND - 1) begin
                    tx_active <= 1'b0;
                    tx_done   <= 1'b1;
                end
                bit_index <= bit_index + 1;
            end else if (!tx_active) begin
                serial_out_next <= 1'b1; // Idle line
            end

            serial_out <= serial_out_next; // Output smoothing
        end
    end

endmodule
