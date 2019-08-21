`timescale 1ns / 1ps

module top(
    input sys_clk,
    output [1:0] led,  // Led outputs
    output [2:0] rgb,  // RGB led
    input [1:0] btn, // buttons
    input [7:0] gpio, // GPIOs
    input uart_txd_in, // This is the RX input.. thanks for the naming digilent :D
    output uart_rxd_out, // This is the TX output
    
    input trigger_in,
    output power_out,
    output glitch_out
    );

// Clock
wire main_clk;
// Generate a 100MHz clock from the external 12MHz clock
clk_wiz_0 clock_generator
(
// Clock out ports
.main_clk(main_clk),     // output main_clk
// Clock in ports
.clk_in1(sys_clk));      // input clk_in1


// deal with fucking meta stability
reg uart_rxd_stable = 1'd0;
always @(posedge main_clk)
begin
    uart_rxd_stable <= uart_txd_in;
end

// Used to reset all modules (not fully functional currently)
// TODO add debouncer for button
reg reset = 1'd0;

// Main UART transmitter
reg tx_enable = 1'd0;
reg [7:0] tx_data = 8'd67;
wire tx_ready;
uart_tx tx1(
    .clk(main_clk),
    .reset(reset),
    .data(tx_data),
    .enable(tx_enable),
    .tx(uart_rxd_out),
    .ready(tx_ready)
);

// Main UART receiver
wire [7:0] rx_data;
wire rx_valid;
uart_rx rx1(
    .clk(main_clk),
    .reset(reset),
    .data(rx_data),
    .rx(uart_rxd_stable),
    .valid(rx_valid)
);

// COMMANDS
// power cycle the target (B)
parameter CMD_POWER_CYCLE = 8'd66;
// set the duration of the glitch pulse (uint32) (C)
parameter CMD_SET_GLITCH_PULSE = 8'd67;
// set the duration of the delay between the trigger input and the glitch (uint32) (D)
parameter CMD_SET_DELAY = 8'd68;
// set the duration of the pulse used to reset the device (uint32) (E)
parameter CMD_SET_POWER_PULSE = 8'd69;
// execute glitch (wait for trigger, wait for $delay, send glitch pulse) (F)
parameter CMD_GLITCH = 8'd70;
// read the 8 gpio pins. returns a single byte with the states of the IOs (G)
parameter CMD_READ_GPIO = 8'd71;
// enable or disable the powercycle before glitching. (bool/single byte 0 or 1) (H)
parameter CMD_ENABLE_GLITCH_POWER_CYCLE = 8'd72;
// returns the state of power pulse, trigger, delay, glitch pulse
parameter CMD_GET_STATE = 8'd73;


// STATES
// Wait for a single command on UART
// white
parameter STATE_WAIT_COMMAND = 8'd0;
// Wait for 4 bytes on UART that set the glitch pulse
// purple
parameter STATE_SET_GLITCH_PULSE = 8'd2;
// Wait for 4 bytes on UART that set the delay
// red
parameter STATE_SET_DELAY = 8'd3;
// Wait for 4 bytes on UART that set the power cycle duration
// cyan
parameter STATE_SET_POWER_PULSE = 8'd4;
// Wait for 1 byte on UART that sets whether the target is power cycled before glitch
// green
parameter STATE_ENABLE_GLITCH_POWER_CYCLE = 8'd5;
// Wait for the power cycle to be over.
// blue
parameter STATE_WAIT_POWER_CYCLE = 8'd6;

reg [7:0] state = STATE_WAIT_COMMAND;

// Receiver for receiving uint32 via serial
reg u32_rec_enable = 1'd0;
wire u32_rec_valid;
wire [31:0] u32_rec_data;
uint32_receiver u32_rec(
    .clk(main_clk),
    .reset(reset),
    .uart_data(rx_data),
    .uart_valid(rx_valid),
    .data(u32_rec_data),
    .data_valid(u32_rec_valid),
    .enable(u32_rec_enable)
);

// Variables used by the glitcher
reg [31:0] glitch_pulse_length = 32'd0;
reg [31:0] glitch_delay_length = 32'd0;
reg [31:0] power_pulse_length = 32'd0;
// whether the device should be powercycled before glitching
reg glitch_power_cycle = 1'd0;
// Indicate current state on RGB led
assign rgb = state[2:0];


// power pulse
// only used in glitch chain if glitch_power_cycle is 1 
reg power_pulse_enable = 1'd0;
wire power_pulse_pulse;
wire power_pulse_done;
// Used to output diagnostics via UART
wire [1:0] power_pulse_state;
pulse power_pulse(
    .clk(main_clk),
    .reset(reset),
    .enable(power_pulse_enable),
    .length(power_pulse_length),
    .pulse(power_pulse_pulse),
    .done(power_pulse_done),
    .state(power_pulse_state)
);

// trigger
reg glitch_trigger_enable = 1'b0;
// Used to disable the entire trigger during a power-cycle-only
reg disable_trigger = 1'b0;
wire glitch_trigger_enable_mixed = ((power_pulse_done && glitch_power_cycle) || glitch_trigger_enable) && ~disable_trigger;
reg [31:0] glitch_trigger_length = 32'd255;
wire glitch_trigger_triggered;
wire [1:0] glitch_trigger_state;

trigger glitch_trigger(
    .clk(main_clk),
    .reset(reset),
    .enable(glitch_trigger_enable_mixed),
    .in(trigger_in),
    .trigger_length(glitch_trigger_length),
    .triggered(glitch_trigger_triggered),
    .state(glitch_trigger_state)
    );

// glitch delay
wire glitch_delay_done;
wire [1:0] glitch_delay_state;
delay glitch_delay(
    .clk(main_clk),
    .reset(reset),
    .enable(glitch_trigger_triggered),
    .length(glitch_delay_length),
    .done(glitch_delay_done),
    .state(glitch_delay_state)
);


// glitch pulse
// mix our manual glitch enable with the output from the delay
wire glitch_pulse_pulse;
wire glitch_pulse_done;
wire [1:0] glitch_pulse_state;
pulse glitch_pulse(
    .clk(main_clk),
    .reset(reset),
    .enable(glitch_delay_done),
    .length(glitch_pulse_length),
    .pulse(glitch_pulse_pulse),
    .done(glitch_pulse_done),
    .state(glitch_pulse_state)
);

assign led[0] = power_pulse_pulse;
assign led[1] = glitch_pulse_pulse;
assign power_out = power_pulse_pulse;
// We also pull glitch high when power resetting to make sure we don't accidentally keep the core on 
assign glitch_out = power_pulse_pulse || glitch_pulse_pulse;

always @(posedge main_clk)
begin
    // default assignments
    u32_rec_enable <= 1'd0;
    glitch_pulse_length <= glitch_pulse_length;
    glitch_delay_length <= glitch_delay_length;
    power_pulse_length <= power_pulse_length;
    power_pulse_enable <= 1'd0;
    glitch_power_cycle <= glitch_power_cycle;
    
    glitch_trigger_enable <= 1'd0;
    disable_trigger <= disable_trigger;
    
    state <= state;
    tx_enable <= 1'b0;

    case(state)
        STATE_WAIT_COMMAND:
        begin
            if(rx_valid)
            begin
                case(rx_data)
                    CMD_SET_GLITCH_PULSE:
                    begin
                        state <= STATE_SET_GLITCH_PULSE;
                        u32_rec_enable <= 1'd1;
                    end
                    CMD_SET_DELAY:
                    begin
                        state <= STATE_SET_DELAY;
                        u32_rec_enable <= 1'd1;
                    end
                    CMD_SET_POWER_PULSE:
                    begin
                        state <= STATE_SET_POWER_PULSE;
                        u32_rec_enable <= 1'd1;
                    end
                    CMD_READ_GPIO:
                    begin
                        tx_data <= gpio;
                        tx_enable <= 1'b1;
                    end
                    CMD_ENABLE_GLITCH_POWER_CYCLE:
                    begin
                        state <= STATE_ENABLE_GLITCH_POWER_CYCLE;
                    end
                    CMD_GLITCH:
                    begin
                        // If glitch with power cycle is enabled we 
                        // use the power pulse to start the glitch
                        // (which will then in turn start the trigger)
                        if(glitch_power_cycle == 1'b1)
                        begin
                            power_pulse_enable <= 1'b1;
                        end
                        else
                        // Otherwise we directly enable the trigger
                        begin
                            glitch_trigger_enable <= 1'b1;
                        end
                    end
                    CMD_POWER_CYCLE:
                    begin
                        power_pulse_enable <= 1'b1;
                        disable_trigger <= 1'b1;
                        state <= STATE_WAIT_POWER_CYCLE;
                    end
                    CMD_GET_STATE:
                    begin
                        tx_data <= {power_pulse_state, glitch_trigger_state, glitch_delay_state, glitch_pulse_state};
                        tx_enable <= 1'b1;
                    end
                    
                endcase
            end
            
        end
        STATE_SET_GLITCH_PULSE:
        begin
            if(u32_rec_valid)
            begin
                glitch_pulse_length <= u32_rec_data;
                state <= STATE_WAIT_COMMAND;
            end
        end
        STATE_SET_DELAY:
        begin
            if(u32_rec_valid)
            begin
                glitch_delay_length <= u32_rec_data;
                state <= STATE_WAIT_COMMAND;
            end
        end
        STATE_SET_POWER_PULSE:
        begin
            if(u32_rec_valid)
            begin
                power_pulse_length <= u32_rec_data;
                state <= STATE_WAIT_COMMAND;
            end
        end
        STATE_ENABLE_GLITCH_POWER_CYCLE:
        begin
            if(rx_valid)
            begin
                glitch_power_cycle <= rx_data[0];
                state <= STATE_WAIT_COMMAND;
            end
        end
        STATE_WAIT_POWER_CYCLE:
        begin
            if(power_pulse_done)
            begin
                disable_trigger <= 1'b0;
                state <= STATE_WAIT_COMMAND;
            end
        end
    endcase
end


endmodule
