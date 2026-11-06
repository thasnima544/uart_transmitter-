
`timescale 1ns/1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 4
)(
    input wire clk,
    input wire rst,
    input wire tx_start,
    input wire [7:0] tx_data,

    output reg tx,
    output wire busy,
    output reg tx_done
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;

    reg [7:0] tx_data_reg;

    // Busy is high whenever the transmitter is active
    assign busy = (state != IDLE);

    always @(posedge clk) begin

        if (rst) begin
            state       <= IDLE;
            clk_count   <= 0;
            bit_index   <= 0;
            tx_data_reg <= 0;
            tx          <= 1'b1;
            tx_done     <= 1'b0;
        end

        else begin

            // Default: tx_done is a one-clock pulse
            tx_done <= 1'b0;

            case (state)

                // Idle state
                IDLE: begin
                    tx <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        state <= START;
                    end
                end

                // Transmit start bit
                START: begin
                    tx <= 1'b0;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                // Transmit 8 data bits, LSB first
                DATA: begin
                    tx <= tx_data_reg[bit_index];

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;

                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                // Transmit stop bit
                STOP: begin
                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= IDLE;
                        tx_done <= 1'b1;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                end

            endcase
        end
    end

endmodule
