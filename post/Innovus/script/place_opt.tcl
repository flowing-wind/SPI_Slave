# Usage
# restoreDesign ./data/power.enc.dat spi_slave
# source script/place_opt.tcl

source script/setup.tcl
banner "STAGE 3 : PLACE + preCTS OPT"

file mkdir ./reports/placeopt

# -------------------------------
#  Set Layer
# -------------------------------

setDesignMode -process 180
setDesignMode -bottomRoutingLayer METAL2
setDesignMode -topRoutingLayer    METAL5

# -------------------------------
#  Analysis
# -------------------------------

setAnalysisMode -analysisType onChipVariation -cppr both
set_analysis_view -setup {view_slow} -hold {view_fast}

# -------------------------------
#  Dont Use
#   *DEL*   delay
#   *FILL*  fill
#   *ANT*   antenna
#   CK*     clock
#   *TIE*   tiehi/tielo
#   G*      gacore7T site
# -------------------------------

foreach cell {*DEL* *FILL* *ANT* CK* *TIE* G*} {
    setDontUse $cell true
}

# -------------------------------
#  Opt
# -------------------------------

setOptMode -fixFanoutLoad true
setOptMode -maxLength 135   ;# ~half of width
setOptMode -maxLocalDensity 0.75

# No CTS for now
setOptMode -usefulSkew           false
setOptMode -usefulSkewPreCTS     false
setOptMode -usefulSkewCCOpt      none
set_db design_early_clock_flow   false

# -------------------------------
#  Place
# -------------------------------

setDesignMode -flowEffort standard
setPlaceMode  -place_global_cong_effort high
set_db place_global_max_density 0.75
set_db opt_max_density          0.76

setPlaceMode -place_global_clock_power_driven true
setPlaceMode -place_global_clock_power_driven_effort high

# -------------------------------
#  Tie
# -------------------------------

setTieHiLoMode -maxFanout 10
setTieHiLoMode -maxDistance 20

# -------------------------------
#  Group Path
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
#  Start
# -------------------------------

place_opt_design

# -------------------------------
#  Tie
# -------------------------------

setDontUse TIEHBWP7T false
setDontUse TIELBWP7T false
setTieHiLoMode -prefix TIE -cell {TIEHBWP7T TIELBWP7T}
addTieHiLo

# -------------------------------
#  Check
#    hold is meaningless before CTS (ideal clock) -> setup only
# -------------------------------

checkPlace

timeDesign -preCTS -pathreports -drvReports -slackReports \
           -numPaths 50 -prefix preCTS_setup -outDir ./reports/placeopt/

saveDesign ./data/place_opt.enc

banner "STAGE 3 COMPLETE"
echo "\n============================================================"
echo "  Next steps:"
echo "      1) Check ./reports/placeopt"
echo "      2) source script/clock_opt_cts.tcl"
echo "============================================================\n"
