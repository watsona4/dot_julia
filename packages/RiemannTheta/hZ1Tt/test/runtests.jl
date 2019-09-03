using RiemannTheta
using Test, Random
using LinearAlgebra

######### some testing values

Ω1 = [ 1.690983006 + 0.9510565162im 1.5+0.363271264im ;
      1.5+0.363271264im 1.309016994+0.9510565162im ]
T1 = Matrix(cholesky(imag.(Ω1)).U)

Ω2 = -1/(2π * im) * [ 111.207 96.616 ; 96.616 83.943 ]
T2 = Matrix(cholesky(imag.(Ω2)).U)

Random.seed!(0)
tmp = 5*rand(10,10) .- 2.5
Ω3 = 5*rand(10,10) .- 2.5 + (tmp * tmp') * im
T3 = Matrix(cholesky(imag.(Ω3)).U)

derivs1 = [ rand(ComplexF64, 2) for i in 1:1 ]
derivs2 = [ rand(ComplexF64, 10) for i in 1:5 ]

ϵ1, ϵ2 = 1e-3, 1e-8

##########

include("internals.jl")
include("mainfuncs.jl")
