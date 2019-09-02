using MultivariateFunctions
using DataStructures: OrderedDict
using DataFrames

# Chebyshev approximation
func = sin
nodes  =  12
degree =  8
left   = -2.0
right  =  5.0
limits =  OrderedDict{Symbol,Tuple{Float64,Float64}}([:default] .=> [(left, right)])
approxim = create_chebyshev_approximation(func, nodes, degree, limits)
X = convert(Array{Float64,1}, left:0.01:right)
y = func.(X)
y_approx = evaluate.(Ref(approxim), X)
maximum(abs.(y .- y_approx)) < 0.01

func = exp
nodes  =  12
degree =  8
left   =  1.0
right  =  5.0
limits =  OrderedDict{Symbol,Tuple{Float64,Float64}}([:default] .=> [(left, right)])
approxim = create_chebyshev_approximation(func, nodes, degree, limits)
X = convert(Array{Float64,1}, left:0.01:right)
y = func.(X)
y_approx = evaluate.(Ref(approxim), X)
maximum(abs.(y .- y_approx)) < 0.01


function func1(a::Float64,b::Float64,c::Float64)
    return sin(a)* c + a * sqrt(b)
end
func = func1
nodes  =  8
degree =  4
function_takes_Dict = false
limits = OrderedDict{Symbol,Tuple{Float64,Float64}}([:a, :b, :c] .=> [(-2.0,0.5), (0.0,4.0), (5.0,11.0)])
approxim = create_chebyshev_approximation(func, nodes, degree, limits, function_takes_Dict)
st =  0.99
d = vcat(Iterators.product(convert(Array{Float64,1}, limits[:a][1]:st:limits[:a][2]),convert(Array{Float64,1}, limits[:b][1]:st:limits[:b][2]),convert(Array{Float64,1}, limits[:c][1]:st:limits[:c][2]))...)
dd = DataFrame()
dd[:a], dd[:b], dd[:c]  = vcat.(d...)
y = Array{Float64,1}(undef, size(dd)[1])
for i in 1:length(y)
    y[i] = func.(dd[i,:a], dd[i,:b], dd[i,:c])
end
y_approx = evaluate(approxim, dd)
maximum(abs.(y .- y_approx)) < 0.5
# This is commented out to avoid the extra dependency. It should be true though.
#using Distributions
#cor(y,y_approx) > 0.9999

function func2(dd::Dict{Symbol,Float64})
    return sin(dd[:a])* cos(dd[:c])/ ((1+dd[:b])^2) +  sqrt(1.0+dd[:b])
end
func = func2
nodes  =  24
degree =  9
function_takes_Dict = true
limits = OrderedDict{Symbol,Tuple{Float64,Float64}}([:a, :b, :c] .=> [(-2.0,1.0), (0.1,0.15), (5.0,11.0)])
approxim = create_chebyshev_approximation(func, nodes, degree, limits, function_takes_Dict)
st =  0.6
d = vcat(Iterators.product(convert(Array{Float64,1}, limits[:a][1]:st:limits[:a][2]),convert(Array{Float64,1}, limits[:b][1]:st:limits[:b][2]),convert(Array{Float64,1}, limits[:c][1]:st:limits[:c][2]))...)
dd = DataFrame()
dd[:a], dd[:b], dd[:c]  = vcat.(d...)
y = Array{Float64,1}(undef, size(dd)[1])
for i in 1:length(y)
    dic = Dict{Symbol,Float64}([:a,:b,:c] .=> [dd[i,:a], dd[i,:b], dd[i,:c]])
    y[i] = func(dic)
end
y_approx = evaluate(approxim, dd)
y .- y_approx
maximum(abs.(y .- y_approx)) < 0.001
#using Distributions
#cor(y,y_approx) > 0.999999
