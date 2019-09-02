using ODEInterfaceDiffEq, DiffEqProblemLibrary, DiffEqBase, Test
using DiffEqProblemLibrary.ODEProblemLibrary: importodeproblems; importodeproblems()
import DiffEqProblemLibrary.ODEProblemLibrary: prob_ode_linear,
                            prob_ode_2Dlinear, prob_ode_vanderpol

prob = prob_ode_linear
sol =solve(prob,dopri5(),dt=1//2^(4))

sol =solve(prob,dop853();dt=1//2^(4))

sol =solve(prob,odex();dt=1//2^(4))

sol =solve(prob,seulex();dt=1//2^(4))

sol =solve(prob,radau();dt=1//2^(4))

sol =solve(prob,radau5();dt=1//2^(4))

sol =solve(prob,rodas();dt=1//2^(4))

sol =solve(prob,ddeabm();dt=1//2^(4))

sol =solve(prob,ddebdf();dt=1//2^(4))

prob = prob_ode_2Dlinear

sol =solve(prob,dopri5(),dt=1//2^4)

sol =solve(prob,dop853();dt=1//2^(4))

sol =solve(prob,odex();dt=1//2^(4))

sol =solve(prob,seulex();dt=1//2^(4))

sol =solve(prob,radau();dt=1//2^(4))

sol =solve(prob,radau5();dt=1//2^(4))

sol =solve(prob,rodas();dt=1//2^(4))

sol =solve(prob,ddeabm();dt=1//2^(4))

sol =solve(prob,ddebdf();dt=1//2^(4))

prob = prob_ode_vanderpol

sol =solve(prob,dopri5(),dt=1//2^4)

sol =solve(prob,dop853();dt=1//2^(4))

sol =solve(prob,odex();dt=1//2^(4))

sol =solve(prob,seulex();dt=1//2^(4))

sol =solve(prob,radau();dt=1//2^(4))

sol =solve(prob,radau5();dt=1//2^(4))

sol =solve(prob,rodas();dt=1//2^(4))

sol =solve(prob,ddeabm();dt=1//2^(4))

sol =solve(prob,ddebdf();dt=1//2^(4))
