# Push Button 4°³ (Active-Low)
set_property PACKAGE_PIN Y18  [get_ports {buttons_4bits_tri_i[0]}]
set_property PACKAGE_PIN AA18 [get_ports {buttons_4bits_tri_i[1]}]
set_property PACKAGE_PIN Y19  [get_ports {buttons_4bits_tri_i[2]}]
set_property PACKAGE_PIN AA19 [get_ports {buttons_4bits_tri_i[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {buttons_4bits_tri_i[*]}]

# Text LCD
set_property PACKAGE_PIN F19 [get_ports {lcd_rs}]
set_property PACKAGE_PIN H20 [get_ports {lcd_rw}]
set_property PACKAGE_PIN G19 [get_ports {lcd_en}]

set_property PACKAGE_PIN A22 [get_ports {lcd_data[7]}]
set_property PACKAGE_PIN D22 [get_ports {lcd_data[6]}]
set_property PACKAGE_PIN C22 [get_ports {lcd_data[5]}]
set_property PACKAGE_PIN E21 [get_ports {lcd_data[4]}]
set_property PACKAGE_PIN D21 [get_ports {lcd_data[3]}]
set_property PACKAGE_PIN B21 [get_ports {lcd_data[2]}]
set_property PACKAGE_PIN B22 [get_ports {lcd_data[1]}]
set_property PACKAGE_PIN H19 [get_ports {lcd_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {lcd_rs lcd_rw lcd_en lcd_data[*]}]