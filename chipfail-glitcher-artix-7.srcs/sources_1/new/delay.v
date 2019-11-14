`timescale 1ns / 1ps


module delay(
    input clk,
    input reset,
    input enable,
    input [31:0] length,
    output reg done,
    output reg [1:0] state = 4'd0
    );

parameter STATE_IDLE = 2'd0;
parameter STATE_DELAY = 2'd1;

reg [31:0] counter = 32'd0;


always @(posedge clk)
begin
    // default assignments
    state <= state;
    counter <= counter;
    done <= 1'd0;

    if(reset)
    begin
        counter <= 32'd0;
        state <= STATE_IDLE;
    end
    else
    begin
        case(state)
            STATE_IDLE:
            begin
                if(enable)
                begin
                    counter <= 32'd0;
                    state <= STATE_DELAY;
                end
            end
            STATE_DELAY:
            begin
                counter <= counter + 1;
                if(counter == length)
                begin
                    done <= 1'd1;
                    state <= STATE_IDLE;
                end
            end
        endcase
    end
end

endmodule
