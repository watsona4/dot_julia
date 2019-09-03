
using Plots

Δ = .1
N = 100
τ = N*Δ/5
ran = 0.0:2pi/N:2pi
function fillxs(Ts = 1,N = 100, ini=0.0, fin=100)
    xs = []
    Δ = fin/N
    τ = N*Δ/5

    for j in 1:Ts
        for i in ini:Δ:τ-Δ
            push!(xs,1)
        end

        for i in τ:Δ:fin
            push!(xs,0)
        end

    end

    return xs
end

function Xforward(x,n)
    N = length(x)
    j = im
    b = 2pi/N
    sum = 0.0
    for k in 1:N
        sum += x[k] * exp(-j * k * b * n)
    end

    return abs(1/N * sum)
end

xs = Int.(fillxs())

ys =  [Xforward(xs,i) for i in 0:1:N]

scatter(xs, title = "Train signal")
scatter(ys, title = "DFT")

function xback(x,n)
    N = length(x)
    j = im
    b = 2pi/N
    sum = 0.0
    for k in 1:N
        sum += x[k] * exp(j * k * b * n)
    end

    return abs(sum)
end

ys2 = [xback(xs,i) for i in 0:1:N]

scatter(ys2, title = "DFT back")
