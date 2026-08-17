# ============================================================================
#  spi_slave.sdc
#
#  Shared core-only constraints, single source of truth.
#    DC      : sourced by post/DC/script/pre_dc.tcl, which adds
#              set_dont_touch_network (DC-only, keeps clock net for CTS)
#    Innovus : referenced by script/mmmc.view; clocks switch to propagated
#              after CTS (see clock_opt_cts.tcl)
# ============================================================================

# -------------------------------
#  PARA
# -------------------------------

set CLK_PERIOD  100.0                           ;# 10 MHz
set CLK_HIGH    [expr {0.60 * $CLK_PERIOD}]     ;# worst duty cycle 60%
set CLK_LOW     [expr {$CLK_PERIOD - $CLK_HIGH}]

# how late mosi may settle after the master's falling edge
# (master Tco_max + board, as seen at the core port)
set EXT_DLY     [expr {0.5 * $CLK_LOW}]         ;# 3.0

# -------------------------------
#  CLOCK
# -------------------------------

create_clock -name sck -period $CLK_PERIOD \
    -waveform [list 0 $CLK_HIGH] [get_ports sck]

set_clock_uncertainty -setup 1.0 [get_clocks sck]   ;# ~10% T
set_clock_uncertainty -hold  0.2 [get_clocks sck]

set_clock_transition 0.3 [get_clocks sck]

# -------------------------------
#  Input path
# -------------------------------

set_input_transition 0.3 [get_ports {sck mosi ssn rst_n}]

# mosi is launched by the master on the FALLING edge
set_input_delay -clock sck -clock_fall -max $EXT_DLY [get_ports mosi]
set_input_delay -clock sck -clock_fall -min 0        [get_ports mosi]

# ssn/rst_n recovery/removal
set_input_delay -clock sck -max 0 [get_ports {ssn rst_n}]
set_input_delay -clock sck -min 0 [get_ports {ssn rst_n}]

# -------------------------------
#  Output path
# -------------------------------

set_output_delay -clock sck -max $EXT_DLY [get_ports {miso miso_oen}]
set_output_delay -clock sck -min 0        [get_ports {miso miso_oen}]

set_load 0.1 [get_ports {miso miso_oen}]

# -------------------------------
#  DRV
# -------------------------------

set_max_transition  2.0 [current_design]
set_max_capacitance 2.0 [current_design]
set_max_fanout      20  [current_design]
