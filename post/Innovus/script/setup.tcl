# Usage
# source script/setup.tcl

setMultiCpuUsage -localCpu 32

proc banner {msg} {
    puts ""
    puts "================================================="
    puts "  $msg"
    puts "  [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts "================================================="
    puts ""
}

# -------------------------------
#  PARA
# -------------------------------

set PRJ          "/home/yangh/project/SPI_Slave"
set DESIGN       "spi_slave"

set PNR          "$PRJ/post/Innovus"

set 180_MS_RF_G  "/home/yangh/project/PDK/180_MS_RF_G"
set TSMC         "/home/yangh/project/PDK/TSMCHOME/digital"
set FE           "$TSMC/Front_End"
set BE           "$TSMC/Back_End"

set STD_VER      "tcb018gbwp7t_270a"

# -------------------------------
#  LIB
# -------------------------------

set STD_CCS_DIR  "$FE/timing_power_noise/CCS/$STD_VER"

set LIB_WC       "$STD_CCS_DIR/tcb018gbwp7twc_ccs.lib"   ;# SS/125C/1.62V -> setup
set LIB_BC       "$STD_CCS_DIR/tcb018gbwp7tbc_ccs.lib"   ;# FF/0C/1.98V   -> hold

# -------------------------------
#  LEF
# -------------------------------

set TECH_LEF     "$180_MS_RF_G/APR_Tech/018G_6lm4X1U_40KUTM_7T_Cad/PR_tech/Cadence/LefHeader/tsmc018_6lm4X1U_40KAUTM_7T.tlef"
set STD_LEF      "$BE/lef/$STD_VER/lef/tcb018gbwp7t_6lm.lef"

set LEF_FILES    [list $TECH_LEF $STD_LEF]

# -------------------------------
#  QRC
# -------------------------------

set QRC_DIR      "$180_MS_RF_G/RC_Extraction/Cadence/RC_QRC_cm018g_1p6m_4x1u_mim5_40k_3corners_1.0a"
set QRC_MAX      "$QRC_DIR/RC_QRC_cm018g_1p6m_4x1u_mim5_40k_cworst/qrcTechFile"
set QRC_MIN      "$QRC_DIR/RC_QRC_cm018g_1p6m_4x1u_mim5_40k_cbest/qrcTechFile"

# -------------------------------
#  GDS out (chipfinish.tcl)
# -------------------------------

set STD_GDS      "$BE/gds/tcb018gbwp7t_270a/tcb018gbwp7t.gds"
set GDS_MAP      "$180_MS_RF_G/APR_Tech/018G_6lm4X1U_40KUTM_Syn/PR_tech/Synopsys/GdsOutMap/gdsout.map"

# -------------------------------
#  Input copied from DC/FM
# -------------------------------

set NETLIST      "$PNR/input/${DESIGN}_netlist.v"
set SDC_FILE     "$PRJ/constraints/spi_slave.sdc"   ;# shared with DC

# -------------------------------
#  Output
# -------------------------------

set DATA_DIR     "$PNR/data"
set RPT_DIR      "$PNR/reports"
set OUT_DIR      "$PNR/outputs"
foreach _d [list $DATA_DIR $RPT_DIR $OUT_DIR "$PNR/input"] { file mkdir $_d }

# -------------------------------
#  Power
# -------------------------------

set PWR_NET      "VDD"        ;# core 1.8V
set GND_NET      "VSS"        ;# core GND

# -------------------------------
#  Check
# -------------------------------

puts "\n================ setup.tcl : file check ================"
foreach f [list $SDC_FILE $NETLIST] {
    if {[file exists $f]} {
        puts "  \[  OK   \]  $f"
    } else {
        puts "  \[MISSING\]  $f"
    }
}
puts "=========================================================\n"
