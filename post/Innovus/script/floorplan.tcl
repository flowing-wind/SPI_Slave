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

set DIE_W       294 ;# core 270 + 2 x 12 margin
set DIE_H       98  ;# core  80 + 2 x 9  margin
set MARGIN_lr   12  ;# left/right margin, holds the power ring
set MARGIN_bt   9   ;# bottom/top margin, holds the power ring

floorPlan -site core7T -d $DIE_W $DIE_H $MARGIN_lr $MARGIN_bt $MARGIN_lr $MARGIN_bt

# -------------------------------
#  Pin Placement
# -------------------------------

setPinAssignMode -pinEditInBatch true

editPin -pin {miso miso_oen mosi sck ssn rst_n} \
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
