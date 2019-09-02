
abstract type AbstractMultipleGridSolutions <: AbstractGridSolution end

# not performant but easy to write (:
flattenGridSolutions(sols::Vararg{AbstractSingleGridSolutions}) = sols
flattenGridSolutions(sol::AbstractSingleGridSolutions, sols::Vararg{AbstractGridSolution}) =
    (sol, flattenGridSolutions(sols...)...)
flattenGridSolutions(sol::AbstractMultipleGridSolutions, sols::Vararg{AbstractGridSolution}) =
    (solutionsOf(sol)..., flattenGridSolutions(sols...)...)

struct SubSolutionHandler
    sols::Tuple{Vararg{AbstractSingleGridSolutions}}
    SubSolutionHandler(sols) = new(flattenGridSolutions(sols...))
end

@inline solutionsOf(ssh::SubSolutionHandler) = ssh.sols

function (s::SubSolutionHandler)(::Nothing, args...; missingIfNotFound::Bool=false, kwargs...)
    if missingIfNotFound
        missing
    else
        throw(GridSolutionError("Couldn't find entry in solution for args = $args."))
    end
end
# TODO: add issue to propagate missingIfNotFound to the Single Grid Solutions
(s::SubSolutionHandler)(num, args...; missingIfNotFound::Bool=false, kwargs...) =
    s[num](args...; kwargs...)

@inline Base.getindex(s::SubSolutionHandler, num) = solutionsOf(s)[num]

@inline Base.convert(::Type{SubSolutionHandler}, sols::Tuple) = SubSolutionHandler(sols)
@inline Base.iterate(ssh::SubSolutionHandler, args...) = iterate(solutionsOf(ssh), args...)
@inline Base.length(ssh::SubSolutionHandler) = length(solutionsOf(ssh))

struct CompositeGridSolution <: AbstractMultipleGridSolutions
    ssh::SubSolutionHandler
    tSpans::MultipleTimeSpans{true} # true => needs to be sorted
    function CompositeGridSolution(ssh::SubSolutionHandler, tSpans::MultipleTimeSpans)
        !issorted(tSpans) && throw(GridSolutionError("Please sort the grid solutions / time spans correctly."))
        new(ssh, tSpans)
    end
end
CompositeGridSolution(ssh::SubSolutionHandler) = begin
    CompositeGridSolution(ssh, convert(MultipleTimeSpans, map(tspan, ssh.sols)))
end
CompositeGridSolution(sols::Vararg{AbstractGridSolution}) =
    CompositeGridSolution(convert(SubSolutionHandler, sols))

# TODO: add issue on github
const ERROR_INDEXING_WITH_COLON = GridSolutionError("Indexing the nodes with `:` is not allowed for a CompositeGridSolution as there might be ambiguities. Please use something like 1:numberOfNodes instead.")
(csol::CompositeGridSolution)(t, ::Colon, args...; kwargs...) =
    throw(ERROR_INDEXING_WITH_COLON)

# map over each element in the time array
(csol::CompositeGridSolution)(t, n, args...; kwargs...) = begin
    csol.(t', n, args...; kwargs...) # note that the ' makes it an outer/product iteration
end
(csol::CompositeGridSolution)(t, n::Number, args...; kwargs...) = begin
    csol.(t, n, args...; kwargs...) # note that the ' makes it an outer/product iteration
end

# takes missingIfNotFound as a kw
# propagate the call to the correct subsolution
(csol::CompositeGridSolution)(t::Number, n::Number, args...; kwargs...) = begin
    # @show t, args
    # find the solution (number) to which the time t belongs to
    solutionNumber = findfirst(t, timeSpansOf(csol))
    # @show solutionNumber
    # call that solution via the SubSolutionHandler (to catch the case where no solutionNumber has been found)
    subSolutionHandlerOf(csol)(solutionNumber, t, n, args...; kwargs...)
end

@inline Base.iterate(csol::CompositeGridSolution, args...) = iterate(subSolutionHandlerOf(csol), args...)
@inline Base.length(csol::CompositeGridSolution) = length(subSolutionHandlerOf(csol))

@inline subSolutionHandlerOf(csol::CompositeGridSolution) = csol.ssh
@inline solutionsOf(csol::CompositeGridSolution) = csol |> subSolutionHandlerOf |> solutionsOf
@inline timeSpansOf(csol::CompositeGridSolution) = csol.tSpans

adjustIndex(n, removed::Tuple{}) = n
function adjustIndex(n, removed::Tuple{Vararg{Integer}})
    n1 = filter(x -> x ∉ removed, n)
    n2 = (s -> s - count(s .> removed)).(n1)
    return n2
end

insertMissingData(data::AbstractArray, n, removed::Tuple{}) = data
insertMissingData(data::AbstractArray{T,2}, n::AbstractArray, removed::Tuple{}) where {T<:AbstractFloat} = data
function insertMissingData(data::AbstractArray{T,2}, n::AbstractArray, removed::Tuple{Vararg{Integer}}) where {T<:AbstractFloat}
    len = size(data, 1)
    for (i, s) in enumerate(n)
        if s ∈ removed
            data = hcat(data[:,1:i-1], fill(NaN, len), data[:,i:end])
        end
    end
    data
end

@recipe function f(csol::CompositeGridSolution, n, sym::Symbol, args...; removedNodes = (), tres = PLOT_TTIME_RESOLUTION)
    if removedNodes == ()
        removedNodes = Tuple(() for sol in csol)
    end
    # ensure the type of removedNodes to be tuples of tuples of integers in order to avoid incomprehensible errors later on
    removedNodes = removedNodes::Tuple{Vararg{Tuple{Vararg{Integer}}}}
    if length(unique( length.(Nodes.(csol)) .+ length.(removedNodes) )) != 1
        throw(PowerDynamicsPlottingError("Please ensure that nodes, that you have removed in one of the sub grids of the `CompositeGridSolution` are mentioned in `removedNodes`."))
    end
    adjusted_ns = adjustIndex.(Ref(n), removedNodes)
    adjusted_ns = adjusted_ns::Tuple
    data = getPlottingData.(csol, adjusted_ns, Ref(sym), args...; tres = tres)
    t = vcat(getindex.(data, 1)...)
    plotDataArray = getindex.(data, 2)
    plotDataArrayWithMissing = insertMissingData.(
        plotDataArray,
        Ref(n),
        removedNodes
    )
    plot_data = vcat(plotDataArrayWithMissing...)
    label --> tslabel.(sym, n)
    xlabel --> "t"
    t, plot_data
end
