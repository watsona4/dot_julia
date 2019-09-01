using Test
using SimpleRandom

A = random_subset(100)
@test length(A) <= 100
B = random_subset(Set(1:20),5)
@test length(B) == 5
A = random_subset(20,15)
@test length(A) == 15

wt = [ 1/2, 1/3, 1/6]
t = random_choice(wt)
@test 0 < t < 4

d = Dict{String, Float64}()
d["alpha"] = 0.5
d["gamma"] = 0.5
t = random_choice(d)
@test length(t) == 5

x = binom_rv(10)
@test 0 <= x <= 10
x = poisson_rv(.25)
@test x >= 0
x = exp_rv(1.2)
@test x >= 0

X = RV{Int, Rational{Int}}()
X[1] = 1//2
X[2] = 1//3
X[3] = 1//6
@test E(X) == 1//2 + 2//3 + 3//6
@test Var(X) ==  5//9
@test length(X)== 3
a = random_choice(X)
@test 0<a<4
@test sum(probs(X)) == 1
