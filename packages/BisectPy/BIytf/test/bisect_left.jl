#=
bisect_left:
- Julia version: 1.0
- Author: qz
- Date: 2018-08-26
=#

using Test

using BisectPy: bisect_left

@test bisect_left([1, 2, 3, 4, 5], 3.5) == 4

@test bisect_left([1, 2, 3, 4, 5], 2) == 2

@test bisect_left([1, 2, 3, 3, 3, 5], 3) == 3