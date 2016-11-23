

# add waves to waveform
add wave Clock_50
add wave -decimal uut/resetn
add wave -divider {some label for my divider}
add wave uut/state
add wave uut/SRAM_we_n
add wave -hexadecimal uut/SRAM_write_data
add wave -hexadecimal uut/SRAM_read_data
add wave -hexadecimal uut/SRAM_address

add wave -hexadecimal uut/U_N
add wave -hexadecimal uut/V_N

add wave -hexadecimal uut/Y_EVEN
add wave -hexadecimal uut/Y_ODD
add wave -hexadecimal uut/U_EVEN
add wave -hexadecimal uut/U_ODD
add wave -hexadecimal uut/V_EVEN
add wave -hexadecimal uut/V_ODD

#add wave -hexadecimal uut/mul0/result_calculation_long
#add wave -hexadecimal uut/mul1/result_calculation_long
#add wave -hexadecimal uut/mul2/result_calculation_long
add wave -hexadecimal uut/mul0_result
add wave -hexadecimal uut/mul1_result
add wave -hexadecimal uut/mul2_result

add wave -hexadecimal uut/U_multi_ODD
add wave -hexadecimal uut/V_multi_ODD
add wave -hexadecimal uut/U_multi_EVEN
add wave -hexadecimal uut/V_multi_EVEN

add wave -hexadecimal uut/R_result_EVEN
add wave -hexadecimal uut/G_result_EVEN
add wave -hexadecimal uut/B_result_EVEN
add wave -hexadecimal uut/R_result_ODD
add wave -hexadecimal uut/G_result_ODD
add wave -hexadecimal uut/B_result_ODD

add wave -hexadecimal uut/R_writable_odd
add wave -hexadecimal uut/G_writable_odd
add wave -hexadecimal uut/B_writable_odd

add wave -hexadecimal uut/R_writable_even
add wave -hexadecimal uut/G_writable_even
add wave -hexadecimal uut/B_writable_even