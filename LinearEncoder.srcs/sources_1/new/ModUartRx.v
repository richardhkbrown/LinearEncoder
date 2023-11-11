`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2023 03:09:07 PM
// Design Name: 
// Module Name: ModUartRx
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


module ModUartRx
#(parameter BAUD = 9600, parameter CLK_RATE = 100000000)
(
    input clk,
    input RsRx,
    output reg req = 0,
    input ack,
    output [7:0] data
    );
    
    // Create cycle counter
    localparam real PERIOD = CLK_RATE/BAUD;
    localparam integer BITS_NEEDED = $clog2($rtoi(PERIOD)+1);
    localparam [(BITS_NEEDED-1):0] RESET_COUNT = $rtoi(PERIOD);
    localparam [(BITS_NEEDED-1):0] HALF_COUNT = $rtoi(0.5*PERIOD);
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
    reg [7:0] dataIn = 8'd0;
    assign DI = dataIn;
    // assign data = DO;
    assign data = dataIn;
    assign TC = 1'b1;
    assign CE = 1'b1;
    reg writeEn = 0;
    assign WREN = writeEn && !FULL;
    reg readEn = 0;
    assign RDEN = readEn && !FULL;
    assign RST = fifoResetCount>0;
            
    // Reset fifo
    always @ ( posedge(CLK) ) begin
        if ( fifoResetCount>0 ) begin
            fifoResetCount <= fifoResetCount - 1;
        end
    end
    
    // State machines
    reg [($clog2(12+1)):0] state = 0; // 12 is max state
    
    always @ ( posedge(clk) ) begin
    
        // Counter
        if ( state!=0 && counter<RESET_COUNT ) begin
            counter <= counter+1;
        end else begin
            counter <= 0;
        end

        // UART read
        if ( state==0 ) begin
            if ( !RsRx ) begin
                state <= 1;
            end
        end else if ( state==10 ) begin
            writeEn <= 1;
            state <= 11;
        end else if ( state==11 ) begin
            writeEn <= 0;
            state <= 12;
        end

        // Parallel to serial
        if ( counter==HALF_COUNT ) begin
            case ( state )
            
                1:
                    begin
                        state <= state + 1; // wait for start bit to end
                    end

                2,3,4,5,6,7,8,9:
                    begin
                        dataIn[state-2] <= RsRx;
                        state <= state + 1;
                    end
                    
                12:
                    if ( RsRx ) begin
                        state <= 0; // wait for end bit to end
                    end
                    
                default:
                    begin
                    end
                    
            endcase
        end
        
    end
    
    // Req Ack state machine
    reg [($clog2(3+1)):0] reqAckState = 0; // 3 is max state
    always @ ( posedge(clk) ) begin
    
        case ( reqAckState )
        
            0:
                if ( !EMPTY ) begin
                    readEn <= 1;
                    reqAckState <= 1;
                end
            
            1:
                begin
                    readEn <= 0;
                    req <= 1;
                    reqAckState <= 2;
                end
                
            2:
                if ( ack ) begin
                     req <= 0;
                     reqAckState <= 3;
                end
            
             3:
                if ( !ack ) begin
                    reqAckState <= 0;
                end
                
            default:
                begin
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
      .RDEN(RDEN),               // 1-bit input read enable
      .RST(RST),                 // 1-bit input reset
      .WREN(WREN)                // 1-bit input write enable
    );

   // End of FIFO_SYNC_MACRO_inst instantiation
   
endmodule
