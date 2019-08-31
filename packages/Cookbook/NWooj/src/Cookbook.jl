
module Cookbook

using Distributed
using LightGraphs
using MacroTools

export Recipe, @Recipe
export make, prepare, prepare!

abstract type Recipe end

macro Recipe(name::Symbol, body::Expr)
    _Recipe_expr(name, body)
end

function _Recipe_expr(name::Symbol, body::Expr)

    @capture body begin parts__ end

    inputs = map(parts) do part
        @capture part inputs = begin x__ end
        x
    end |> x->filter(!(==(nothing)), x)
    length(inputs) == 1 || error("Missing inputs specification")

    outputs = map(parts) do part
        @capture part outputs = begin x__ end
        x
    end |> x->filter(!(==(nothing)), x)
    length(outputs) == 1 || error("Missing inputs specification")

    args_list = map(parts) do part
        @capture part args = begin x__ end
        x
    end |> x->filter(!(==(nothing)), x)

    inputs_type = _named_type(inputs[1])
    outputs_type = _named_type(outputs[1])

    make_block = parts[end]

    args = if length(args_list) > 0
        map(args_list[1]) do x
            @capture x (a_::T_,doc_)
            :($a::$T)
        end
    else
        :()
    end

    _name = name #:($(esc(name)))

    esc(quote
        struct $(_name) <: Recipe
            inputs::$(inputs_type)
            outputs::$(outputs_type)
            $(args...)
        end
        function Cookbook.make(
            args::$(_name),
            inputs::$(inputs_type),
            outputs::$(outputs_type),
        )
            $make_block
            nothing
        end
    end
   )
end


function _named_type(data)
    names = tuple( (map(data) do x
        @capture x (a_...,doc_) | (a_,doc_)
        a
    end)... )
    isvector = map(data) do x
        @capture x (a_...,doc_)
    end
    types = map(isvector) do x
        ifelse(x, Vector{String}, String)
    end
    :(
        NamedTuple{$(names),Tuple{$(types...),}}
    )
end

input_names(recipe::Type{T}) where T  = fieldtype(T, :inputs).names
output_names(recipe::Type{T}) where T  = fieldtype(T, :outputs).names
function arg_names(recipe::Type{T}) where T<:Recipe
    filter(collect(fieldnames(T))) do x
        !(x in (:inputs, :outputs, :stacktrace))
    end |> collect
end

function prepare(recipe::Type{T}; kwargs...) where T
    prepare(recipe, kwargs)
end

function prepare(recipe::Type{T}, kwargs) where T
    inputs_list = [ input=>kwargs[input] for input in input_names(T) ]
    outputs_list = [ output=>kwargs[output] for output in output_names(T) ]
    inputs_tuple = NamedTuple{
        tuple(map(x->x[1], inputs_list)...)
    }( 
        tuple(map(x->x[2], inputs_list)...)
    )
    outputs_tuple = NamedTuple{
        tuple(map(x->x[1], outputs_list)...)
    }( 
        tuple(map(x->x[2], outputs_list)...)
    )
    outputs_list = [ output=>kwargs[output] for output in output_names(T) ]
    args = [ kwargs[arg] for arg in arg_names(T) ]

    for (name,input) in pairs(inputs_tuple)
        if input isa Vector && isempty(input)
            @error "Empty inputs list" name input recipe
            error("Empty inputs list")
        end
    end

    T(inputs_tuple, outputs_tuple, args...)
end

function prepare!(recipes, recipe::Type{T}; kwargs...) where T<:Recipe
    r = prepare(recipe, kwargs)
    push!(recipes, r)
end

function make(recipe::Recipe)
    make(recipe, recipe.inputs, recipe.outputs)
end

function _print_item(io::IO, item::String; level = 1)
    for i in 1:level+1
        print(io, "  ")
    end
    println(io, item)
end

function _print_item(io::IO, items; level = 1)
    for item in items
        _print_item(io, item, level = level + 1)
    end
end

function Base.show(io::IO, dt::MIME"text/plain", x::Recipe)
    println(io, "Recipe for $(typeof(x))")
    println(io, "  Products:")
    for output in pairs(x.outputs)
        println(io, "  ")
        print(io, string( first(output) ,":\n"))
        _print_item(io, last(output))
    end
    println(io, "  Dependencies: ")
    for input in pairs(x.inputs)
        println(io, "  ")
        print(io, string( first(input) ,":\n"))
        _print_item(io, last(input))
    end
    for field in fieldnames(typeof(x))
        if !(field in (:outputs, :inputs, :stacktrace))
            println(io, "$(field) = $(getfield(x,field))")
        end
    end
    if :stacktrace in fieldnames(typeof(x)) && length(x.stacktrace)>5
        show(io, dt, x.stacktrace[1:end-5])
    end
    nothing
end

lastmodified(filename) = if isfile(filename)
    stat(filename).mtime
else
    Inf
end

is_stale(::Any; err = false) = true

function is_stale(recipe::Recipe, output::String, input::String)
    if !ispath(input)
        if ispath(output)
            @debug "Missing recipe input for extant output." recipe input
            false
        else
            @error "Missing recipe input." recipe input
            error("Missing input")
            true
        end
    elseif !ispath(output)
        @info "Recipe is stale due to missing output" recipe output
        true
    elseif lastmodified(output) < lastmodified(input)
        @info "Recipe is stale due to new input" recipe input
        true
    else
        false
    end
end

function is_stale(recipe::Recipe, output::String, input::Nothing)
    if !ispath(output)
        @info "Recipe is stale due to missing output" recipe output
        true
    else
        false
    end
end

function is_stale(recipe::Recipe, output::String, inputs)
    if isempty(inputs)
        @info "Recipe has no inputs" recipe
        is_stale(recipe, output, nothing)
    else
        mapreduce(|, inputs) do input
            is_stale(recipe, output, input)
        end
    end
end
function is_stale(recipe::Recipe, outputs, input::String)
    mapreduce(|, outputs) do output
        is_stale(recipe, output, input)
    end
end
function is_stale(recipe::Recipe, outputs, input)
    mapreduce(|, outputs) do output
        is_stale(recipe, output, input)
    end
end

function is_stale(recipe::Recipe; err=false)
    for output in recipe.outputs, input in recipe.inputs
        if is_stale(recipe, output, input)
            if err
                error("Recipe should not be stale")
            end
            return true
        end
    end
    false
end

function add_input!(graph, output2recipe, output_idx::Int, input)
    if input isa String
        if haskey(output2recipe, input)
            j = output2recipe[input]
            add_edge!(graph, output_idx, j)
        end
    else
        for input in input
            if haskey(output2recipe, input)
                j = output2recipe[input]
                add_edge!(graph, output_idx, j)
            end
        end
    end
    nothing
end

function make_graph(output2recipe, num_recipes, inputs)
    graph = SimpleDiGraph(num_recipes)
    outputs = collect(keys(output2recipe))
    for output in outputs
        i = output2recipe[output]
        for input in inputs[i]
            add_input!(graph, output2recipe, i::Int, input)
        end
    end
    graph
end


#returns recipes that are not already in order and for which all the inputs
#are already in `order`
function recipe_order(graph)
    order = []
    in_neighbors = map(x->inneighbors(graph,x), vertices(graph))
    out_neighbors = map(x->outneighbors(graph,x), vertices(graph))
    num_in_neighbors = map(x->length(in_neighbors[x]), vertices(graph))
    num_out_neighbors = map(x->length(out_neighbors[x]), vertices(graph))
    allocated = zeros(Bool, length(vertices(graph)))
    while !reduce( & , allocated )
        next = []
        new_allocated = zeros(Bool, length(vertices(graph)))
        for vertex in vertices(graph)
            if allocated[vertex]
                continue
            elseif num_out_neighbors[vertex] == 0 || reduce( & , allocated[out_neighbors[vertex]] )
                push!(next, vertex)
                new_allocated[vertex] = true
            end
        end
        allocated .|= new_allocated
        @assert length(next)>0
        append!(order, sort(
             next,
             by=x->(num_in_neighbors[x], -num_out_neighbors[x], -x),
             rev=true,
        ))
    end
    @assert reduce( & , allocated)
    @assert length(order) == length(vertices(graph))
    order
end


function map_outputs_to_recipes(recipes)
    output2recipe = Dict{String, Int}()
    for (v,recipe) in enumerate(recipes), output in recipe.outputs
        if output isa String
            if haskey(output2recipe, output)
                @error "An output is produced by multiple recipes." output recipeA = recipes[output2recipe[output]] recipeB=recipe
                error("An output is produced by multiple recipes.")
            end
            output2recipe[output] = v
        else
            for prod in output
                if haskey(output2recipe, prod)
                    error("The output $prod is produced by multiple recipes.")
                end
                output2recipe[prod] = v
            end
        end
    end
    output2recipe
end

function make(recipes::Vector; maximum_running = 1, distributed = false)
    @info "gather outputs"
    output2recipe = map_outputs_to_recipes(recipes)
    @info "make graph"
    inputs = [ recipe.inputs for recipe in recipes ]
    graph = make_graph(output2recipe, length(recipes), inputs)
    @info "check for circular inputs "
    if has_self_loops(graph)
        error("Circular inputs detected")
    end

    @info "ordering recipes"
    order = recipe_order(graph)

    tasks = Dict{Int,Task}()
    @info "Checking recipes"
    @sync for v in order 
        recipe = recipes[v]
       #if recipe isa Time_Averaged_RMSD
       #    @show recipe.outputs
       #end
        states = [t.state for t in values(tasks)]
        abort = false
        while !abort && sum(states .!= :done) >= maximum_running 
            yield()
            states = [t.state for t in values(tasks)]
            abort = reduce( | , states .== :failed )
        end
        if abort
            @error "Failure detected. Aborting."
            break
        end
        for n in outneighbors(graph, v)
            if haskey(tasks,n)
                wait(tasks[n])
            end
        end
        #@info "scheduling task" 
        tasks[v] = @async begin
            #@info "task starting"
            if is_stale(recipe)
                @info "Making recipe" recipe
                for output in recipe.outputs
                    if output isa String
                        mkpath(dirname(output))
                    else
                        for p in output
                            mkpath(dirname(p))
                        end
                    end
                end
                if distributed
                    fetch( @spawn make(recipe) )
                else
                    make(recipe)
                end
                @info "Made recipe" recipe
            end
            is_stale(recipe, err=true)
            #@info "Task ending"
        end
        states = [t.state for t in values(tasks)]
        if :failed in states
            @error "One or more recipes have errored."
            errored = true
            break
        end
    end
end

end
