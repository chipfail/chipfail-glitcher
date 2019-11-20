`timescale 1ns / 1ps


module pulse(
    input clk,
    input reset,
    input enable,
    input [31:0] length,
    output reg pulse = 1'd0,
    output reg done = 1'd0,
    output reg [1:0] state = 2'd0
    );

reg [31:0] counter = 32'd0;

parameter STATE_IDLE = 2'd0;
parameter STATE_PULSE = 2'd1;

always @(posedge clk)
begin
    // default assignments
    state <= state;
    counter <= counter;
    pulse <= 1'd0;
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
                    state <= STATE_PULSE;
                    pulse <= 1'd1;
                end
            end
            STATE_PULSE:
            begin
                counter <= counter + 1;
                pulse <= 1'd1;
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
