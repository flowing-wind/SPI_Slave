# Usage
# restoreDesign ./data/import.enc.dat spi_slave
# source script/floorplan.tcl

source script/setup.tcl
banner "STAGE 2a : FLOORPLAN + PIN PLACEMENT"

# -------------------------------
#  Process
# -------------------------------

setDesignMode -process 180

# -------------------------------
#  FloorPlan
# -------------------------------

set DIE_W    294    ;# core 270 + 2 x 12 margin
set DIE_H    104    ;# core  80 + 2 x 12 margin
set MARGIN   12     ;# core-to-die margin, holds the power ring

floorPlan -site core7T -d $DIE_W $DIE_H $MARGIN $MARGIN $MARGIN $MARGIN

# -------------------------------
#  Pin Placement
# -------------------------------

setPinAssignMode -pinEditInBatch true

editPin -pin {rst_n sck ssn mosi miso_oen miso} \
        -edge 1 -layer METAL2 \
        -spreadType side -spreadDirection clockwise \
        -offsetStart 20 -offsetEnd 20 \
        -fixedPin

setPinAssignMode -pinEditInBatch false

saveDesign ./data/fp.enc

banner "STAGE 2a COMPLETE"
echo "\n============================================================"
echo "  Next step:"
echo "      source script/power.tcl"
echo "============================================================\n"
