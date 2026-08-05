onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand /somadorfloat_vhd_tst/HEX0
add wave -noupdate -expand /somadorfloat_vhd_tst/HEX1
add wave -noupdate /somadorfloat_vhd_tst/HEX2
add wave -noupdate /somadorfloat_vhd_tst/HEX3
add wave -noupdate /somadorfloat_vhd_tst/HEX4
add wave -noupdate /somadorfloat_vhd_tst/HEX5
add wave -noupdate /somadorfloat_vhd_tst/KEY
add wave -noupdate -expand /somadorfloat_vhd_tst/LEDR
add wave -noupdate /somadorfloat_vhd_tst/SW
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 236
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {240 ns} {1187 ns}
