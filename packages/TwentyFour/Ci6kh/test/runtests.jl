using Test
using TwentyFour

@test solve(5,5,3,1) == "No solution"
x = solve(5,5,2,1)
@test eval(Meta.parse(x)) == 24
