# Usage
# restoreDesign ./data/postcts.enc.dat spi_slave
# source script/route.tcl

source script/setup.tcl
banner "STAGE 6 : ROUTING"

file mkdir ./reports/route

# -------------------------------
#  GlobalNetConnect
# -------------------------------

globalNetConnect $PWR_NET -type pgpin -pin $PWR_NET -inst *
globalNetConnect $GND_NET -type pgpin -pin $GND_NET -inst *
globalNetConnect $PWR_NET -type tiehi -inst *
globalNetConnect $GND_NET -type tielo -inst *

# -------------------------------
#  Antenna Diode
# -------------------------------

setDontUse ANTENNABWP7T false
setNanoRouteMode -routeAntennaCellName   ANTENNABWP7T
setNanoRouteMode -routeInsertAntennaDiode true

# -------------------------------
#  Density
# -------------------------------

setOptMode -maxLocalDensity 0.75
set_db opt_max_density          0.75
set_db place_global_max_density 0.75

# -------------------------------
#  Delay Calc
# -------------------------------

set_db delaycal_enable_si                  true
set_db delaycal_equivalent_waveform_model  propagation
set_db delaycal_equivalent_waveform_type   simulation

# -------------------------------
#  NanoRoute
# -------------------------------

setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven     true

set_db route_design_adjust_auto_via_weight          true
set_db route_design_detail_use_multi_cut_via_effort low
set_db route_design_detail_post_route_spread_wire   true

# -------------------------------
#  Route
# -------------------------------

routeDesign -globalDetail

# -------------------------------
#  Save
# -------------------------------

saveDesign ./data/route.enc

# -------------------------------
#  Physical Verify
# -------------------------------

checkFPlan -reportUtil
verifyConnectivity -type all -error 1000 -warning 50
verifyGeometry -report ./reports/route/geom.rpt

banner "STAGE 6 COMPLETE"
echo "\n============================================================"
echo "  Next step:"
echo "      source script/route_opt.tcl"
echo "============================================================\n"
