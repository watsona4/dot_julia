using ODEInterfaceDiffEq, DiffEqProblemLibrary, DiffEqBase
using Test

using DiffEqProblemLibrary.ODEProblemLibrary: importodeproblems; importodeproblems()
import DiffEqProblemLibrary.ODEProblemLibrary: prob_ode_mm_linear

prob = prob_ode_mm_linear

@test_throws ErrorException solve(prob,dopri5(),dt=1//2^4)

@test_throws ErrorException solve(prob,dop853();dt=1//2^(4))

@test_throws ErrorException solve(prob,odex();dt=1//2^(4))

sol =solve(prob,seulex();dt=1//2^(4))

sol =solve(prob,radau();dt=1//2^(4))

sol =solve(prob,radau5();dt=1//2^(4))

sol =solve(prob,rodas();dt=1//2^(4))

@test_throws ErrorException solve(prob,ddeabm();dt=1//2^(4))

sol =solve(prob,ddebdf();dt=1//2^(4))
