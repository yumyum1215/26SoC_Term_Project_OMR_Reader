set root [file dirname [file normalize [info script]]]
open_project [file join $root OMR_state_change.xpr]
set bd [get_files system.bd]
open_bd_design $bd
validate_bd_design
generate_target all $bd
make_wrapper -files $bd -top
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne {write_bitstream Complete!}} {
    error [get_property STATUS [get_runs impl_1]]
}

set impl_dir [get_property DIRECTORY [get_runs impl_1]]
set sdk_dir [file join $root OMR_state_change.sdk]
file mkdir $sdk_dir
file copy -force [file join $impl_dir system_wrapper.sysdef] [file join $sdk_dir system_wrapper.hdf]
close_project
