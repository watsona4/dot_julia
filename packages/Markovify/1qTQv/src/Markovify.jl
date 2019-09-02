module Markovify

include("Tokenizer.jl")

export Model, walk, walk2, combine, makefromdict, state_with_beginning

"""
    Token{T} = Union{Symbol, T}

Tokens can be of any type. They can also include symbols `:begin` and `:end`
which are used to denote the beginning and end of a suptoken.
"""
Token{T} = Union{Symbol, T}

"""
    State{T} = Vector{Token{T}}

A state is described by a succession of tokens.
"""
State{T} = Vector{Token{T}}

"""
    TokenOccurences{T} = Dict{Token{T}, Int}

A dictionary pairing tokens (or special symbols `:begin` and `:end`) with
the number of their respective occurences.
"""
TokenOccurences{T} = Dict{Token{T}, Int}

"""
The datastructure of the Markov chain. Encodes all the different states
and the probabilities of going from one to another as a dictionary. The keys
are the states, the values are the respective
[`TokenOccurences`](@ref) dictionaries. Those are dictionaries which say
how many times was a token found *immediately* after the state.

# Fields
- `order` is the number of tokens in a [`State`](@ref)
- `nodes` is a dictionary pairing [`State`](@ref) and its respective
[`TokenOccurences`](@ref) dictionary.
"""
struct Model{T}
    order::Int
    nodes::Dict{State{T}, TokenOccurences{T}}
end

"""
    combine(chain, others)

Return a Model which is a combination of all of the models provided. All of the
arguments should have the same `order`. The nodes of all the Models are merged
using the function `merge`.
"""
function combine(chain, others...)
    return Model(chain.order, merge(chain.nodes, map(ch -> ch.nodes, others)...))
end

"""
    Model(nodes)

Return a model constructed from `nodes`. Can be used to reconstruct
a model object from its nodes, e.g. if the nodes were saved in a JSON file.
"""
function Model(nodes)
    if isempty(nodes) return nothing end
    # Pick some state and get its length; that's the order of the model
    order = length(nodes[first(keys(nodes))])
    return Model(order, nodes)
end

"""
    begseq(n)

Return the symbol `:begin` repeated `n` times. This array is then used
as a starting sequence for all suptokens.
"""
begseq(n) = fill(:begin, n)


"""
    stdweight(state, token)

A constant `1`. Used as a placeholder function in [`Model`](@ref) to represent
unbiased weight function.
"""
function stdweight(state, token)
    return 1
end

"""
    Model(suptokens::Vector{<:Vector{T}}; order=2, weight=stdweight)

Return a [`Model`](@ref) trained on an array of arrays of [`tokens`](@ref Token) (`suptokens`).
Optionally an `order` of the chain can be supplied; that is
the number of tokens in one state. A weight function of general
type `func(::State{T}, ::Token{T}) -> Int` can be supplied to be used
to bias the weights based on the state or token value.
"""
function Model(suptokens::Vector{<:Vector{T}}; order=2, weight=stdweight) where T
    nodes = Dict{State{T}, TokenOccurences{T}}()
    begin_sequence = begseq(order)
    for incomplete_tokens in suptokens
        # Tokens looks like: :begin :begin ... :begin token ... token :end
        # There will thus be a state consisting of only :begins
        # then a state with :begins and only one token etc.
        tokens = [begin_sequence; incomplete_tokens; [:end]]
        for i in 1:(length(tokens) - order)
            # Current state has a length=order
            state = tokens[i:i+order-1]
            # The token after the current state
            token = tokens[i+order]
            token_counts = get!(nodes, state, Dict{Token{T}, Int}())
            # Add a new occurence (possible with added weight)
            # of the token after the state
            token_counts[token] = get(token_counts, token, 0) + weight(state, token)
        end
    end
    return Model(order, nodes)
end

"""
    walk(model[, init_state])

Return an array of tokens obtained by a random walk through the Markov chain.
The walk starts at state `init_state` if supplied, and at state
`[:begin, :begin...]` (the length depends on
the order of the supplied `model`) otherwise. The walk ends once a special
token `:end` is reached.

See also: [`walk2`](@ref).
"""
function walk(model)
    return walker(model, begseq(model.order), [])
end

function walk(model, init_state)
    return walker(model, init_state, init_state)
end

"""
    states_with_suffix(model, init_suffix)

Return all of the states of `model` that end with `init_suffix`. If
the number of such states is 1 (or 0), the function shortens the suffix
(cuts the first token) in order to lower the requirements, and makes another try.
"""
function states_with_suffix(model, init_suffix)
    hassuffix(ar, suffix) = ar[end-length(suffix)+1:end] == suffix

    # If there is more than one state with given suffix, return the array of them
    # if not, cut the first token out of the suffix and try again
    function helper(suffix)
        states = [k for k in keys(model.nodes) if hassuffix(k, suffix)]
        # Either we got than one valid state (yay!)
        # or the suffix is already so short that we have to end
        if (length(states) > 1) || (length(suffix) <= 1)
            return states
        else
            # Shorten the suffix and try again
            return helper(suffix[2:end])
        end
    end

    return helper(init_suffix)
end

"""
    walk2(model[, init_state])

Return an array of tokens obtained by a random walk through the Markov chain.
When there is only one state following the current one (i.e. there is 100%
chance that the state will become the next one), the function shortens
the current `State` as to lower the requirements and obtain more randomness.
The `State` gets shortened until a state with at least two possible
successors is found (or until `State` is only one token long).

The walk starts at state `init_state` if supplied, and at state
`[:begin, :begin...]` (the length depends on the order of the supplied `model`)
otherwise. The walk ends once a special token `:end` is reached.

See also: [`walk`](@ref).
"""
function walk2(model)
    # First, do the normal append_token operation
    # Then choose all the states that are similar to the new state
    # but have more possible following tokens than only one
    # (or choose the new state itself if it is possibly followed by more than one token)
    # And then, chose a random state from this list
    newstate = rand ∘ (suf -> states_with_suffix(model, suf)) ∘ append_token
    return walker(model, begseq(model.order), [], newstate)
end

function walk2(model, init_state)
    # First, do the normal append_token operation
    # Then choose all the states that are similar to the new state
    # but have more possible following tokens than only one
    # (or choose the new state itself if it is possibly followed by more than one token
    # And then, chose a random state from this list
    newstate = rand ∘ (suf -> states_with_suffix(model, suf)) ∘ append_token
    return walker(model, init_state, init_state, newstate)
end

"""
    append_token(state, token)

Drop the first element in `state` and append
the `token` at the end of the `state` array.
"""
function append_token(state, token)
    return [state[2:end]; [token]]
end

"""
    walker(model, init_state, init_accum, newstate=append_token)

Return an array of tokens obtained by a random walk through the Markov chain.
The walk starts at state `init_state` and ends once a special token `:end`
is reached. A function `newstate` of general type
`func(::State{T}, ::Token{T})::State{T} where T` can be supplied
to be used to generate a new state given the old state and the following token.

This is a general function which is used by all the `walk` functions.

See also: [`walk`](@ref), [`walk2`](@ref).
"""
function walker(model, init_state, init_accum, newstate=append_token)
    function helper(state, accum)
        token = next_token(model, state)
        if token == :end
            return accum
        end
        return helper(newstate(state, token), push!(accum, token))
    end

    return helper(init_state, init_accum)
end

"""
    state_with_prefix(model, prefix; strict=false)

Attempts to return a random valid state of `model` that begins with `tokens`.
If `strict` is `false` and the `model` doesn't have any state that begins
with `tokens`, the function shortens the tokens (cuts the last token)
to lower the requirements and tries to find some valid state again.
"""
function state_with_prefix(model, prefix; strict=false)
    # The token sequence must be at most as long as the model's state
    if length(prefix) > model.order
        message =
            "The length of the prefix must be equal" *
            "to or lower than the order of the model (i.e. $(model.order))"
        throw(DomainError(tokens, message))
    end

    # If the tokens are already a valid state, just return them
    # if the token sequence is too short, just fill in :begin to make a valid state
    if haskey(model.nodes, [begseq(model.order - length(prefix)); prefix])
        return [begseq(model.order - length(prefix)); prefix]
    end

    hasprefix(ar, pref) = ar[1:length(pref)] == pref
    # Try to cut out the last element of the token sequence
    # in order to find a valid state with this given prefix
    function helper(pref, states)
        if pref == [] return nothing end
        states_with_prefix = (st for st in states if hasprefix(st, pref))
        if !isempty(states_with_prefix)
            # Return the non-empty iterator of valid states with iven prefix
            return states_with_prefix
        elseif strict
            # We didn't find any states with given prefix
            return nothing
        else
            return helper(pref[1:end-1], states)
        end
    end

    valid_states = helper(prefix, keys(model.nodes))
    if valid_states != nothing
        return rand(collect(valid_states))
    else
        return nothing
    end
end

"""
    next_token(model, state)

Return a token which will come after the current state, at random.
The probabilities of individual tokens getting choosed
are skewed by their individual values in the `TokenOccurences` dictionary
of the current `state`, that is obtained from the `model`.
"""
function next_token(model, state) where T
    # Choose a random token coming after state
    randkey(model.nodes[state])
end

"""
    randkey(dict)

Return a random key from `dict`. The probabilities of individual keys
getting chosen are skewed by their respective values.
"""
function randkey(dict)
    # Accumulate is similar to scanl in Haskell
    # It folds the array with the given function and returns
    # a list of all intermediate values
    possibility_weights = accumulate(+, collect(values(dict)))
    # Generate a random index in range 1:length(keys(dict))
    # by generating a random number and then placing it into
    # a sorted array of accomulated occurence sums
    index = indexin(possibility_weights, rand() * possibility_weights[end])
    return collect(keys(dict))[index]
end

"""
    indexin(array)

Given a sorted `array`, return the index on which `n` would be inserted in
should the insertion preserve the sorting.
"""
function indexin(array, n)
    for i in 1:length(array)
        if array[i] >= n
            return i
        end
    end
    # If we didn't return yet, n is bigger than every element of array
    return length(array) + 1
end

end
