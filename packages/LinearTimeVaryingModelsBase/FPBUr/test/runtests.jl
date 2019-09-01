using LinearTimeVaryingModelsBase
using Test

# write your own tests here
t = Trajectory(randn(2,4), randn(2,4))
@test length(t) == 3
@test t.nx == t.nu == 2

for (x,u) in t
    println(x,u)
end
