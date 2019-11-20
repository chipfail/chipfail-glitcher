`timescale 1ns / 1ps
`include "uart_definitions.v"

module uart_tx(
    // System clock
    input wire clk,
    // Data input
    input wire [7:0] data,
    // Enable, pull high for one cycle to start sending
    input wire enable,
    // Resets the entire module
    input wire reset,
    
    // The data line
    output reg tx,
    // Indicates the module is ready to receive
    output reg ready = 1'b1
    );



// States
parameter STATE_IDLE = 4'd0;
parameter STATE_START_BIT = 4'd1;
parameter STATE_DATA_BITS = 4'd2;
parameter STATE_STOP_BIT = 4'd3;
parameter STATE_DONE = 4'd5;

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

reg [7:0] data_local;

always @(posedge clk)
begin
    if(reset == 1'b1)
    begin
        state <= STATE_IDLE;
        current_bit <= 8'd0;
        tx <= 1'b1;
    end
    else
    begin
        // Default assignments
        tx <= tx;
        ready <= ready;
        state <= state;
        current_bit <= current_bit;
        data_local <= data_local;

        // Always count up the ETU counter
        etu_counter <= etu_counter + 1'd1;

        case(state)
            STATE_IDLE:
            begin
                // Our state is idle, but we just got an enable signal. Start sending!
                if(enable)
                begin
                    data_local <= data;
                    state <= STATE_DATA_BITS;
                    tx <= 1'b0;
                    ready <= 1'b0;
                    current_bit <= 4'd0;
                    // Start etu_counter
                    etu_counter <= 32'd0;
                end
                else
                begin
                    tx <= 1'b1;
                    ready <= 1'b1;
                end
            end
            STATE_START_BIT:
            begin
                    state <= STATE_DATA_BITS;
                    etu_counter <= 32'd0;
            end
            STATE_DATA_BITS:
            begin
                if(etu_full)
                begin
                    etu_counter <= 32'd0;
                    tx <= data_local[0];
                    data_local <= {data_local[0], data_local[7:1]};
                    current_bit <= current_bit + 1'd1;
                    if(current_bit == 3'd7)
                    begin
                        state <= STATE_STOP_BIT;
                    end
                end
            end
            STATE_STOP_BIT:
            begin
                if(etu_full)
                begin
                    tx <= 1'd1;
                    etu_counter <= 32'd0;
                    state <= STATE_DONE;
                end
            end
            STATE_DONE:
            begin
                if(etu_full)
                begin
                    ready <= 1'b1;
                    state <= STATE_IDLE;
                end
            end
        endcase
    end
    
end




endmodule
