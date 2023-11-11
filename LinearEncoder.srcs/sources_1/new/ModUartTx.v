`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2023 05:17:50 PM
// Design Name: 
// Module Name: ModUartTx
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


module ModUartTx
#(parameter BAUD = 9600, parameter CLK_RATE = 100000000)
(
    input clk,
    output reg RsTx = 1,
    input req,
    output reg ack,
    input [7:0] data
    );
    
    // Create cycle counter
    localparam real PERIOD = CLK_RATE/BAUD;
    localparam integer BITS_NEEDED = $clog2($rtoi(PERIOD)+1);
    localparam [(BITS_NEEDED-1):0] RESET_COUNT = $rtoi(PERIOD);
    reg [(BITS_NEEDED-1):0] counter = 0;

    // Fifo connections
    wire ALMOSTEMPTY;
    wire ALMOSTFULL;
    wire [7:0] DO;
    wire EMPTY;
    wire FULL;
    wire [10:0] RDCOUNT;
    wire RDERR;
    wire [10:0] WRCOUNT;
    wire WRERR;
    wire CLK;
    wire [7:0] DI;
    wire RDEN;
    wire RST;
    wire WREN;
    
    // Fifo assignment
    assign CLK = clk;
    localparam integer FIFO_RESET_COUNT = 4;
    reg [($clog2(FIFO_RESET_COUNT+1)):0] fifoResetCount = FIFO_RESET_COUNT;
    assign DI = data;      
    assign TC = 1'b1;
    assign CE = 1'b1;
    reg writeEn = 0;
    assign WREN = writeEn && !FULL;
    reg readEn = 0;
    assign RDEN = readEn && !EMPTY;
    assign RST = fifoResetCount>0;
    
    // Reset fifo
    always @ ( posedge(CLK) ) begin
        if ( fifoResetCount>0 ) begin
            fifoResetCount <= fifoResetCount - 1;
        end
    end
    
    // State machines
    reg [($clog2(11+1)):0] state = 0; // 11 is max state
    always @ ( posedge(clk) ) begin
    
        // Counter
        if ( state!=0 && counter<RESET_COUNT ) begin
            counter <= counter+1;
        end else begin
            counter <= 0;
        end

        // UART read
        if ( state==0 && fifoResetCount==0 ) begin
            if ( !EMPTY ) begin
                RsTx <= 0; // start bit
                readEn <= 1;
                state <= 1;
            end
        end else if ( state==1 ) begin
            readEn <= 0;
            state <= 2;
        end

        // Parallel to serial
        if ( counter==RESET_COUNT ) begin
            case ( state )

                2,3,4,5,6,7,8,9:
                    begin
                        RsTx <= DO[state-2];
                        state <= state + 1;
                    end
                    
                10:
                    begin
                        RsTx <= 1; // stop bit
                        state <= state + 1;
                    end
                    
                11:
                    state <= 0;
                    
                default:
                    begin
                    end
                    
            endcase
        end
        
    end
    
    // Req Ack state machine
    reg [($clog2(2+1)):0] reqAckState = 0; // 2 is max state
    always @ ( posedge(clk) ) begin
    
        case ( reqAckState )
        
            0:
                if ( req ) begin
                    writeEn <= 1;
                    reqAckState <= 1;
                end
            
            1:
                begin
                    writeEn <= 0;
                    ack <= 1;
                    reqAckState <= 2;
                end
                
            2:
                if ( !req ) begin
                     ack <= 0;
                     reqAckState <= 0;
                end
        
        endcase
    
    end

   // FIFO_SYNC_MACRO: Synchronous First-In, First-Out (FIFO) RAM Buffer
   //                  Artix-7
   // Xilinx HDL Language Template, version 2022.2

   /////////////////////////////////////////////////////////////////
   // DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
   // ===========|===========|============|=======================//
   //   37-72    |  "36Kb"   |     512    |         9-bit         //
   //   19-36    |  "36Kb"   |    1024    |        10-bit         //
   //   19-36    |  "18Kb"   |     512    |         9-bit         //
   //   10-18    |  "36Kb"   |    2048    |        11-bit         //
   //   10-18    |  "18Kb"   |    1024    |        10-bit         //
   //    5-9     |  "36Kb"   |    4096    |        12-bit         //
   //    5-9     |  "18Kb"   |    2048    |        11-bit         //
   //    1-4     |  "36Kb"   |    8192    |        13-bit         //
   //    1-4     |  "18Kb"   |    4096    |        12-bit         //
   /////////////////////////////////////////////////////////////////

   FIFO_SYNC_MACRO  #(
      .DEVICE("7SERIES"), // Target Device: "7SERIES" 
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(8), // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DO_REG(0),     // Optional output register (0 or 1)
      .FIFO_SIZE ("18Kb")  // Target BRAM: "18Kb" or "36Kb" 
   ) FIFO_SYNC_MACRO_inst (
      .ALMOSTEMPTY(ALMOSTEMPTY), // 1-bit output almost empty
      .ALMOSTFULL(ALMOSTFULL),   // 1-bit output almost full
      .DO(DO),                   // Output data, width defined by DATA_WIDTH parameter
      .EMPTY(EMPTY),             // 1-bit output empty
      .FULL(FULL),               // 1-bit output full
      .RDCOUNT(RDCOUNT),         // Output read count, width determined by FIFO depth
      .RDERR(RDERR),             // 1-bit output read error
      .WRCOUNT(WRCOUNT),         // Output write count, width determined by FIFO depth
      .WRERR(WRERR),             // 1-bit output write error
      .CLK(CLK),                 // 1-bit input clock
      .DI(DI),                   // Input data, width defined by DATA_WIDTH parameter
      .RDEN(RDEN),            // 1-bit input read enable
      .RST(RST),                 // 1-bit input reset
      .WREN(WREN)                // 1-bit input write enable
    );

   // End of FIFO_SYNC_MACRO_inst instantiation
   
endmodule
