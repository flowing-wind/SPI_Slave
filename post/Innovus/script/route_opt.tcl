# Usage
# restoreDesign ./data/route.enc.dat spi_slave
# source script/route_opt.tcl

source script/setup.tcl
banner "STAGE 7 : POST-ROUTE OPTIMIZATION"

file mkdir ./reports/postroute

proc libcells {pat} {
    set r [dbGet head.libCells.name $pat]
    if {$r eq "0x0"} { return {} }
    return $r
}

# -------------------------------
#  Parasitics
#    routing changed everything -> re-extract with the real engine
# -------------------------------

setExtractRCMode -engine postRoute
reset_parasitics
extractRC

# -------------------------------
#  Analysis
# -------------------------------

setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -engine aae -siAware true
set_analysis_view -setup {view_slow} -hold {view_fast}

# -------------------------------
#  Density
# -------------------------------

setOptMode -maxLocalDensity 0.75
set_db opt_max_density          0.75
set_db place_global_max_density 0.75

# -------------------------------
#  Path Group
# -------------------------------

reset_path_group
resetPathGroupOptions
set inp    [all_inputs -no_clocks]
set outp   [all_outputs]
set allreg [all_registers]

group_path -name in2reg  -from $inp    -to $allreg
group_path -name reg2out -from $allreg -to $outp
group_path -name in2out  -from $inp    -to $outp      ;# ssn -> miso_oen
group_path -name reg2reg -from $allreg -to $allreg

# -------------------------------
#  Hold Fix
# -------------------------------

set hold_cells [concat [libcells BUFFD*] [libcells DEL*]]

set_db opt_fix_hold_allow_setup_tns_degradation false

setOptMode -fixClockDrv          true \
           -fixFanoutLoad        true \
           -fixHoldAllowResizing true \
           -holdFixingCells      $hold_cells \
           -holdTargetSlack      0.05 \
           -setupTargetSlack     0.00

# -------------------------------
#  Optimize
# -------------------------------

optDesign -postRoute -setup -hold -prefix postRoute

# -------------------------------
#  Save
# -------------------------------

saveDesign ./data/route_opt.enc

# -------------------------------
#  Report
# -------------------------------

timeDesign -postRoute       -pathreports -drvReports -slackReports \
           -numPaths 50 -prefix postRoute_setup -outDir ./reports/postroute/
timeDesign -postRoute -hold -pathreports -slackReports \
           -numPaths 50 -prefix postRoute_hold  -outDir ./reports/postroute/

checkFPlan -reportUtil
verify_connectivity
verify_drc -limit 100

# # -------------------------------
# #  EcoRoute
# # -------------------------------

# # Find net name
# verify_drc -limit 10 -report ./reports/postroute/drc.rpt

# # Block the place if needed
# createRouteBlk -name ecoblk1 -layer METALn -box {x1-w y1-h x2+w y2+h}

# # Del the net
# editDelete -net {netA}

# # EcoRoute
# ecoRoute

# # Verify
# verifyConnectivity -type all  
# verify_drc -limit 100

# # Report
# setExtractRCMode -engine postRoute
# reset_parasitics
# extractRC
# timeDesign -postRoute       -pathreports -numPaths 20 -prefix eco_setup -outDir ./reports/postroute/
# timeDesign -postRoute -hold -pathreports -numPaths 20 -prefix eco_hold  -outDir ./reports/postroute/
# saveDesign ./data/route_opt.enc

banner "STAGE 7 COMPLETE"
echo "\n============================================================"
echo "  Next steps:"
echo "      1) Check DRC and do ecoRoute if needed"
echo "      2) Check ./reports/postroute"
echo "      3) source script/chipfinish.tcl"
echo "============================================================\n"
