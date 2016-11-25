

# add waves to waveform
add wave Clock_50
add wave -decimal uut/resetn
add wave -divider {some label for my divider}
add wave uut/state
add wave uut/SRAM_we_n
add wave -hexadecimal uut/SRAM_write_data
add wave -hexadecimal uut/SRAM_read_data
add wave -decimal uut/SRAM_address

add wave uut/DPRAM_wen
add wave -hexadecimal uut/DPRAM_write_data
add wave -decimal uut/DPRAM_write_address
add wave -hexadecimal uut/DPRAM_read_address
add wave -decimal uut/DPRAM_read_data


#add wave -hexadecimal uut/data_counter
#add wave -hexadecimal uut/start_row
#add wave -hexadecimal uut/end_row

#add wave -hexadecimal uut/U_N
#add wave -hexadecimal uut/V_N
#
#add wave -hexadecimal uut/Y_EVEN
#add wave -hexadecimal uut/Y_ODD
#add wave -hexadecimal uut/U_EVEN
#add wave -hexadecimal uut/U_ODD
#add wave -hexadecimal uut/V_EVEN
#add wave -hexadecimal uut/V_ODD

#add wave -hexadecimal uut/mul0/result_calculation_long
#add wave -hexadecimal uut/mul1/result_calculation_long
#add wave -hexadecimal uut/mul2/result_calculation_long
#add wave -hexadecimal uut/mul0_result
#add wave -hexadecimal uut/mul1_result
#add wave -hexadecimal uut/mul2_result

#add wave -hexadecimal uut/U_multi_ODD
#add wave -hexadecimal uut/V_multi_ODD
#add wave -hexadecimal uut/U_multi_EVEN
#add wave -hexadecimal uut/V_multi_EVEN

#add wave -hexadecimal uut/R_result_EVEN
#add wave -hexadecimal uut/G_result_EVEN
#add wave -hexadecimal uut/B_result_EVEN
#add wave -hexadecimal uut/R_result_ODD
#add wave -hexadecimal uut/G_result_ODD
#add wave -hexadecimal uut/B_result_ODD

#add wave -hexadecimal uut/R_writable_odd
#add wave -hexadecimal uut/G_writable_odd
#add wave -hexadecimal uut/B_writable_odd

#add wave -hexadecimal uut/R_writable_even
#add wave -hexadecimal uut/G_writable_even
#add wave -hexadecimal uut/B_writable_even