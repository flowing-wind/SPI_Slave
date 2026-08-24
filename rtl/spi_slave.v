// ============================================================================
//  spi_slave.v     v1.0
//  
//  SPI SLAVE   BY Eric Yang    2026.08
//
//  Features
//  - CPOL=0, CPHA=0
//  - MSB first
//  - Back to back transfer support
//  - 8 x 16-bit registers available
//  - Read data within the same frame
//  - No system clock
//  - 24-bit self-defined frame protocol
//
//  Frame Structure (MSB first)
//      [23]     RW     0 = write, 1 = read
//      [22:16]  ADDR   only the low AW bits are decoded, upper bits ignored
//      [15:0]   DATA
// ============================================================================

module spi_slave #(
    parameter integer DW = 16,  // Data Width
    parameter integer AW = 3    // Address Width
) (
    input  wire rst_n,
    input  wire ssn,
    input  wire sck,
    input  wire mosi,
    output wire miso,
    output wire miso_oen
);

    localparam integer CW    = 8;       // Command Width
    localparam integer FW    = CW + DW; // Frame Width = 24
    localparam integer CNT_W = 5;       // Change CNT_W if FW changes
    localparam integer REG_N = 1 << AW; // 8 regs, 16 bits each

    localparam [CNT_W-1:0] CNT_CMD  = CW - 1;   // 7,  latch command
    localparam [CNT_W-1:0] CNT_LOAD = CW;       // 8,  load tx (neg edge)
    localparam [CNT_W-1:0] CNT_LAST = FW - 1;   // 23, write mem
    
    // Clear frame state on deselect, do not apply to mem
    wire sck_rstn = rst_n & ~ssn;

    // -------------------------------
    //  Receive shifter.
    // -------------------------------
    reg  [DW-2:0]    rx;    // DW-1 bits, the last bit is taken from mosi
    reg  [CNT_W-1:0] bit_cnt;

    always @(posedge sck or negedge sck_rstn) begin
        if (!sck_rstn) begin
            rx      <= {(DW-1){1'b0}};
            bit_cnt <= {CNT_W{1'b0}};
        end
        else begin
            rx      <= {rx[DW-3:0], mosi};
            bit_cnt <= (bit_cnt == CNT_LAST) ? {CNT_W{1'b0}} : (bit_cnt + 1'b1);
        end
    end

    // -------------------------------
    //  Command latch.
    // -------------------------------
    wire [CW-1:0] cmd_w = {rx[CW-2:0], mosi};   // If tx needed, data should be prepared next sample edge
    reg           cmd_rw;
    reg [AW-1:0]  cmd_addr;

    always @(posedge sck or negedge sck_rstn) begin
        if (!sck_rstn) begin
            cmd_rw   <= 1'b0;
            cmd_addr <= {AW{1'b0}};
        end
        else if (bit_cnt == CNT_CMD) begin
            cmd_rw   <= cmd_w[CW-1];    // read/write signal
            cmd_addr <= cmd_w[AW-1:0];  // read/write address
        end
    end

    // -------------------------------
    //  Register file.
    // -------------------------------
    wire [DW-1:0] data_w = {rx[DW-2:0], mosi};
    wire          wr_en  = (bit_cnt == CNT_LAST) & ~cmd_rw;
    reg [DW-1:0] mem [0:REG_N-1];

    integer i;
    always @(posedge sck or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < REG_N; i = i + 1)
                mem[i] <= {DW{1'b0}};
        end
        else if (wr_en) begin
            mem[cmd_addr] <= data_w;
        end
    end

    // -------------------------------
    //  Readback and miso.
    // -------------------------------
    wire [DW-1:0] rd_data = mem[cmd_addr];
    reg [DW-1:0] tx;
    always @(negedge sck or negedge sck_rstn) begin     // Loads data on falling edge of sck
        if (!sck_rstn)
            tx <= {DW{1'b0}};
        else if (bit_cnt == CNT_LOAD)   // On falling edge, cnt already + 1
            tx <= cmd_rw ? rd_data : {DW{1'b0}};
        else
            tx <= {tx[DW-2:0], 1'b0};   // MSB first, fill 0 when idle, so the first byte is always 0x00
    end

    assign miso = tx[DW-1];
    assign miso_oen = ssn;

endmodule
