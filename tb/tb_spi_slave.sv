// ============================================================================
//  tb_spi_slave.sv      v1.0
//  
//  SPI SLAVE TESTBENCH     BY Eric Yang    2026.08
// ============================================================================

`timescale 1ns/1ps

module tb_spi_slave;
    
    // -------------------------------
    //  Device Under Test.
    // -------------------------------
    logic rst_n, ssn, sck, mosi;
    wire  miso, miso_oen;

    spi_slave dut (
        .rst_n      (rst_n),
        .ssn        (ssn),
        .sck        (sck),
        .mosi       (mosi),
        .miso       (miso),
        .miso_oen   (miso_oen)
    );

    // -------------------------------
    //  Covergroups.
    // -------------------------------
    localparam int REG_N = 8;
    covergroup cg_frame_t with function sample(
        bit rw,
        bit [6:0]  addr,
        bit [15:0] data
    );
        option.per_instance = 1;

        // Cover both read and write
        cp_rw : coverpoint rw {
            bins write = {1'b0};
            bins read  = {1'b1};
        }

        // Cover all 8 regs
        cp_addr : coverpoint addr[2:0] {
            bins reg_n[] = {[0:REG_N-1]};
        }

        // Cover arbitrary addr_hi
        cp_arb_addr : coverpoint (addr[6:3] != 4'h0) {
            bins normal  = {1'b0};
            bins aliased = {1'b1};
        }

        // Cover data with boundary conditions
        cp_data : coverpoint data iff (!rw) {   // Write data only
            bins all_zeros = {16'h0000};
            bins all_ones  = {16'hFFFF};
            bins others[4] = {[16'h0001:16'hFFFE]};
        }

        // All regs should be both read and written
        cx_rw_addr : cross cp_rw, cp_addr;

    endgroup
    cg_frame_t cg_frame;

    // -------------------------------
    //  Tasks.
    // -------------------------------
    int errors = 0;
    int checks = 0;
    task automatic check(
        input string rw,
        input logic [23:0] src,
        input logic [23:0] exp
    );
        checks++;
        if (src !== exp) begin
            errors++;
            $error("[%0t] %-30s got=%6h exp=%6h", $time, rw, src, exp);
        end
    endtask

    localparam int T = 100; // 10MHz
    logic [15:0] ref_mem [REG_N];   // Reference mem
    task automatic reset_dut();
        rst_n = 1'b0; ssn = 1'b1; sck = 1'b0; mosi = 1'b0;
        foreach (ref_mem[i]) ref_mem[i] = '0;
        #(T); rst_n = 1'b1; #(T);
    endtask

    localparam int T_SSN = 10;  // 10ns
    task automatic chip_select();
        ssn = 1'b0;
        #(T_SSN);   // Minimum leading time before the first SCK edge
    endtask

    localparam int T_SSH  = 10;  // 10ns
    localparam int T_IDLE = 10;  // 10ns
    task automatic chip_deselect();
        #(T_SSH);   // Minimum trailing time after the last SCK edge
        ssn = 1'b1;
        #(T_IDLE);  // Minimum ssn high time
    endtask

    // Drive MOSI and read MISO
    localparam int T_MOSI = 3;
    task automatic sck_tick(
        input  logic tx_bit,
        output logic rx_bit
    );
        #(T_MOSI);
        mosi = tx_bit;
        #(T/2 - T_MOSI);
        rx_bit = miso;
        sck = 1'b1;
        #(T/2);
        sck = 1'b0;
    endtask

    task automatic transfer_frame(
        input logic rw,    // 0=write, 1=read
        input logic [6:0]  addr,
        input logic [15:0] wdata
    );
        logic [23:0] tx, rx, exp;
        logic rx_bit;
        bit valid, data_valid = 1'b1;
        int addr_lo;

        tx = {rw, addr, wdata};
        rx = '0;
        for (int i = 23; i >=0; i--) begin
            valid = (rst_n === 1'b1) && (ssn === 1'b0);
            // Data is not valid once rst_n/ssn changed
            if (!valid) data_valid = 1'b0;
            sck_tick (tx[i], rx_bit);
            rx = {rx[22:0], rx_bit};
        end

        // Check and Sample
        // Write data to ref mem
        addr_lo = addr[2:0];
        if (data_valid) begin
            if (!rw) ref_mem[addr_lo] = wdata;
            exp = rw ? {8'h00, ref_mem[addr_lo]} : 24'h000_000;
            cg_frame.sample(rw, addr, wdata);
            check($sformatf("%s addr=%02h", rw ? "READ " : "WRITE", addr), rx, exp);
        end
    endtask

    task automatic write_data(
        input logic [6:0]  addr,
        input logic [15:0] data
    );
        chip_select();
        transfer_frame(1'b0, addr, data);
        chip_deselect();
    endtask

    task automatic read_data(
        input logic [6:0]  addr
    );
        chip_select();
        transfer_frame(1'b1, addr, '0);
        chip_deselect();
    endtask

    // Random transfer num, including back to back transfer
    task automatic random_transfer(input int n_ssn);
        reset_dut ();
        // n transfers
        repeat (n_ssn) begin
            int n_frame;
            n_frame = $urandom_range(1, 10);
            // improve the weight of single frame
            if ($urandom_range(0, 2) == 0) n_frame = 1;
            // transfer n_frame frames
            chip_select();
            repeat (n_frame) begin
                transfer_frame(
                    $urandom_range(0,1),
                    $urandom_range(0,127),
                    $urandom_range(0,65535)
                );
            end
            chip_deselect();
        end
    endtask

    // -------------------------------
    //  Test cases.
    // -------------------------------
    // Generate waveform
    task automatic t0_wave();
        reset_dut();
        // A single frame
        write_data(7'd3, 16'hABCD);
        // Back to back transfer
        chip_select();
        transfer_frame(1'b0, 7'd6, 16'h2FAE);
        transfer_frame(1'b1, 7'd6, '0);
        chip_deselect();
    endtask

    task automatic t1_reset_check();
        logic [6:0]  addr;
        logic [15:0] data;

        // 1. Check reset values
        reset_dut();
        for (int a = 0; a < REG_N; a++) read_data(a[6:0]);

        // 2. Combination of rst_n and ssn
        reset_dut();
        #(T_SSH);
        rst_n = 1'b0; ssn = 1'b0;
        addr = 1; data = 16'h1A2B;
        #(T_SSN);
        transfer_frame(1'b0, addr, data);
        transfer_frame(1'b1, addr, '0);

        #(T_SSH);
        rst_n = 1'b0; ssn = 1'b1;
        addr = 3; data = 16'h3C4D;
        #(T_SSN);
        transfer_frame(1'b0, addr, data);
        transfer_frame(1'b1, addr, '0);

        // BTW. Read/Write when ssn is high
        #(T_SSH);
        rst_n = 1'b1; ssn = 1'b1;
        addr = 5; data = 16'h5E6F;
        #(T_SSN);
        transfer_frame(1'b0, addr, data);
        transfer_frame(1'b1, addr, '0);

        // BTW. Write and read the same addr with back to back transfer
        #(T_SSH);
        rst_n = 1'b1; ssn = 1'b0;
        addr = 7; data = 16'h7C8A;
        #(T_SSN);
        transfer_frame(1'b0, addr, data);
        transfer_frame(1'b1, addr, '0);
        chip_deselect();
        
        // Check all regs
        for (int a = 0; a < REG_N; a++) read_data(a[6:0]);
    endtask

    task automatic t2_all_zeros_2_all_ones();
        reset_dut();
        for (int a =0; a < REG_N; a++) begin
            write_data(a, 16'h0000);
            read_data(a);
            write_data(a, 16'hFFFF);
            read_data(a);
            write_data(a, 16'h0000);
            read_data(a);
        end
    endtask

    task automatic t3_abort_transmission(input int n);
        repeat (n) begin
            reset_dut();
            // Fullfill non-zero values
            for (int a = 0; a < REG_N; a++) write_data(a[6:0], 16'hABCD);

            chip_select();
            fork
                begin   // rst_n
                    if ($urandom_range(0,1)) begin  
                        #($urandom_range(1, 230) * T/10 + T/4);
                        rst_n = 1'b0;
                    end
                end
                begin   // ssn
                    if ($urandom_range(0,1)) begin  
                        #($urandom_range(1, 230) * T/10 + T/4);
                        ssn = 1'b1;
                    end
                end
            join_none
            transfer_frame($urandom_range(0,1), $urandom_range(0,127), $urandom_range(0,65535));
            wait fork;
            chip_deselect();

            // Check regs
            if (!rst_n) foreach (ref_mem[i]) ref_mem[i] = '0;
            rst_n = 1'b1;
            for (int a = 0; a < REG_N; a++) read_data(a[6:0]);
        end
    endtask

    // -------------------------------
    //  Start.
    // -------------------------------
    initial begin
        string test;
        cg_frame = new();
        if (!$value$plusargs("TEST=%s", test)) test = "all";
        case (test)
            "wave" : t0_wave();
            "t1"   : t1_reset_check();
            "t2"   : t2_all_zeros_2_all_ones();
            "t3"   : t3_abort_transmission(50);
            "rnd"  : random_transfer(500);
            default: begin
                reset_dut();
                t1_reset_check();
                t2_all_zeros_2_all_ones();
                t3_abort_transmission(50);
                random_transfer(500);
            end
        endcase

        $finish;
    end

    `ifdef FSDB_ON
        initial begin
            if ($test$plusargs("FSDB")) begin
                $fsdbDumpfile("wave.fsdb");
                $fsdbDumpvars(0, tb_spi_slave);
                $fsdbDumpMDA();
            end
        end
    `endif

    initial begin
        #200_000_000;
        $fatal(1, "Timeout");
    end

    final begin
        $display("");
        $display("  functional coverage = %0.2f %%", cg_frame.get_inst_coverage());
        $display("  checks = %0d   errors = %0d   %s", checks, errors, (errors == 0) ? "*** PASS ***" : "*** FAIL ***");
    end

endmodule
