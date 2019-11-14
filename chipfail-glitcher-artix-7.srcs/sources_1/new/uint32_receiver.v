`timescale 1ns / 1ps

module uint32_receiver(
    input clk,
    input reset,
    input enable,
    
    // UART data
    input [7:0] uart_data,
    input uart_valid,
    
    // The data received
    output reg [31:0] data,
    // Whether the current output on data is valid
    output reg data_valid = 1'b0
    );

parameter STATE_IDLE = 4'd0;
parameter STATE_RECEIVING = 4'd1;

reg [3:0] state = STATE_IDLE;

reg [3:0] received_bytes = 4'd0;

always @(posedge clk)
begin
    // default assignments
    received_bytes <= received_bytes;
    state <= state;
    data_valid <= 1'b0;
    data <= data;
    if(reset)
    begin
        received_bytes <= 4'd0;
        state <= STATE_IDLE;
    end
    else
    begin
        case(state)
            STATE_IDLE:
            begin
                if(enable)
                begin
                    received_bytes <= 4'd0;
                    data_valid <= 4'd0;
                    state <= STATE_RECEIVING;
                end
            end
            STATE_RECEIVING:
            begin
                if(uart_valid)
                begin
                    data <= {data[23:0], uart_data};
                    received_bytes <= received_bytes + 1;
                    if(received_bytes == 3)
                    begin
                        state <= STATE_IDLE;
                        data_valid <= 1'b1;
                    end
                end
            end
        endcase        
    end
end

endmodule
