`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2023 02:50:43 PM
// Design Name: 
// Module Name: TopFile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TopFile(
    input clk,
    input RsRx,
    output RsTx,
    output [11:0] led
    );
    
    wire req;
    wire ack;
    wire [7:0] data;
    ModUartRx instRx( .clk(clk), .RsRx(RsRx), .req(req), .ack(ack), .data(data) );
    ModUartTx instTx( .clk(clk), .RsTx(RsTx), .req(req), .ack(ack), .data(data) );
    assign led = { data, req, ack, RsRx, RsTx };


endmodule
