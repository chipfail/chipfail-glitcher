`timescale 1ns / 1ps

// Definitons for the UART clockings 
`define SYSTEM_CLOCK    100_000_000

// 115200 8N1
`define UART_FULL_ETU	(`SYSTEM_CLOCK/115200)
`define UART_HALF_ETU	((`SYSTEM_CLOCK/115200)/2)
