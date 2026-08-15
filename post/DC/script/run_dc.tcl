# Usage
# dc_shell -f script/run_dc.tcl -output_log_file dc.log

set_app_var sh_enable_page_mode false

set_app_var sh_continue_on_error false

source script/pre_dc.tcl

source script/compile.tcl

source script/post_dc.tcl

exit
