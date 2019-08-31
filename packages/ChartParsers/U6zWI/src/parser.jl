abstract type AbstractStrategy end
struct BottomUp <: AbstractStrategy end
struct TopDown <: AbstractStrategy end

function initial_chart(tokens, grammar::AbstractGrammar, ::BottomUp)
    chart = Chart{rule_type(grammar), chart_key(grammar)}(length(tokens))
end

function initial_chart(tokens, grammar::AbstractGrammar{R}, ::TopDown) where {R}
    chart = Chart{R, chart_key(grammar)}(length(tokens))
    for arc in terminal_productions(grammar, tokens)
        push!(chart, PassiveArc(arc))
    end
    chart
end

struct Agenda{R, S <: SortedSet{ActiveArc{R}}}
    data::S
end

function Agenda{R}() where {R}
    s = SortedSet{ActiveArc{R}}(Base.Order.ReverseOrdering(Base.Order.By(arc -> (score(arc), objectid(arc)))))
    Agenda{R, typeof(s)}(s)
end
Base.push!(agenda::Agenda, arc::ActiveArc) = push!(agenda.data, arc)
Base.pop!(agenda::Agenda) = pop!(agenda.data)
Base.isempty(agenda::Agenda) = isempty(agenda.data)

function initial_agenda(tokens, grammar::AbstractGrammar{R}, ::BottomUp) where {R}
    agenda = Agenda{R}()
    for arc in terminal_productions(grammar, tokens)
        push!(agenda, ActiveArc(arc))
    end
    agenda
end

function initial_agenda(tokens, grammar::AbstractGrammar{R}, ::TopDown) where {R}
    agenda = Agenda{R}()
    for rule in productions(grammar)
        if lhs(rule) == start_symbol(grammar)
            push!(agenda, ActiveArc(Arc(0, 0, rule, [], score(rule))))
        end
    end
    agenda
end

struct PredictionCache{T}
    predictions::Set{Tuple{T, Int}}
end

PredictionCache{T}() where {T} = PredictionCache(Set{Tuple{T, Int}}())

"""
Returns `true` if the key was added, `false` otherwise.
"""
function maybe_push!(p::PredictionCache{T}, key::Tuple{T, Int}) where {T}
    # TODO: this can probably be done without two Set lookup operations
    if key in p.predictions
        return false
    else
        push!(p.predictions, key)
        return true
    end
end

struct ChartParser{R, G <: AbstractGrammar{R}, S <: AbstractStrategy, F}
    tokens::Vector{String}
    grammar::G
    strategy::S
    scoring_function::F
end

function ChartParser(tokens::AbstractVector{<:AbstractString},
            grammar::G,
            strategy::S=BottomUp(),
            scoring_function::F = arc -> 1.0) where {R, G <: AbstractGrammar{R}, S <: AbstractStrategy, F}
    ChartParser{R, G, S, F}(tokens, grammar, strategy, scoring_function)
end

struct ChartParserState{R, T}
    chart::Chart{R, T}
    agenda::Agenda{R}
    prediction_cache::PredictionCache{T}
end

function initial_state(parser::ChartParser{R}) where R
    chart = initial_chart(parser.tokens, parser.grammar, parser.strategy)
    agenda = initial_agenda(parser.tokens, parser.grammar, parser.strategy)
    prediction_cache = PredictionCache{chart_key(R)}()
    ChartParserState(chart, agenda, prediction_cache)
end

function Base.iterate(parser::ChartParser{R, T}, state=initial_state(parser)) where {R, T}
    while !isempty(state.agenda)
        candidate = pop!(state.agenda)
        if is_finished(candidate)
            arc = passive(candidate, parser.scoring_function)
            if score(arc) > 0
                update!(state, parser, arc)
                return (inner(arc), state)
            end
        else
            update!(state, parser, candidate)
        end
    end
    return nothing
end

Base.IteratorSize(::Type{<:ChartParser}) = Base.SizeUnknown()
Base.eltype(::Type{<:ChartParser{R}}) where {R} = Arc{R}

function is_complete(arc::Arc, parser::ChartParser)
    start(arc) == 0 && stop(arc) == length(parser.tokens) && head(arc) == start_symbol(parser.grammar)
end

is_complete(parser::ChartParser) = arc -> is_complete(arc, parser)

function update!(state::ChartParserState, parser::ChartParser, candidate::AbstractArc)
    push!(state.chart, candidate)
    for mate in mates(state.chart, candidate)
        push!(state.agenda, combine(candidate, mate))
    end
    predict!(state.agenda, state.chart, candidate, parser.grammar, state.prediction_cache, parser.strategy)
end

function predict!(agenda::Agenda, chart::Chart, candidate::ActiveArc,
                  grammar::AbstractGrammar{R}, prediction_cache::PredictionCache,
                  ::TopDown) where {R}
    is_new = maybe_push!(prediction_cache, (next_needed(candidate), stop(candidate)))
    if is_new
        for rule in productions(grammar)
            if lhs(rule) === next_needed(candidate)
                push!(agenda, ActiveArc(Arc(stop(candidate), stop(candidate), rule, Arc{R}[], score(rule))))
            end
        end
    end
end

function predict!(agenda::Agenda, chart::Chart, candidate::PassiveArc,
                  grammar::AbstractGrammar{R}, prediction_cache::PredictionCache,
                  ::TopDown) where {R}
    # Nothing to do here
end

function predict!(agenda::Agenda, chart::Chart, candidate::PassiveArc,
                  grammar::AbstractGrammar{R}, prediction_cache::PredictionCache,
                  ::BottomUp) where {R}
    is_new = maybe_push!(prediction_cache, (head(candidate), start(candidate)))
    if is_new
        for rule in productions(grammar)
            if first(rhs(rule)) === head(candidate)
                push!(agenda, ActiveArc(Arc(start(candidate), start(candidate), rule, Arc{R}[], score(rule))))
            end
        end
    end
end

function predict!(agenda::Agenda, chart::Chart, candidate::ActiveArc,
                  grammar::AbstractGrammar, prediction_cache::PredictionCache,
                  ::BottomUp)
    # Nothing to do here
end
