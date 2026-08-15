# Usage
# restoreDesign ./data/cts.enc.dat spi_slave
# source script/clock_opt_opto.tcl

source script/setup.tcl
banner "STAGE 5 : POST-CTS OPTIMIZATION"

file mkdir ./reports/postcts

proc libcells {pat} {
    set r [dbGet head.libCells.name $pat]
    if {$r eq "0x0"} { return {} }
    return $r
}

# -------------------------------
#  Analysis
# -------------------------------

setExtractRCMode -engine preRoute
setAnalysisMode  -analysisType onChipVariation -cppr both
set_analysis_view -setup {view_slow} -hold {view_fast}

# -------------------------------
#  Opt
# -------------------------------

setOptMode -maxLocalDensity 0.75
set_db opt_max_density          0.75
set_db place_global_max_density 0.75

# -------------------------------
#  DELAY
# -------------------------------

set del_cells [libcells DEL*]
foreach c $del_cells { setDontUse $c false }

# -------------------------------
#  Hold Fix
# -------------------------------

set hold_cells [concat [libcells BUFFD*] $del_cells]

set_db opt_fix_hold_allow_setup_tns_degradation false

setOptMode -fixClockDrv               true \
           -fixFanoutLoad             true \
           -fixHoldAllowResizing      true \
           -fixHoldOnExcludedClockNets false \
           -holdFixingCells           $hold_cells \
           -holdTargetSlack           0.1 \
           -setupTargetSlack          0.05

# -------------------------------
#  PostCTS
# -------------------------------

optDesign -postCTS -setup -hold -prefix postCTS

# -------------------------------
#  DontUse CK
# -------------------------------

foreach c [concat [libcells CKBD*] [libcells CKND*]] { setDontUse $c true }

# -------------------------------
#  Report
# -------------------------------

report_ccopt_skew_groups -summary

timeDesign -postCTS -hold -pathreports -slackReports \
           -numPaths 50 -prefix postCTS_hold  -outDir ./reports/postcts/
timeDesign -postCTS -pathreports -drvReports -slackReports \
           -numPaths 50 -prefix postCTS_setup -outDir ./reports/postcts/
checkFPlan -reportUtil

saveDesign ./data/postcts.enc

banner "STAGE 5 COMPLETE"
echo "\n============================================================"
echo "  Next steps:"
echo "      1) Check ./reports/postcts"
echo "      2) source script/route.tcl"
echo "============================================================\n"
