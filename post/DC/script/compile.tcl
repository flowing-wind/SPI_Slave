# No ICG
set_clock_gating_style -sequential_cell none

echo ">>> compiling ..."
compile_ultra -no_autoungroup

echo "\n============================================================"
echo "  Next step:"
echo "      source script/post_dc.tcl"
echo "============================================================\n"
echo ">>> compile done.\n"
