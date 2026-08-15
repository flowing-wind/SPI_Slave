# Usage  
#   cd /home/yangh/project/SPI_Slave/post/Innovus
#   innovus -log innovus
#   source script/init_design.tcl

source script/setup.tcl

banner "STAGE 1 : DESIGN IMPORT"

file mkdir ./data ./reports ./outputs

# -------------------------------
#  Import
# -------------------------------

source script/design.globals
init_design

banner "IMPORT DONE -- saving database"
saveDesign ./data/import.enc
# restoreDesign ./data/import.enc.dat spi_slave

banner "STAGE 1 COMPLETE"
echo "\n============================================================"
echo "  Next step:"
echo "      source script/floorplan.tcl"
echo "============================================================\n"
