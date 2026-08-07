onerror {resume}
quietly WaveActivateNextPane {} 0

# Portas da placa (via testbench) -- igual ao wave.do original
add wave -noupdate -expand /somadorfloat_vhd_tst/HEX0
add wave -noupdate -expand /somadorfloat_vhd_tst/HEX1
add wave -noupdate /somadorfloat_vhd_tst/HEX2
add wave -noupdate /somadorfloat_vhd_tst/HEX3
add wave -noupdate /somadorfloat_vhd_tst/HEX4
add wave -noupdate /somadorfloat_vhd_tst/HEX5
add wave -noupdate /somadorfloat_vhd_tst/KEY
add wave -noupdate -expand /somadorfloat_vhd_tst/LEDR
add wave -noupdate /somadorfloat_vhd_tst/SW

# Acumulador (sign_acc/exp_acc/frac_acc): estado gravado por KEY, confirma o resultado entre somas
add wave -noupdate -group {Acumulador} /somadorfloat_vhd_tst/i1/sign_acc
add wave -noupdate -group {Acumulador} -radix unsigned /somadorfloat_vhd_tst/i1/exp_acc
add wave -noupdate -group {Acumulador} -radix binary /somadorfloat_vhd_tst/i1/frac_acc

# Operando de entrada apos normalizacao (o que realmente entra no somador junto com o acumulador)
add wave -noupdate -group {Entrada normalizada} /somadorfloat_vhd_tst/i1/sign_in
add wave -noupdate -group {Entrada normalizada} -radix unsigned /somadorfloat_vhd_tst/i1/exp_in
add wave -noupdate -group {Entrada normalizada} -radix binary /somadorfloat_vhd_tst/i1/frac_in
add wave -noupdate -group {Entrada normalizada} -radix binary /somadorfloat_vhd_tst/i1/frac_in_raw
add wave -noupdate -group {Entrada normalizada} -radix unsigned /somadorfloat_vhd_tst/i1/lead0_in

# Resultado do somador antes de ser gravado no acumulador (sign_out/exp_out/frac_out)
add wave -noupdate -group {Resultado do somador} /somadorfloat_vhd_tst/i1/sign_out
add wave -noupdate -group {Resultado do somador} -radix unsigned /somadorfloat_vhd_tst/i1/exp_out
add wave -noupdate -group {Resultado do somador} -radix binary /somadorfloat_vhd_tst/i1/frac_out

# Estagios internos do nucleo (big/small/aligned/normalized, sum e lead0)
add wave -noupdate -group {Nucleo (estagios 1-4)} /somadorfloat_vhd_tst/i1/signb
add wave -noupdate -group {Nucleo (estagios 1-4)} /somadorfloat_vhd_tst/i1/signs
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix unsigned /somadorfloat_vhd_tst/i1/expb
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix unsigned /somadorfloat_vhd_tst/i1/exps
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix binary /somadorfloat_vhd_tst/i1/fracb
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix binary /somadorfloat_vhd_tst/i1/fracs
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix binary /somadorfloat_vhd_tst/i1/fraca
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix binary /somadorfloat_vhd_tst/i1/sum
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix unsigned /somadorfloat_vhd_tst/i1/lead0
add wave -noupdate -group {Nucleo (estagios 1-4)} -radix binary /somadorfloat_vhd_tst/i1/fracn

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
