struct RouletteWheelSelection end
# selection(pop::Vector{<:GACreature}, n::Integer, rng)
function selection(::RouletteWheelSelection,
                   pop::Vector{<:GACreature}, n::Integer, rng=Base.GLOBAL_RNG)    
    wmin,wmax = extrema(fitness(c) for c in pop)
    weight = wmax - wmin
    function stochasticpick()
        while true
            i = rand(rng,1:length(pop))
            if wmin + weight * rand(rng,typeof(weight)) <= fitness(pop[i])
                return i
            end
        end
    end
    parents = Vector{Tuple{Int,Int}}(undef, n)
    for k = 1:n
        i = stochasticpick()
        j = i
        while i==j
            j = stochasticpick()
        end
        parents[k] = (i,j)
    end
    parents
end

struct TournamentSelection
    k::Int # if k=2 then binary tournament selection
    TournamentSelection(k=2) = new(k)
end
function selection(sel::TournamentSelection,
                   pop::Vector{<:GACreature}, n::Integer, rng=Base.GLOBAL_RNG)    
    function stochasticpick()
        si = rand(rng,1:length(pop))
        weighti = fitness(pop[si])
        for _ = 1:sel.k-1
            sj = rand(rng,1:length(pop))
            weightj = fitness(pop[sj])
            if weightj > weighti
                si = sj
                weighti = weightj
            end
        end
        si
    end
    parents = Vector{Tuple{Int,Int}}(undef, n)
    for k = 1:n
        i = stochasticpick()
        j = i
        while i==j
            j = stochasticpick()
        end
        parents[k] = (i,j)
    end
    parents
end
