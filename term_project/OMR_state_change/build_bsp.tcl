if {[catch {
    set root [file normalize [lindex $argv 0]]
    set hw [file normalize [lindex $argv 1]]
    hsi::open_hw_design $hw
    hsi::create_sw_design omr_bsp -proc ps7_cortexa9_0 -os standalone
    hsi::add_library xilffs 4.1
    hsi::generate_bsp -dir $root
} message]} {
    puts stderr $message
    exit 1
}
exit 0
