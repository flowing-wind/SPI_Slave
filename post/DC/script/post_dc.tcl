change_names -rules verilog -hierarchy

write -format verilog -hierarchy -output $OUT_DIR/${DESIGN_NAME}_netlist.v

write -format ddc     -hierarchy -output $OUT_DIR/${DESIGN_NAME}_post.ddc

write_sdc $OUT_DIR/${DESIGN_NAME}.sdc

write_sdf $OUT_DIR/${DESIGN_NAME}_dc.sdf

set_svf -off

# Summary report
redirect -file $RPT_DIR/summary.rpt {
    report_qor

    report_constraint -all_violators

    report_clock -skew -attributes

    report_area -hierarchy

    report_reference

    check_design
}

# Timing report
redirect -file $RPT_DIR/timing.rpt {

    report_timing -delay_type max -max_paths 20 -nworst 2 \
                  -transition_time -capacitance -nets -nosplit

    report_timing -delay_type min -max_paths 20 -nworst 2 -nosplit
}


echo "\n============================================================"
echo "  Netlist : $OUT_DIR/${DESIGN_NAME}_netlist.v"
echo "  SDC     : $OUT_DIR/${DESIGN_NAME}.sdc"
echo "  Report  : $RPT_DIR/summary.rpt"
echo "            $RPT_DIR/timing.rpt"
echo "============================================================\n"
echo ">>> post_dc.tcl DONE\n"
