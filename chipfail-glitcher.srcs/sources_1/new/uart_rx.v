`timescale 1ns / 1ps
`include "uart_definitions.v"


module uart_rx(
    // System clock
    input wire clk,
    // Data input
    output reg [7:0] data,
    // Resets the entire module
    input wire reset,
    
    // The data line
    input wire rx,

    // Indicates the module is ready to receive
    output reg valid
    );

// States
parameter STATE_IDLE = 4'd0;
parameter STATE_START_BIT = 4'd1;
parameter STATE_DATA_BITS = 4'd2;
parameter STATE_STOP_BIT = 4'd3;

// Hold state in this
reg [3:0] state = STATE_IDLE;

// The bit we are sending currently
reg [3:0] current_bit = 4'd0;

// Counter for baudrate
reg [31:0] etu_counter = 32'd0;

wire etu_full;
wire etu_half;

assign etu_full = (etu_counter == `UART_FULL_ETU);
assign etu_half = (etu_counter == `UART_HALF_ETU);

always @(posedge clk)
begin
    if(reset == 1'b1)
    begin
        state <= STATE_IDLE;
        current_bit <= 4'd0;
        data <= 8'd0;
    end
    else // not resetting
    begin
        // default assignments
        valid <= 1'd0;
        data <= data;
        current_bit <= current_bit;
        state <= state;

        etu_counter <= etu_counter + 1;
        
        case(state)
            STATE_IDLE:
            begin
                // Start condition detected
                if(rx == 1'd0)
                begin
                    state <= STATE_START_BIT;
                    etu_counter <= 32'd0;
                    current_bit <= 4'd0;
                end
            end
            STATE_START_BIT:
            begin
                if(etu_half)
                begin
                    state <= STATE_DATA_BITS;
                    etu_counter <= 32'd0;
                    current_bit <= 32'd0;
                end
            end
            STATE_DATA_BITS:
            begin
                if(etu_full)
                begin
                    data <= {rx, data[7:1]};
                    current_bit <= current_bit + 1;
                    etu_counter <= 32'd0;
                    if(current_bit == 4'd7)
                    begin
                        state <= STATE_STOP_BIT;
                    end
                end
            end
            STATE_STOP_BIT:
            begin
                if(etu_full)
                begin
                    valid <= 1'b1;
                    state <= STATE_IDLE;
                    etu_counter <= 32'd0;
                end
            end
        endcase
    end
end

endmodule
