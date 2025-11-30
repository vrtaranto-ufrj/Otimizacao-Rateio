\ SCIP STATISTICS
\   Problem name     : model
\   Variables        : 15 (6 binary, 4 integer, 0 implicit integer, 5 continuous)
\   Constraints      : 22
Minimize
 Obj: +1 z
Subject to
 c1: +1 trade_amounts_positive_0 +1 trade_amounts_positive_1 = +0
 c2: +1 trade_amounts_negative_0 +1 trade_amounts_negative_1 = -4
 c3: +1 final_position_0 +1 final_position_1 = +1
 c4: +1 final_position_0 -1 trade_amounts_positive_0 -1 trade_amounts_negative_0 = +3
 c5: +1 final_position_1 -1 trade_amounts_positive_1 -1 trade_amounts_negative_1 = +2
 c6: +1 is_positive_dir_0 -1 min_piece_0 <= +0
 c7: +1 is_positive_dir_1 -1 min_piece_1 <= +0
 c8: +1 final_position_0 -5 min_piece_0 <= +0
 c9: +1 final_position_1 -4 min_piece_1 <= +0
 c10: +1 final_position_0 +5 min_piece_0 >= +0
 c11: +1 final_position_1 +4 min_piece_1 >= +0
 c12: +1 final_position_0 -2 min_piece_0 -5 is_positive_dir_0 >= -5
 c13: +1 final_position_1 -2 min_piece_1 -4 is_positive_dir_1 >= -4
 c14: +1 final_position_0 +7 min_piece_0 -5 is_positive_dir_0 <= +5
 c15: +1 final_position_1 +6 min_piece_1 -4 is_positive_dir_1 <= +4
 c16: +1 new_ratios_0 -1 final_position_0 = +0
 c17: +1 new_ratios_1 -1 final_position_1 = +0
 c18: +0.6 ratios_errors_0 -1 new_ratios_0 >= -0.6
 c19: +0.4 ratios_errors_1 -1 new_ratios_1 >= -0.4
 c20: +0.6 ratios_errors_0 +1 new_ratios_0 >= +0.6
 c21: +0.4 ratios_errors_1 +1 new_ratios_1 >= +0.4
 c22: +1 z -10000 ratios_errors_0 -10000 ratios_errors_1 >= +0
Bounds
 0 <= trade_amounts_positive_0 <= 0
 0 <= trade_amounts_positive_1 <= 0
 0 <= min_piece_0 <= 1
 0 <= min_piece_1 <= 1
 0 <= is_positive_dir_0 <= 1
 0 <= is_positive_dir_1 <= 1
 -4 <= trade_amounts_negative_0 <= 0
 -4 <= trade_amounts_negative_1 <= 0
 final_position_0 free
 final_position_1 free
Binaries
 trade_amounts_positive_0 trade_amounts_positive_1 min_piece_0 min_piece_1 is_positive_dir_0 is_positive_dir_1
Generals
 trade_amounts_negative_0 trade_amounts_negative_1 final_position_0 final_position_1
End
