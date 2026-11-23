set root [file dirname [file normalize [info script]]]
if {$argc > 1 || ($argc == 1 && [lindex $argv 0] ne "bars")} {
    error "Expected optional argument: bars"
}
set build_dir [file join $root [expr {$argc == 0 ? "build_upright" : "build_bars"}]]
create_project -force camera_tfttest $build_dir -part xc7z020clg484-1
add_files [list [file join $root camera_tfttest.v] \
    [file join $root camera_i2c.vhd] [file join $root camera_i2c_command.vhd] \
    [file join $root camera_i2c_rom.vhd]]
add_files -fileset constrs_1 [file join $root camera_tfttest.xdc]
set_property top camera_tfttest [current_fileset]
if {$argc > 0} {
    set_property generic SHOW_COLOR_BARS=1 [current_fileset]
}
update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
    error "Bitstream generation failed. See the run logs in $build_dir."
}
if {$argc == 0} {set output camera_tfttest.bit} else {set output tft_color_bars.bit}
file copy -force [file join [get_property DIRECTORY [get_runs impl_1]] camera_tfttest.bit] \
    [file join $root $output]
puts "Bitstream: [file join $root $output]"
