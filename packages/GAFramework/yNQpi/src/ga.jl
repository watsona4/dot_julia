using Random
import Future
import Base.Threads: @threads
#macro threads(ex) :($(esc(ex))) end 

"""
   function to create a population for GAState or ga
"""
function initializepop(model::GAModel,npop::Integer,
                       nelites::Integer, baserng=Random.GLOBAL_RNG, sortpop=true)
    # each thread gets its own auxiliary scratch space
    # and each thread gets its own random number generator
    nthreads = Threads.nthreads()
    rngs = accumulate(Future.randjump, fill(big(10)^20, nthreads), init=baserng)
    aux = map(i -> genauxga(model), 1:nthreads)
    if npop > 0
        # initialize population
        pop1 = randcreature(model,aux[1],rngs[1])
        pop = Vector{typeof(pop1)}(undef, npop)
        pop[1] = pop1
        @threads for i = 2:npop
            threadid = Threads.threadid()
            pop[i] = randcreature(model, aux[threadid], rngs[threadid])
        end
        if sortpop
            sort!(pop,by=fitness,rev=true,
                  alg=PartialQuickSort(max(1,nelites)))
        end
    else
        pop = nothing
    end
    return pop,aux,rngs
end

# this holds the full state of the genetic algorithm
# so that it can be stored to file
mutable struct GAState
    model::GAModel
    # vector of the population
    pop::Vector
    # number of generations
    ngen::Int
    # current generation
    curgen::Int
    # size of the population
    npop::Int
    # fraction of population that goes to the next generation regardless
    elite_fraction::Real
    # parameters for crossover function
    crossover_params
    # parameters for mutate function
    mutation_params
    # print the fitness of fittest creature every n iteration
    print_fitness_iter::Int
    # save the fittest creature to file every n iteration
    save_creature_iter::Int
    # save the entire state of the GA (i.e. this struct) to file every n iteration
    save_state_iter::Int
    # prefix for the files to be save
    file_name_prefix::AbstractString
    # random number generator for replication purposes
    baserng::AbstractRNG
end
function GAState(model::GAModel;
                 ngen=10,
                 npop=100,
                 elite_fraction=0.01,
                 crossover_params=nothing,
                 mutation_params=Dict(:rate=>0.1),
                 print_fitness_iter=1,
                 save_creature_iter=0,
                 save_state_iter=0,
                 file_name_prefix="gamodel",
                 baserng=Random.GLOBAL_RNG)
    0 <= elite_fraction <= 1 || error("elite_fraction bounds")
    nelites = Int(floor(elite_fraction*npop))
    pop,aux,rngs = initializepop(model, npop, nelites, baserng)
    return GAState(model,pop,ngen,0,npop,
                   elite_fraction,
                   crossover_params,
                   mutation_params,
                   print_fitness_iter,
                   save_creature_iter,
                   save_state_iter,
                   file_name_prefix,
                   baserng)
end

"""
       Saves ga state to file
       Doesn't support GAModels or GACreatures containing functions (e.g. CoordinateModel)
       since JLD doesn't support saving functions
"""       
function savegastate(file_name_prefix::AbstractString, curgen::Integer, state::GAState)
    filename = "$(file_name_prefix)_state_$(curgen).jld"
    println("Saving state to file $filename")
    save(filename,"state",state)
end

function loadgastate(filename::AbstractString)
    println("Load state from file $filename")
    load(filename, "state")
end

"""
    ga function
    x in each generation, the following is done
        - select parents from all creatures in population
        - create children using crossover
        - replace non-elites in population with children
        - mutate all creatures (both elites and children) in population
        - logging
            x saves state every save_state_iter iterations to file
                - restart using state = loadgastate(filename) & ga(state)
            x outputs creature every save_creature_iter iterations to file
            x prints fitness value every print_fitness_iter iterations to screen
        - go to next generation
            """
function ga(state::GAState)
    # load from state
    model = state.model
    pop = state.pop
    ngen = state.ngen
    curgen = state.curgen
    npop = state.npop
    elite_fraction = state.elite_fraction
    crossover_params = state.crossover_params
    mutation_params = state.mutation_params
    print_fitness_iter = state.print_fitness_iter
    save_creature_iter = state.save_creature_iter
    save_state_iter = state.save_state_iter
    file_name_prefix = state.file_name_prefix
    baserng = state.baserng

    nelites = Int(floor(elite_fraction*npop))
    nchildren = npop-nelites
    children = deepcopy(pop[nelites+1:end])
    # initialize auxiliary space
    _,aux,rngs = initializepop(model, 0, 0, baserng)

    println("Running genetic algorithm with
            population size $npop,
            generation number $ngen,
            elite fraction $elite_fraction,
            children created $nchildren,
            crossover_params $(repr(crossover_params)),
            mutation_params $(repr(mutation_params)),
            printing fitness every $print_fitness_iter iteration(s),
            saving creature to file every $save_state_iter iteration(s),
            saving state every $save_state_iter iteration(s),
            with file name prefix $file_name_prefix.")

    # main loop:
    # 1. select parents
    # 2. crossover parents & create children
    # 4. replace non-elites in current generation with children
    # 3. mutate population
    # 5. sort population
    for outer curgen = curgen+1:ngen
        # crossover. uses multi-threading when available
        parents = selection(pop, nchildren, rngs[1])
        @threads for i = 1:nchildren
            threadid = Threads.threadid()
            p1,p2 = parents[i]
            children[i] = crossover(children[i], pop[p1], pop[p2],
                                    model, crossover_params, curgen,
                                    aux[threadid], rngs[threadid])
        end
        # moves children and elites to current pop
        for i = 1:nchildren
            ip = nelites+i
            # swapping instead of deepcopy-ing
            pop[ip], children[i] = children[i], pop[ip]
        end
        # mutate pop (including elites; except for the most elite creature
        # in order to preserve monotonocity wrt best fitness)
        @threads for i = 2:npop
            threadid = Threads.threadid()
            pop[i] = mutate(pop[i], model, mutation_params, curgen,
                            aux[threadid], rngs[threadid])
        end
        sort!(pop,by=fitness,rev=true,alg=PartialQuickSort(max(1,nelites)))

        if print_fitness_iter>0 && mod(curgen,print_fitness_iter)==0
            printfitness(curgen, pop[1])
        end

        if save_creature_iter>0 && mod(curgen,save_creature_iter)==0
            savecreature(file_name_prefix, curgen, pop[1], model)
        end

        if save_state_iter>0 && mod(curgen,save_state_iter)==0
            state = GAState(model,pop,ngen,curgen,npop,
                            elite_fraction,
                            crossover_params,
                            mutation_params,
                            print_fitness_iter,
                            save_creature_iter,
                            save_state_iter,
                            file_name_prefix,
                            baserng)
            savegastate(file_name_prefix, curgen, state)
        end
    end
    state.curgen = curgen
    pop[1]
end
