abstract type AbstractGrammar{R} end

chart_key(g::AbstractGrammar{R}) where {R} = chart_key(R)
rule_type(g::AbstractGrammar{R}) where {R} = R

function productions end
function terminal_productions end
function start_symbol end

abstract type AbstractRule{R} end
chart_key(::Type{<:AbstractRule{R}}) where {R} = R

lhs(p::Pair) = first(p)
rhs(p::Pair) = last(p)

struct SimpleRule <: AbstractRule{Symbol}
    rule::Pair{Symbol, Vector{Symbol}}
end

rhs(r::SimpleRule) = rhs(r.rule)
lhs(r::SimpleRule) = lhs(r.rule)
score(r::SimpleRule) = 1.0

Base.convert(::Type{SimpleRule}, p::Pair{Symbol, Vector{Symbol}}) = SimpleRule(p)

struct SimpleGrammar <: AbstractGrammar{SimpleRule}
    productions::Vector{SimpleRule}
    categories::Dict{String, Vector{Symbol}}
    start::Symbol
end

productions(g::SimpleGrammar) = g.productions
start_symbol(g::SimpleGrammar) = g.start

function terminal_productions(g::SimpleGrammar, tokens::AbstractVector{<:AbstractString})
    R = rule_type(g)
    result = Arc{R}[]
    for (i, token) in enumerate(tokens)
        for category in get(g.categories, token, Symbol[])
            push!(result, Arc{R}(i - 1, i, category => Symbol[], Arc{R}[], 1.0))
        end
    end
    result
end

struct SimpleWeightedRule <: AbstractRule{Symbol}
    rule::Pair{Symbol, Vector{Symbol}}
    score::Float64
end

rhs(r::SimpleWeightedRule) = rhs(r.rule)
lhs(r::SimpleWeightedRule) = lhs(r.rule)
score(r::SimpleWeightedRule) = r.score

Base.convert(::Type{SimpleWeightedRule}, t::Tuple{Pair{Symbol, Vector{Symbol}}, Real}) = SimpleWeightedRule(t...)

struct SimpleWeightedGrammar <: AbstractGrammar{SimpleWeightedRule}
    productions::Vector{SimpleWeightedRule}
    categories::Dict{String, Vector{Pair{Symbol, Float64}}}
    start::Symbol
end

productions(g::SimpleWeightedGrammar) = g.productions
start_symbol(g::SimpleWeightedGrammar) = g.start

function terminal_productions(g::SimpleWeightedGrammar, tokens::AbstractVector{<:AbstractString})
    R = rule_type(g)
    result = Arc{R}[]
    for (i, token) in enumerate(tokens)
        for (category, weight) in get(g.categories, token, Symbol[])
            push!(result, Arc{R}(i - 1, i, SimpleWeightedRule(category => Symbol[], weight), Arc{R}[], weight))
        end
    end
    result
end

