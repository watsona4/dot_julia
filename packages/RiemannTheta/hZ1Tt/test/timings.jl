using BenchmarkTools
using RiemannTheta
using Distances

######### some testing values

Ω1 = [ 1.690983006 + 0.9510565162im 1.5+0.363271264im ;
      1.5+0.363271264im 1.309016994+0.9510565162im ]
T1 = Matrix(cholesky(imag.(Ω1)))

Ω2 = -1/(2π * im) * [ 111.207 96.616 ; 96.616 83.943 ]
T2 = Matrix(cholesky(imag.(Ω2)))

srand(0)
tmp = 5*rand(10,10) - 2.5
Ω3 = 5*rand(10,10) - 2.5 + (tmp * tmp') * im
T3 = Matrix(cholesky(imag.(Ω3)))

derivs1 = [ rand(ComplexF64, 2) for i in 1:1 ]
derivs2 = [ rand(ComplexF64, 10) for i in 1:5 ]

ϵ1, ϵ2 = 1e-3, 1e-8

############## lll_reduce.jl  ###############

############## radius.jl  ###############

@btime radius($ϵ1, $T1) # 3.2 μs
@btime radius($ϵ1, $T1, $derivs1) # 95 μs
@btime radius($ϵ2, $T3) # 540 μs
@btime radius($ϵ2, $T3, $derivs2) # 770 μs

############## innerpoints.jl  ###############

R = radius(ϵ1, T1)
@btime innerpoints(T1, R) # 4.6 μs

R = radius(ϵ2, T3)
@btime innerpoints(T3, R) # 770 μs


##########   riemanntheta function     ###########

zs1 = [ComplexF64[0.5, 0.]]
@btime riemanntheta(zs1, Ω1, eps=ϵ1) # 50.512 μs (269 allocations: 24.03 KiB)
@btime riemanntheta(zs1, Ω1, eps=ϵ2) # 58.536 μs (390 allocations: 35.91 KiB)

R = RiemannTheta.radius(ϵ1, Matrix(cholesky(imag.(Ω1))), Vector{ComplexF64}[], 5.)
RiemannTheta.innerpoints(Matrix(cholesky(imag.(Ω1))), R)
R = RiemannTheta.radius(ϵ2, Matrix(cholesky(imag.(Ω1))), Vector{ComplexF64}[], 5.)
RiemannTheta.innerpoints(Matrix(cholesky(imag.(Ω1))), R)


zs2 = [ ComplexF64[x, 2x] for x in -1:0.01:1 ]
@btime riemanntheta(zs2, Ω1, eps=ϵ1) # 608.379 μs (1097 allocations: 487.64 KiB)
@btime riemanntheta(zs2, Ω1, eps=ϵ2) # 930.824 μs (1122 allocations: 793.72 KiB)

@btime riemanntheta(zs2, Ω1, eps=ϵ1, derivs=derivs1) # 3.149 ms (61344 allocations: 3.45 MiB)
@btime riemanntheta(zs2, Ω1, eps=ϵ2, derivs=derivs1) # 4.760 ms (96737 allocations: 5.42 MiB)


srand(0)
zs3 = [ rand(ComplexF64, 10) for i in 1:20 ]
@btime riemanntheta(zs3, Ω3, eps=ϵ1) # 1.095 ms (8566 allocations: 852.06 KiB)
@btime riemanntheta(zs3, Ω3, eps=ϵ2) # 1.921 ms (12017 allocations: 1.08 MiB)

R = RiemannTheta.radius(ϵ1, Matrix(cholesky(imag.(Ω3))), Vector{ComplexF64}[], 5.)
RiemannTheta.innerpoints(Matrix(cholesky(imag.(Ω3))), R)
R = RiemannTheta.radius(ϵ2, Matrix(cholesky(imag.(Ω3))), Vector{ComplexF64}[], 5.)
RiemannTheta.innerpoints(Matrix(cholesky(imag.(Ω3))), R)



@btime riemanntheta(zs3, Ω3, eps=ϵ1, derivs=derivs2) # 97.773 ms (1004788 allocations: 112.40 MiB)
@btime riemanntheta(zs3, Ω3, eps=ϵ2, derivs=derivs2) # 200.701 ms (2147103 allocations: 240.10 MiB)


# comparable to openRT timings ?
# openRT at 90 ms
srand(0)
zs4 = [ ComplexF64[Complex(rand(),0.), Complex(rand(),0.)] for i in 1:10000 ]
Ω4 = [ 3im 0. ; 0. 2im ]
@btime riemanntheta(zs4, Ω4, eps=1e-8) #  22.784 ms (20724 allocations: 20.02 MiB)



Profile.clear()
@profile for i in 1:100 ; riemanntheta(zs3, Ω3, eps=ϵ1) ; end
Profile.print(format=:flat)



Count File                        Line Function
36 ...Theta\src\finite_sum.jl   124 finite_sum(::Array{Float64,2}, ::Ar...
 1 ...Theta\src\finite_sum.jl   141 finite_sum_small(::Array{Float64,2}...
 1 ...Theta\src\finite_sum.jl   142 finite_sum_small(::Array{Float64,2}...
25 ...Theta\src\finite_sum.jl   149 finite_sum_small(::Array{Float64,2}...
 2 ...Theta\src\finite_sum.jl   150 finite_sum_small(::Array{Float64,2}...
 2 ...Theta\src\finite_sum.jl   152 finite_sum_small(::Array{Float64,2}...
 2 ...Theta\src\finite_sum.jl   153 finite_sum_small(::Array{Float64,2}...
 2 ...Theta\src\finite_sum.jl   154 finite_sum_small(::Array{Float64,2}...
 1 ...Theta\src\finite_sum.jl   156 finite_sum_small(::Array{Float64,2}...

 1 ...heta\src\innerpoints.jl    25 (::RiemannTheta.#_innerpoints#8{Arr...
12 ...heta\src\innerpoints.jl    26 (::RiemannTheta.#_innerpoints#8{Arr...
 9 ...heta\src\innerpoints.jl    32 (::RiemannTheta.#_innerpoints#8{Arr...
102 ...heta\src\innerpoints.jl    34 (::RiemannTheta.#_innerpoints#8{Arr...
 8 ...heta\src\innerpoints.jl    19 innerpoints(::Array{Float64,2}, ::F...
22 ...heta\src\innerpoints.jl    41 innerpoints(::Array{Float64,2}, ::F...

 1 ...RiemannTheta\src\lll.jl    52 lll(::Array{Array{Float64,1},1})
18 ...RiemannTheta\src\lll.jl    53 lll(::Array{Array{Float64,1},1})
 2 ...RiemannTheta\src\lll.jl    54 lll(::Array{Array{Float64,1},1})
33 ...RiemannTheta\src\lll.jl    55 lll(::Array{Array{Float64,1},1})
 1 ...RiemannTheta\src\lll.jl    59 lll(::Array{Array{Float64,1},1})
 1 ...RiemannTheta\src\lll.jl    60 lll(::Array{Array{Float64,1},1})
 1 ...RiemannTheta\src\lll.jl    65 lll(::Array{Array{Float64,1},1})
 1 ...RiemannTheta\src\lll.jl    68 lll(::Array{Array{Float64,1},1})
 1 ...RiemannTheta\src\lll.jl    69 lll(::Array{Array{Float64,1},1})
 1 ...RiemannTheta\src\lll.jl    70 lll(::Array{Array{Float64,1},1})
 3 ...RiemannTheta\src\lll.jl    34 (::RiemannTheta.#☼#1{Array{Array{...
 8 ...RiemannTheta\src\lll.jl    36 (::RiemannTheta.#☼#1{Array{Array{...
36 ...RiemannTheta\src\lll.jl    37 (::RiemannTheta.#☼#1{Array{Array{...
 2 ...RiemannTheta\src\lll.jl    38 (::RiemannTheta.#☼#1{Array{Array{...

 1 ...iemannTheta\src\main.jl   113 #25
 1 ...iemannTheta\src\main.jl    76 #oscillatory_part#23(::Float64, ::A...
60 ...iemannTheta\src\main.jl    80 #oscillatory_part#23(::Float64, ::A...
30 ...iemannTheta\src\main.jl    81 #oscillatory_part#23(::Float64, ::A...
36 ...iemannTheta\src\main.jl    83 #oscillatory_part#23(::Float64, ::A...
 3 ...iemannTheta\src\main.jl   148 #riemanntheta#28(::Float64, ::Array...
229 ...iemannTheta\src\main.jl   149 #riemanntheta#28(::Float64, ::Array...
 4 ...iemannTheta\src\main.jl   152 #riemanntheta#28(::Float64, ::Array...
 2 ...iemannTheta\src\main.jl   110 exponential_part(::Array{Array{Comp...
 1 ...iemannTheta\src\main.jl   113 exponential_part(::Array{Array{Comp...

60 ...mannTheta\src\radius.jl    69 radius(::Float64, ::Array{Float64,2...


###############################################################################


######### optim   ###########
