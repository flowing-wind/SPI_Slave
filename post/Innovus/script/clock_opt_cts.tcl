# Usage
# restoreDesign ./data/place_opt.enc.dat spi_slave
# source script/clock_opt_cts.tcl

source script/setup.tcl
banner "STAGE 4 : CLOCK TREE SYNTHESIS"

file mkdir ./reports/cts

# -------------------------------
#  Helper
# -------------------------------

proc libcells {pat} {
    set r [dbGet head.libCells.name $pat]
    if {$r eq "0x0"} { return {} }
    return $r
}

# -------------------------------
#  Clock Cell
# -------------------------------

set cts_buf [libcells CKBD*]
# CKND2D* are clock NANDs, not inverters -> filter, or ccopt warns and drops them
set cts_inv [lsearch -all -inline -not -glob [libcells CKND*] CKND2D*]
puts "  CTS buffer   : [llength $cts_buf]"
puts "  CTS inverter : [llength $cts_inv]"

foreach c [concat $cts_buf $cts_inv] { setDontUse $c false }

# -------------------------------
#  CCOpt Target
# -------------------------------

# >= one inverter unit delay (0.26 here), or ccopt relaxes it anyway and warns
set_ccopt_property target_skew      0.30
set_ccopt_property target_max_trans 0.30
set_ccopt_property max_fanout       15

set_ccopt_property use_inverters                        true
set_ccopt_property inverter_cells                       $cts_inv
set_ccopt_property clustering_mix_inverters_and_buffers true

# -------------------------------
#  Useful Skew : off
# -------------------------------

setOptMode -usefulSkew      false
setOptMode -usefulSkewCCOpt none

# -------------------------------
#  NDR + Route Type
# -------------------------------

add_ndr -name ndr_2w2s \
        -width_multiplier   {METAL3:METAL5 2} \
        -spacing_multiplier {METAL3:METAL5 2} \
        -generate_via


create_route_type -name trunk_rule \
        -top_preferred_layer METAL5 -bottom_preferred_layer METAL4 \
        -preferred_routing_layer_effort medium \
        -non_default_rule ndr_2w2s



create_route_type -name leaf_rule \
        -top_preferred_layer METAL3 -bottom_preferred_layer METAL2 \
        -preferred_routing_layer_effort medium

set_ccopt_property route_type trunk_rule -net_type top
set_ccopt_property route_type trunk_rule -net_type trunk
set_ccopt_property route_type leaf_rule  -net_type leaf

# -------------------------------
#  Clock Tree Spec
# -------------------------------

create_ccopt_clock_tree_spec -file ./reports/cts/clock.spec
source ./reports/cts/clock.spec

# -------------------------------
#  CTS
# -------------------------------

ccopt_design -cts

refinePlace
checkPlace

# -------------------------------
#  Sanity Check
# -------------------------------

set n_ck 0
foreach c [dbGet top.insts.cell.name] { if {[string match CK* $c]} { incr n_ck } }
puts "  clock tree cells inserted : $n_ck"

# -------------------------------
#  Save
# -------------------------------

saveDesign ./data/cts.enc

# -------------------------------
#  Report
# -------------------------------

report_ccopt_skew_groups -summary

banner "STAGE 4 COMPLETE"
echo "\n============================================================"
echo "  Next step:"
echo "      source script/clock_opt_opto.tcl"
echo "============================================================\n"
