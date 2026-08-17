// ============================================================================
//  spi_slave_io.v     v1.0
//  
//  SPI SLAVE IO   BY Eric Yang    2026.08
// ============================================================================

module spi_slave_io (
    inout  wire     pad_rst_n,
    inout  wire     pad_ssn,
    inout  wire     pad_sck,
    inout  wire     pad_mosi,
    inout  wire     pad_miso
);

    wire rst_n_i, ssn_i, sck_i, mosi_i;
    wire miso_o, miso_oen;

    spi_slave #(
        .DW     (16),
        .AW     (3)
    ) u_core (
        .rst_n      (rst_n_i),
        .ssn        (ssn_i),
        .sck        (sck_i),
        .mosi       (mosi_i),
        .miso       (miso_o),
        .miso_oen   (miso_oen)
    );

    // ---- inputs ----
    PRUW0812SCDG u_pad_rst_n (
        .PAD (pad_rst_n), .C (rst_n_i),
        .I   (1'b0), .OEN (1'b1), .IE (1'b1), .PE (1'b1), .DS (1'b1)
    );

    PRUW0812SCDG u_pad_ssn (
        .PAD (pad_ssn), .C (ssn_i),
        .I   (1'b0), .OEN (1'b1), .IE (1'b1), .PE (1'b1), .DS (1'b1)
    );

    PRDW0812SCDG u_pad_sck (
        .PAD (pad_sck), .C (sck_i),
        .I   (1'b0), .OEN (1'b1), .IE (1'b1), .PE (1'b1), .DS (1'b1)
    );

    PRDW0812SCDG u_pad_mosi (
        .PAD (pad_mosi), .C (mosi_i),
        .I   (1'b0), .OEN (1'b1), .IE (1'b1), .PE (1'b1), .DS (1'b1)
    );

    // ---- miso, tri-state ----
    PRDW0812SCDG u_pad_miso (
        .PAD (pad_miso), .C (),
        .I   (miso_o), .OEN (miso_oen), .IE (1'b0), .PE (1'b0), .DS (1'b0)
    );

endmodule
