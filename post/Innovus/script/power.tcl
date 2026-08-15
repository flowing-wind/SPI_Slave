# Usage
# restoreDesign ./data/fp.enc.dat spi_slave
# source script/power.tcl

source script/setup.tcl
banner "STAGE 2b : CORE POWER (VDD/VSS)"

# -------------------------------
#  Well Tap
# -------------------------------

addWellTap -cell TAPCELLBWP7T \
           -cellInterval 30 \
           -prefix WELLTAP \
           -checkerBoard

# -------------------------------
#  GlobalNetConnect
# -------------------------------

globalNetConnect $PWR_NET -type pgpin -pin $PWR_NET -inst * -verbose
globalNetConnect $GND_NET -type pgpin -pin $GND_NET -inst * -verbose

globalNetConnect $PWR_NET -type tiehi -inst * -verbose
globalNetConnect $GND_NET -type tielo -inst * -verbose

# -------------------------------
#  VIA
# -------------------------------

setAddRingMode   -stacked_via_top_layer METAL6 -stacked_via_bottom_layer METAL1
setAddStripeMode -stacked_via_top_layer METAL6 -stacked_via_bottom_layer METAL1

# -------------------------------
#  Core Power
# -------------------------------

addRing -nets [list $PWR_NET $GND_NET] \
        -type core_rings -follow core \
        -layer   {top METAL5 bottom METAL5 left METAL6 right METAL6} \
        -width   {top 2 bottom 2 left 3 right 3} \
        -spacing {top 1 bottom 1 left 3 right 3} \
        -offset  {top 1 bottom 1 left 1 right 1} \
        -threshold 1 -jog_distance 1

# -------------------------------
#  M6 Vertical Stripe
# -------------------------------

addStripe -nets [list $PWR_NET $GND_NET] \
          -layer METAL6 -direction vertical \
          -width 3 -spacing 3 \
          -set_to_set_distance 60 \
          -start_from left -start_offset 25 -stop_offset 25 \
          -switch_layer_over_obs false \
          -max_same_layer_jog_length 2

# -------------------------------
#  Special Route
# -------------------------------

sroute -connect {corePin floatingStripe} \
       -nets [list $PWR_NET $GND_NET] \
       -layerChangeRange       {METAL1 METAL6} \
       -crossoverViaLayerRange {METAL1 METAL6} \
       -targetViaLayerRange    {METAL1 METAL6} \
       -allowJogging 1 -allowLayerChange 1

# -------------------------------
#  Check
#    PG must be whole before placement starts
# -------------------------------

verifyConnectivity -type special -nets [list $PWR_NET $GND_NET] \
                   -error 1000 -warning 50

saveDesign ./data/power.enc

banner "STAGE 2b COMPLETE"
echo "\n============================================================"
echo "  Next step:"
echo "      source script/place_opt.tcl"
echo "============================================================\n"
