# Usage
# fm_shell -f script/run_fm.tcl | tee fm.log

# -------------------------------
#  PARA
# -------------------------------

set PRJ         "/home/yangh/project/SPI_Slave"
set DESIGN_NAME "spi_slave"

set RTL_FILES   [list $PRJ/rtl/spi_slave.v]

set NETLIST     $PRJ/post/DC/outputs/${DESIGN_NAME}_netlist.v
set SVF_FILE    $PRJ/post/DC/outputs/${DESIGN_NAME}.svf

set TSMC        "/home/yangh/project/PDK/TSMCHOME/digital/Front_End/timing_power_noise/NLDM"
set LIB_FILES   [list $TSMC/tcb018gbwp7t_270a/tcb018gbwp7twc.db]

set RPT_DIR     "./reports"
file mkdir $RPT_DIR

set_app_var synopsys_auto_setup true
set_app_var verification_failing_point_limit 200

# -------------------------------
#  Read SVF
# -------------------------------

set_svf $SVF_FILE

# -------------------------------
#  Read DB
# -------------------------------

read_db $LIB_FILES

# -------------------------------
#  Reference
# -------------------------------

read_verilog -container r -libname WORK -05 $RTL_FILES
set_top r:/WORK/$DESIGN_NAME

# -------------------------------
#  Implementation
# -------------------------------

read_verilog -container i -libname WORK -05 $NETLIST
set_top i:/WORK/$DESIGN_NAME

# -------------------------------
#  Match
# -------------------------------

match
redirect -tee $RPT_DIR/fm_unmatched.rpt { report_unmatched_points }

# -------------------------------
#  Verify
# -------------------------------

set PASS [verify]

# -------------------------------
#  Report
# -------------------------------

if { $PASS } {
    puts "\n\n================================================="
    puts "   FORMALITY: VERIFICATION SUCCEEDED"
    puts "=================================================\n"
} else {
    puts "\n\n*************************************************"
    puts "   FORMALITY: VERIFICATION FAILED  --  see reports"
    puts "*************************************************\n"

    redirect -tee $RPT_DIR/fm_failing.rpt  { report_failing_points }
    redirect -tee $RPT_DIR/fm_aborted.rpt  { report_aborted_points }
    redirect      $RPT_DIR/fm_analyze.rpt  { analyze_points -all }

    save_session -replace $RPT_DIR/fm_fail.fss
}

exit
