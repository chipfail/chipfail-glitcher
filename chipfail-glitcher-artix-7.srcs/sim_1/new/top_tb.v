`timescale 1ns / 1ps


module top_tb(
 input sys_clk
);


reg clk;
reg [7:0] data = 8'd64;
reg enable = 1'b1;
reg rst = 1'b0;
always
    begin
        clk = 1'b1;
        #10;
        clk = 1'b0;
        #10;
    end

wire [1:0] led;
wire uart_tx;

//top t1(
//    .sys_clk(clk),
//    .led(led),
//    .uart_txd_in(uart_tx)
//);

//module top(
//    input sys_clk,
//    output [1:0]led,  // Led outputs
//    output uart_txd_in // UART TX (strange txd_in name by Digilent)
//    );





uart_tx tx1(
    .clk(sys_clk),
    .reset(rst),
    .data(data),
    .enable(enable),
    .tx(uart_tx)
);

top t(
    .sys_clk(clk),
    .uart_txd_in(uart_tx)
);




//uart_rx rx1(
//    .clk(clk),
//    .reset(rst),
//    .rx(tx1.tx)
//);

endmodule
