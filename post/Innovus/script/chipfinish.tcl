# Usage
# restoreDesign ./data/route_opt.enc.dat spi_slave
# source script/chipfinish.tcl

source script/setup.tcl
banner "STAGE 8 : CHIP FINISH + EXPORT"

file mkdir ./reports/chipfinish

proc libcells {pat} {
    set r [dbGet head.libCells.name $pat]
    if {$r eq "0x0"} { return {} }
    return $r
}

# -------------------------------
#  Std Cell Filler
# -------------------------------

set fill_cells [lsort -decreasing [libcells FILL*BWP7T]]
puts "  filler cells : $fill_cells"

addFiller -cell $fill_cells -prefix FILLER -fitGap

# filler insertion can push small DRC -> patch route
ecoRoute -target

# -------------------------------
#  Verify
# -------------------------------

verifyConnectivity -type all -error 1000 -warning 50
verify_drc -limit 100
verifyProcessAntenna -report ./reports/chipfinish/antenna.rpt

checkFPlan -reportUtil

# -------------------------------
#  Final Timing
# -------------------------------

timeDesign -postRoute       -pathreports -drvReports -slackReports \
           -numPaths 50 -prefix final_setup -outDir ./reports/chipfinish/
timeDesign -postRoute -hold -pathreports -slackReports \
           -numPaths 50 -prefix final_hold  -outDir ./reports/chipfinish/

# -------------------------------
#  Export
#    - *_pr.v   : logical netlist, post-layout sim + LVS schematic source
#    - *_lvs.v  : + PG, for LVS
#    - .sdf     : post-layout sim
#    - .spef    : signoff STA
#    - .def     : record of placement/routing
#    - .gds     : import into Virtuoso, hand connect to the pad ring
# -------------------------------

saveNetlist $OUT_DIR/${DESIGN}_pr.v -excludeLeafCell

saveNetlist $OUT_DIR/${DESIGN}_lvs.v -excludeLeafCell -includePowerGround

write_sdf -min_view view_fast -max_view view_slow $OUT_DIR/${DESIGN}_minmax.sdf

setExtractRCMode -engine postRoute
extractRC
rcOut -spef $OUT_DIR/${DESIGN}.spef -rc_corner rc_cworst

defOut -floorplan -netlist -routing $OUT_DIR/${DESIGN}.def

streamOut $OUT_DIR/${DESIGN}.gds \
          -mapFile $GDS_MAP \
          -merge   $STD_GDS \
          -units 1000 -mode ALL

saveDesign ./data/chipfinish.enc

banner "STAGE 8 COMPLETE"
echo "\n============================================================"
echo "  Hand-off to Virtuoso:"
echo "      GDS     : $OUT_DIR/${DESIGN}.gds"
echo "      LVS     : $OUT_DIR/${DESIGN}_lvs.v"
echo "      Netlist : $OUT_DIR/${DESIGN}_pr.v"
echo "      SDF     : $OUT_DIR/${DESIGN}_minmax.sdf"
echo "      SPEF    : $OUT_DIR/${DESIGN}.spef"
echo "  Copy GDS to ../Virtuoso/input"
echo "  Copy lvs.v to ../Virtuoso/verify/lvs"
echo "============================================================\n"
