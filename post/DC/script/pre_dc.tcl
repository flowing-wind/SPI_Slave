set DESIGN_NAME "spi_slave"
set RTL_FILES   "spi_slave.v"
set SDC_FILE    "$PRJ/constraints/spi_slave.sdc"   ;# shared with Innovus, see mmmc.view

set WORK_DIR    "./work"
set OUT_DIR     "./outputs"
set RPT_DIR     "./reports"

foreach d [list $WORK_DIR $OUT_DIR $RPT_DIR] {
    file mkdir $d
}

define_design_lib WORK -path $WORK_DIR

set_svf $OUT_DIR/${DESIGN_NAME}.svf
saif_map -start

analyze -format verilog -library WORK $RTL_FILES
elaborate $DESIGN_NAME -library WORK

current_design $DESIGN_NAME
link

# Check
redirect -tee -file $RPT_DIR/check_design.rpt {check_design}

# Use "read_ddc outputs/spi_slave_pre.ddc" to recover
write -format ddc -hierarchy -output $OUT_DIR/${DESIGN_NAME}_pre.ddc

reset_design
source -echo -verbose $SDC_FILE

# DC-only: keep the clock net untouched, buffering belongs to CTS.
set_dont_touch_network [get_clocks sck]

redirect -tee -file $RPT_DIR/check_timing.rpt {check_timing}

echo "\n============================================================"
echo "  current_design = [get_object_name [current_design]]"
echo "  register_num   = [sizeof_collection [all_registers]]"
echo ""
echo "  Next steps:"
echo "      1) check reports"
echo "      2) source script/compile.tcl"
echo "============================================================\n"
echo ">>> pre_dc.tcl DONE\n"
