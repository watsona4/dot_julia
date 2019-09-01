module CoordinateGA

using ..GAFramework
import ..GAFramework: fitness, crossover, mutate, selection, randcreature, printfitness

export CoordinateModel, CoordinateCreature

"""
# E.g.
minimizes function
    model = CoordinateModel(x -> abs(x[1] - 20.0), -200.0, 200.0)
    state = GAState(model, ngen=500, npop=6_000, elite_fraction=0.1,
                       crossover_rate=0.9, mutation_rate=0.9,
                       print_fitness_iter=1)
    ga(state)

    type T has to have properties
        y-x :: T     
        0.25 .* (x+y) :: T
        randn(T) :: T
        z + 0.25*(y-x)*randn(T) :: T

"""
struct CoordinateModel{F,T} <: GAModel
    f::F
    xmin::T
    xmax::T
    xspan::T # xmax-xmin
    clamp::Bool
end
function CoordinateModel(f::F,xmin,xmax,clamp::Bool=true) where {F}
    xmin,xmax = promote(xmin,xmax)
    ET = eltype(xmin)
    N = length(xmin)
    xspan = xmax .- xmin
    # check that f(xmin), f(xmax) can be converted to Float64 without error
    z1 = Float64(f(xmin))
    z2 = Float64(f(xmax))
    # and that f(xspan), f(xmin), and f(xmax) has sane values maybe
    # z1!=Inf && z2!=Inf && !isnan(z1) && !isnan(z2) ||
    #    error("f(xmin) or f(xmax) objective function is either NaN or Inf")
    all(xspan .>= zero(ET)) || error("xmax[i] < xmin[i] for some i")
    CoordinateModel{F,typeof(xspan)}(f,xmin,xmax,xspan,clamp)
end

struct CoordinateCreature{T} <: GACreature
    value :: T
    objvalue :: Float64
end
CoordinateCreature(value::T, m::CoordinateModel{F,T}) where {F,T} =
    CoordinateCreature{T}(value, m.f(value))

fitness(x::CoordinateCreature{T}) where {T} = -x.objvalue

function randcreature(m::CoordinateModel{F,T}, aux, rng) where {F,T}
    xvalue = m.xmin .+ m.xspan .* rand(rng,length(m.xspan))
    CoordinateCreature(xvalue, m)
end

struct AverageCrossover end
function crossover(::AverageCrossover, z::CoordinateCreature{T},
                   x::CoordinateCreature{T}, y::CoordinateCreature{T},
                   m::CoordinateModel{F,T}, params, curgen::Integer,
                   aux, rng) where {F,T}
    z.value .= 0.5 .* (x.value .+ y.value)
    CoordinateCreature(z.value, m)
end

struct SinglePointCrossover end
function crossover(::SinglePointCrossover, z::CoordinateCreature{T},
                   x::CoordinateCreature{T}, y::CoordinateCreature{T},
                   m::CoordinateModel{F,T}, params, curgen::Integer,
                   aux, rng) where {F,T}
    N = length(x.value)
    i = rand(rng, 1:N)
    if rand(rng) < 0.5
        z.value[1:i] = x.value[1:i]
        z.value[i+1:end] = y.value[i+1:end]
    else
        z.value[1:i] = y.value[1:i]
        z.value[i+1:end] = x.value[i+1:end]
    end
    CoordinateCreature(z.value, m)
end

struct TwoPointCrossover end
function crossover(::TwoPointCrossover, z::CoordinateCreature{T},
                   x::CoordinateCreature{T}, y::CoordinateCreature{T},
                   m::CoordinateModel{F,T}, params, curgen::Integer,
                   aux, rng) where {F,T}
    N = length(x.value)
    i,j = rand(rng, 1:N, 2)
    i,j = i > j ? (j,i) : (i,j)
    if rand(rng) < 0.5
        z.value[:] = x.value
        z.value[i+1:j] = y.value[i+1:j]
    else
        z.value[:] = y.value
        z.value[i+1:j] = x.value[i+1:j]
    end
    CoordinateCreature(z.value, m)
end

function crossover(z::CoordinateCreature{T},
                   x::CoordinateCreature{T}, y::CoordinateCreature{T},
                   m::CoordinateModel{F,T}, params, curgen::Integer,
                   aux, rng) where {F,T}
    crossover(TwoPointCrossover(), z, x, y, m, nothing, curgen, aux, rng)
end

# Mutate over all dimensions
function mutatenormal(temp::Real, x::CoordinateCreature{T},
                      model::CoordinateModel{F,T}, rng) where {F,T}
    x.value .+= temp .* model.xspan .* randn(rng,length(x.value))
    model.clamp && (x.value .= clamp.(x.value, model.xmin, model.xmax))
    CoordinateCreature(x.value, model)
end

# Mutate through a single dimension
function mutatenormaldim(temp::Real, x::CoordinateCreature{T}, dim::Integer,
                         model::CoordinateModel{F,T}, rng) where {F,T}
    ET = eltype(T)
    x.value[dim] += temp * model.xspan[dim] * randn(rng,ET)
    model.clamp && (x.value[dim] = clamp(x.value[dim], model.xmin[dim], model.xmax[dim]))
    CoordinateCreature(x.value, model)
end

function mutate(x::CoordinateCreature{T}, model::CoordinateModel{F,T},
                params, curgen::Integer, aux, rng) where {F,T}
    if rand(rng) < params[:rate]
        if rand(rng) < get(params, :sa_rate, 0.0)
            sa(x,model,params[:k], params[:lambda],
               params[:maxiter], curgen, aux, rng)
        else
            N = length(x.value)
            mutatenormaldim(0.1, x, rand(1:N), model, rng)
        end
    else
        x
    end
end

export sa,satemp,saprob,mutatenormal
function sa(x::CoordinateCreature{T}, model::CoordinateModel{F,T},
            k::Real, lambda::Real, maxiter::Integer, curgen::Integer,
            aux, rng) where {F,T}
    N = length(x.value)
    y = x
    numnoups = 0 # number of consecutive
    #curgen = 0
    iter = curgen*maxiter + 0
    while true
        temp = satemp(iter, k, lambda) + numnoups/maxiter
        #temp = satemp(iter, k, lambda) + lambda * log(1+numnoups)
        dim = rand(rng,1:N)
        yvdim_old = y.value[dim]
        yov_old = y.objvalue
        fitness_old = fitness(y)
        y = mutatenormaldim(temp, y, dim, model, rng)
        diffe = fitness(y) - fitness_old
        if diffe >= 0
        elseif rand(rng) < saprob(diffe, temp)
        else
            y.value[dim] = yvdim_old
            y = CoordinateCreature(y.value, yov_old)
        end
        #println("temp: $temp newy: $(newy.objvalue) diffe: $diffe prob: $(saprob(diffe, temp))")
        #numnoups = ifelse(diffe > 0, 0, ifelse(diffe < 0, numnoups+1, numnoups))
        numnoups = ifelse(diffe > 0, 0, numnoups + 1)
        iter += 1
        iter > curgen*maxiter + maxiter && break
    end
    #println("pre: $(x.objvalue) post: $(y.objvalue)")
    y
end

satemp(iter::Integer, k::Real, lambda::Real) = k * exp(-lambda * iter)
# diff = newscore - oldscore
saprob(diff::Real, iter::Integer, k::Real, lambda::Real) =
    exp(diff / satemp(iter, k, lambda))
saprob(diff::Real, temp::Real) = exp(diff / temp)

selection(pop::Vector{<:CoordinateCreature{T}}, n::Integer, rng) where {T} =
    selection(TournamentSelection(2), pop, n, rng)

printfitness(curgen::Integer, x::CoordinateCreature{T}) where {T} =
    println("curgen: $curgen value: $(x.value) obj. value: $(x.objvalue)")

end # CoordinateGA
