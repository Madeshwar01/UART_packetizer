// UPDATED TESTBENCH FOR UART PACKETIZER
`timescale 1ns / 1ps

module tb_uart_packetizer;

    localparam CLK_PERIOD       = 20;
    localparam BAUD_RATE        = 115200;
    localparam CLK_FREQ         = 50_000_000;
    localparam FIFO_DEPTH       = 16;
    localparam DATA_WIDTH       = 8;
    localparam BAUD_DIVISOR     = CLK_FREQ / BAUD_RATE;
    localparam BIT_PERIOD_CLKS  = BAUD_DIVISOR;
    localparam BIT_PERIOD_TIME  = BIT_PERIOD_CLKS * CLK_PERIOD;

    reg                          clk;
    reg                          rst;
    reg  [DATA_WIDTH-1:0]        data_in;
    reg                          data_valid;
    reg                          tx_ready;

    wire                         serial_out;
    wire                         fifo_full;
    wire                         tx_busy;

    uart_packetizer_top dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .tx_ready(tx_ready),
        .serial_out(serial_out),
        .fifo_full(fifo_full),
        .tx_busy(tx_busy)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    task reset_dut;
        begin
            rst = 1;
            #(CLK_PERIOD * 5);
            rst = 0;
            #(CLK_PERIOD);
        end
    endtask

    task write_byte(input [7:0] byte);
        begin
            @(posedge clk);
            data_in = byte;
            data_valid = 1;
            @(posedge clk);
            data_valid = 0;
        end
    endtask

    task wait_for_tx_done;
        begin
            while (tx_busy) @(posedge clk);
        end
    endtask

    task check_packet(input [7:0] byte);
        reg [9:0] expected_frame;
        integer i;
        begin
            expected_frame = {1'b1, byte, 1'b0};
            #(BIT_PERIOD_TIME / 2); // sync to start bit center
            for (i = 0; i < 10; i = i + 1) begin
                #(BIT_PERIOD_TIME);
                if (serial_out !== expected_frame[i])
                    $display("FAIL: Bit %0d mismatch. Expected: %b, Got: %b", i, expected_frame[i], serial_out);
                else
                    $display("PASS: Bit %0d matched", i);
            end
            wait_for_tx_done();
        end
    endtask

    initial begin
        $timeformat(-9, 2, " ns", 10);
        clk = 0;
        rst = 1;
        data_in = 8'h00;
        data_valid = 0;
        tx_ready = 0;

        reset_dut();

        // FIFO Write Test
        tx_ready = 0;
        for (integer i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_byte(8'h30 + i);
        end
        @(posedge clk);
        if (fifo_full) $display("PASS: fifo_full asserted after FIFO filled");
        else $display("FAIL: fifo_full not asserted after FIFO filled");

        // Enable transmission
        tx_ready = 1;
        wait_for_tx_done();

        @(posedge clk);
        if (dut.fifo_empty_w) $display("PASS: fifo_empty asserted after transmit");
        else $display("FAIL: fifo_empty not asserted after transmit");

        // Send two known bytes
        write_byte(8'hA5);
        write_byte(8'h5A);
        check_packet(8'hA5);
        check_packet(8'h5A);

        // FSM & tx_ready toggle test
        tx_ready = 0;
        write_byte(8'hF0);
        @(posedge clk);
        if (dut.fsm_inst.current_state !== 3'b001) $display("FAIL: FSM not in S_WAIT_TX_READY");
        else $display("PASS: FSM correctly in S_WAIT_TX_READY");

        tx_ready = 1;
        check_packet(8'hF0);

        $display("Testbench complete.");
        $finish;
    end
endmodule
