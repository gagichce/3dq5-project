

# add waves to waveform
add wave Clock_50
add wave -decimal uut/resetn
add wave -divider {some label for my divider}
add wave uut/state
add wave uut/SRAM_we_n
add wave -decimal uut/SRAM_write_data
add wave -hexadecimal uut/SRAM_read_data
add wave -hexadecimal uut/SRAM_address
add wave -decimal uut/pixel_X_pos
add wave -decimal uut/pixel_Y_pos
