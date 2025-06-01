# UART Packetizer with FSM and FIFO Integration
This project implements a UART Packetizer system in Verilog that buffers 8-bit parallel data into a FIFO and transmits it serially via a custom UART protocol. It demonstrates asynchronous FIFO handling, FSM-driven control flow, and UART serialization—suited for FPGA-based communication systems.

The digital logic design of the system shall include the RTL development of the following modules. 
1. A Packetizer FSM. 
2. An asynchronous FIFO buffer. 
3. A UART-like serial output block. 
4. A top module interconnecting the above three modules.

🧩 Project Modules
1. fifo_async.v
-   Asynchronous FIFO buffer (16x8)
-   Handles clock domain crossing using Gray code pointers
-   Provides fifo_full, fifo_empty, and data_out_valid flags

2. packetizer_fsm.v
-   Finite State Machine controlling packetization and flow
-   Waits for tx_ready, reads from FIFO, and starts UART transmission
-   FSM States: S_IDLE, S_READ_FIFO, S_LATCH_AND_START_TX, S_WAIT_TX_DONE

3. uart_tx.v
-   UART transmitter with 1 start bit, 8 data bits, and 1 stop bit
-   Baud rate generator (115200 bps from 50 MHz system clock)
-   Clocked serial_out with glitch prevention

4. uart_packetizer_top.v
-   Top-level integration of FIFO, FSM, and UART modules
-   Unified under a 50 MHz clock domain

🧪 Testbench
-   uart_packetizer_tb.v
-   Simulates writing 16 bytes (0x30 to 0x3F) into FIFO
-   Verifies UART output structure for bytes like 0x5A and 0xF0
-   Validates FIFO control logic, FSM transitions, and proper serial framing

🛠 Features
-   Asynchronous FIFO with clean CDC implementation
-   Clocked serial_out design to prevent glitches/spikes
-   Testbench tasks to verify bit-wise UART framing
-   Modular and scalable RTL architecture


 


