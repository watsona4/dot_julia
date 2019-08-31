
struct Chart{R, T}
    num_tokens::Int
    active::Dict{T, Vector{Vector{ActiveArc{R}}}} # organized by next needed constituent then by stop
    passive::Dict{T, Vector{Vector{PassiveArc{R}}}} # organized by head then by start
end

Chart{R, T}(num_tokens::Integer) where {R, T} =
    Chart(num_tokens, Dict{T, Vector{Vector{ActiveArc{R}}}}(),
                Dict{T, Vector{Vector{PassiveArc{R}}}}())

num_tokens(chart::Chart) = chart.num_tokens

function _active_storage(chart::Chart{R, T}, next_needed::T, stop::Integer) where {R, T}
    v = get!(chart.active, next_needed) do
        [Vector{ActiveArc{R}}() for _ in 0:num_tokens(chart)]
    end
    v[stop + 1]
end

function _passive_storage(chart::Chart{R, T}, head::T, start::Integer) where {R, T}
    v = get!(chart.passive, head) do
        [Vector{PassiveArc{R}}() for _ in 0:num_tokens(chart)]
    end
    v[start + 1]
end

storage(chart::Chart, arc::ActiveArc) = _active_storage(chart, next_needed(arc), stop(arc))
storage(chart::Chart, arc::PassiveArc) = _passive_storage(chart, head(arc), start(arc))

mates(chart::Chart, candidate::ActiveArc) = _passive_storage(chart, next_needed(candidate), stop(candidate))
mates(chart::Chart, candidate::PassiveArc) = _active_storage(chart, head(candidate), start(candidate))

function Base.push!(chart::Chart, arc::AbstractArc)
    push!(storage(chart, arc), arc)
end

Base.in(arc::AbstractArc, chart::Chart) = arc ∈ storage(chart, arc)

