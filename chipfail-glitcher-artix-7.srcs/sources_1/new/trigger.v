`timescale 1ns / 1ps

module trigger(
    input clk,
    input reset,
    input enable,
    input in,
    input [31:0] trigger_length,
    output reg triggered = 1'd0,
    output reg [1:0] state = 2'd0
    );

parameter STATE_IDLE = 2'd0;
parameter STATE_WAIT_LOW = 2'd1;
parameter STATE_TRIGGERING = 2'd2;

reg [31:0] counter;

always @(posedge clk)
begin
    triggered <= 1'd0;
    counter <= counter;
    state <= state;
    if(reset)
    begin
        counter <= 1'd0;
        state <= STATE_IDLE;
    end
    else
    begin
        case(state)
            STATE_IDLE:
            begin
                if(enable)
                begin
                    state <= STATE_WAIT_LOW;
                end
            end
            STATE_WAIT_LOW:
            begin
                if(in == 1'b0)
                begin
                    state <= STATE_TRIGGERING;
                end
            end
            STATE_TRIGGERING:
            begin
                if(in)
                begin
                    counter <= counter + 1;
                    if(counter == trigger_length)
                    begin
                        triggered <= 1'd1;
                        state <= STATE_IDLE;
                    end
                end
                else
                begin
                    counter <= 0;
                end
            end
        endcase
        
    end
end

endmodule
