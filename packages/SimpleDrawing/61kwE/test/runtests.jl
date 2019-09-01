using Test, SimpleDrawing, Plots

@test non_colinear_check(im, 2im, 2im+1)
z = 1+im
@test !non_colinear_check(z,-z,2z)

@test isinf(find_center(im,2im,3im))
@test find_center(im,-1+0im,1+im) == 0.5 - 0.5im

y = [1;5;2;-1;3]
S = Spline(y,:open)
@test S(2)==5
S = Spline(y,:closed)
@test S(7)==5
