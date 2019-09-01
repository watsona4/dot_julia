__precompile__()

module GAFramework

using JLD

export GAModel, GACreature, ga,
fitness, genauxga, crossover, mutate, selection, randcreature,
printfitness, savecreature,
GAState, loadgastate, savegastate,
RouletteWheelSelection, TournamentSelection

"""
To create a GA with a specific GACreature and GAModel, import this module,
make a GACreature and GAModel with the following interface functions:
    fitness (has default)
    genauxga  (has default)
    crossover (no default)
    mutate (has identity function as default)
    selection (has default)
    randcreature (no default)
    printfitness (has default)
    savecreature (has default)
 """
abstract type GACreature end
abstract type GAModel end

"""
Fitness function.
    fitness(x) is maximized always
    To minimize x.objvalue, dispatch fitness(x) to -x.objvalue for your Creature
    Recommended to make this either x.objvalue to maximize or -x.objvalue to minimize

    Since fitness(x) used for selecting the fittest creature, elites, and parents,
    all the computationally expensive part of calculating the fitness value should
    be implemented in the randcreature method.
"""
fitness(x::GACreature) = x.objvalue

"""
    genauxga(model::GAModel) :: GAModel auxiliary structure

    Given model GAM <: GAModel,
    generate auxiliary scratch space for calculating alignment scores
    model = GAM(G1,G2)
    aux = genauxga(model)
    """
genauxga(model::GAModel) = nothing

"""
    crossover(z::GACreature, x::GACreature,y::GACreature,model::GAModel, aux, rng) :: GACreature

    Crosses over x and y to create a child. Optionally use space in z as a
    scratch space or to create the child.
    aux is more scratch space. rng is random number generator.
    model = GAM(G1,G2)
    aux = genauxga(model)
    x = randcreature(model,aux)
    y = randcreature(model,aux)
    z = randcreature(model,aux)
    child = crossover(z,x,y,model,aux,rng)
"""
crossover(z::GACreature, x::GACreature, y::GACreature, model::GAModel, aux, rng) =
    error("crossover not implemented for $(typeof(z)) and $(typeof(model))")

"""
    Mutates a incoming creature and outputs mutated creature
"""
mutate(creature::GACreature, model::GAModel, aux, rng) = creature

"""
    selection(pop::Vector{<:GACreature}, n::Integer, rng)

    Generate a vector of n tuples (i,j) where i and j are
    indices into pop, and where pop[i] and pop[j] are the
    selected parents.
    Uses binary tournament selection by default. 
"""    
selection(pop::Vector{<:GACreature}, n::Integer, rng) =
    selection(TournamentSelection(2), pop, n, rng)

"""
    randcreature(model::GAModel, aux)

    Create a random instance of a GACreature, given a GAModel.
    There is always a GACreature associated with a GAModel    
    """    
randcreature(model::GAModel,aux,rng) =
    error("randcreature not implemented for $(typeof(model))")

"""
   Print fitness
"""        
printfitness(curgen::Integer, creature::GACreature) =
    println("curgen: $curgen fitness: $(creature.objvalue)")

"""
   Saves best fitness creature to file
"""
savecreature(file_name_prefix::AbstractString, curgen::Integer,
    creature::GACreature, model::GAModel) =
    save("$(file_name_prefix)_creature_$(curgen).jld", "creature", creature)

include("ga.jl")
include("selections.jl")

include("coordinatega.jl")

end
