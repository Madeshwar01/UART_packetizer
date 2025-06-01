`timescale 1ns / 1ps
module packetizer_fsm (
    input                       clk,
    input                       rst,
    input                       fifo_empty,
    input      [7:0]            fifo_data_out, 
    output reg                  fifo_rd_en,    
    output reg                  uart_start_tx, 
    output reg [7:0]            uart_data_to_tx, 
    input                       uart_tx_done,  
    input                       tx_ready,     
    output reg                  tx_busy
);


    localparam S_IDLE                 = 3'b000;
    localparam S_WAIT_TX_READY        = 3'b001;
    localparam S_READ_FIFO_START_TX   = 3'b010;
    localparam S_WAIT_TX_DONE         = 3'b011;

    reg [2:0] current_state, next_state;


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end


    always @(*) begin
      
        next_state        = current_state;
        fifo_rd_en        = 1'b0;
        uart_start_tx     = 1'b0;
        uart_data_to_tx   = 8'h00; 
        tx_busy           = (current_state == S_READ_FIFO_START_TX) |
| (current_state == S_WAIT_TX_DONE);

        case (current_state)
            S_IDLE: begin
                if (!fifo_empty) begin
                    next_state = S_WAIT_TX_READY;
                end
            end
            S_WAIT_TX_READY: begin
                if (fifo_empty) begin 
                    next_state = S_IDLE;
                end else if (tx_ready) begin
                    next_state = S_READ_FIFO_START_TX;
                end
            end
            S_READ_FIFO_START_TX: begin
                fifo_rd_en = 1'b1; 
                uart_data_to_tx = fifo_data_out; 
                uart_start_tx = 1'b1;   
                next_state = S_WAIT_TX_DONE;
            end
            S_WAIT_TX_DONE: begin
                if (uart_tx_done) begin
                    next_state = S_IDLE;
                end
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

endmodule
