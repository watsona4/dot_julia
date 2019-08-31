#=
bisect_right:
- Julia version: 1.0
- Author: qz
- Date: 2018-08-25
=#

using Test

using BisectPy: bisect_right

@test bisect_right([1, 2, 3, 4, 5], 3.5) == 4

@test bisect_right([1, 2, 3, 4, 5], 2) == 3

@test bisect_right([1, 2, 3, 3, 3, 5], 3) == 6