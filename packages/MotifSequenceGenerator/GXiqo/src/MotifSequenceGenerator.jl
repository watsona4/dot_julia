"""
    MotifSequenceGenerator
This module generates random sequences of motifs, under the constrain that the
sequence has some total length ℓ so that `q - δq ≤ ℓ ≤ q + δq`.
All main functionality is given by the function [`random_sequence`](@ref).
"""
module MotifSequenceGenerator

using Combinatorics, Random, StatsBase

export random_sequence, all_possible_sums

struct DeadEndMotifs <: Exception
  tries::Int
  summands::Int
  tailcut::Int
end
Base.showerror(io::IO, e::DeadEndMotifs) = print(io,
"DeadEndMotifs: Couldn't find a proper sequence with $(e.tries) random tries, "*
"each with summands up to $(e.summands) (total tailcuts: $(e.tailcut)).")

#= Algorithm description
The algorithm works as follows: First a random sequence of motifs is created,
so that it has length of `q - δq ≤ ℓ ≤ q - δq + maximum(motiflengths)`.
The possible tries of random sequences is set by the `tries` keyword (default `5`).
The sequence is optionally sampled given a probability vector.

For each random try, it is first checked whether the sequence is already correct.
If not, the last entry of the sequence is dropped. Then, since the sequence is now
already smaller than `q`, all possible sums of `summands` out of the motif pool
are checked. If some combination of `summands` sums to the difference,
they are added to the sequence.
For multiple satisfactory combinations, a random one is picked.

If the random combination of `summands` does not fit, one more entry is dropped
from the sequence and the process is repeated.

The keyword `tailcut` limits how many times will an element
be dropped (default is `2`).
The keyword `summands` denotes how many possible combinations of sums to check.
Default is `3` which means that we check from 2 up to `3` summands (*all*
possible combinations of summands are checked, which means that the computation
skyrockets for large `summands`!).

If after going though all these combinations of possible sequences we do not find
a proper one, an error is thrown.
=#

"""
    random_sequence(motifs::Vector{M}, q, limits, translate, δq = 0; kwargs...)
Create a random sequence of motifs of type `M`, under the constraint that the
sequence has "length" `ℓ` **exactly** within `q - δq ≤ ℓ ≤ q + δq`.
Return the sequence itself as well as the
sequence of indices of `motifs` used to create it. A vector of probabilities `weights`
can be given as a keyword argument, which then dictates the sampling probability
for each entry of `motifs` for the initial sequence created.

"length" here means an abstracted length defined by the struct `M`,
based on the `limits` and `translate` functions.
It does **not** refer to the amount of elements!

`M` can be anything, given the two functions
* `limits(motif)` : Some function that given the `motif` it returns the
  `(start, fine)` of the the motif in the same units as `q`.
  This function establishes a measure of length, which simply is `fine - start`.
* `translate(motif, t)` : Some function that given the `motif` it returns a *new*
  motif which is translated by `t` (either negative or positive), with
  respect to the same units as `q`.

## Other Keywords
Please see the source code (use `@which`) for a full description of the algorithm.

* `tries = 5` : Up to how many initial random sequences are accepted.
* `taulcut = 2` : Up to how times an element is dropped from the initial guess.
* `summands = 3` : Up to how many motifs may be combined as a sum to
  complete a sequence.
"""
function random_sequence(motifs::Vector{M}, q,
    limits, translate, δq = 0;
    tries = 5, summands = 3, tailcut = 2,
    weights = ones(length(motifs))) where {M}

    ws = _toweight(weights)

    idxs = 1:length(motifs)
    motifs0, motiflens = _motifs_at_origin(motifs, limits, translate)

    q - δq < minimum(motiflens) && throw(ArgumentError(
    "Minimum length of motifs is greater than `q - δq`! "*
    "Impossible to make a sequence."
    ))

    eltype(motiflens) <: AbstractFloat && δq == 0 && throw(ArgumentError(
    "Due to finite precision of floating values, it is almost always impossible "*
    "to create a sequence of *exact* amount of floating length. Please provide "*
    "a δq > 0."
    ))

    worked = false; count = 0; seq = Int[]
    while worked == false
        count > tries && throw(DeadEndMotifs(tries, summands, tailcut))

        seq, seq_length = _random_sequence_try(motiflens, q, δq, ws)

        worked = _complete_sequence!(seq, motiflens, q, δq, summands, tailcut)

        count += 1
    end

    return _instantiate_sequence(motifs0, motiflens, seq, translate), seq
end

_toweight(a) = (s = sum(a); ProbabilityWeights(a./s, 1))

"""
    _motifs_at_origin(motifs, limits, translate) -> (motifs0, motiflens)
Bring all motifs to the origin and compute the motif lengths.
"""
function _motifs_at_origin(motifs::Vector{M}, limits, translate) where M
    motifs0 = similar(motifs)
    a, b = limits(motifs[1])
    motiflens = zeros(typeof(b-a), length(motifs))
    for i in 1:length(motifs)
        start, fine = limits(motifs[i])
        motifs0[i] = start == 0 ? motifs[i] : translate(motifs[i], -start)
        motiflens[i] = fine - start
    end
    return motifs0, motiflens
end

"""
    _random_sequence_try(motiflens, q, δq [, ws]) -> seq, seq_length
Return a random sequence of motif indices
so that the total sequence is *guaranteed* to have total length of
`q - δq ≤ ℓ ≤ q - δq + maximum(motiflens)`.
"""
function _random_sequence_try(motiflens, q, δq, ws = defaultweights(motiflens))
    seq = Int[]; seq_length = 0; idxs = 1:length(motiflens)
    while seq_length < q - δq
        i = sample(idxs, ws)
        push!(seq, i)
        seq_length += motiflens[i]
    end
    return seq, seq_length
end

function _complete_sequence!(seq, motiflens, q, δq, summands, tailcut)
    # notice the ||
    _complete_sequence_extra!(seq, motiflens, q, δq) ||
    _complete_sequence_remainder!(seq, motiflens, q, δq, summands, tailcut) ||
    false
end
function _complete_sequence_extra!(seq, motiflens, q, δq)

    ℓ = sum(motiflens[k] for k in seq)

    if q - δq ≤ ℓ ≤ q + δq
        # Case 0: The sequence is already within δq limits
        return true
    elseif (extra = ℓ - q - δq) > 0
        # Case 1: There is an extra difference. We check if it can be
        # accounted for by deleted some motif with length up to `extra + 2δq`.
        # We find the possible motifs, pick a random one, and pick
        # a random position in the sequence that it exists.
        # Delete that entry of the sequence.
        mi = findall(x -> extra ≤ x ≤ extra + 2δq, motiflens)
        possible = findall(in(mi), seq)
        if !isempty(possible)
            deleteat!(seq, rand(possible))
            return true
        end
    end
    return false
end
function _complete_sequence_remainder!(seq, motiflens, q, δq, summands, tailcut)

    # Case 2: Recursive deletion of last entry of the sequence, and trying to
    # see if it can be completed with some combination of existing motifs
    tcut = 0
    while tcut < tailcut
        tcut += 1
        pop!(seq)
        isempty(seq) && return false

        # At this point ℓ is guaranteed less than q - δq
        remainder = q - δq - sum(motiflens[k] for k in seq)
        @assert remainder > 0

        mi = findall(x -> remainder ≤ x ≤ remainder + 2δq, motiflens)
        if !isempty(mi)
            push!(seq, rand(mi))
            return true
        end

        for n in 2:summands
            everything = all_possible_sums(motiflens, n)
            sums = [e[1] for e in everything]
            cases = findall(x -> remainder ≤ x ≤ remainder + 2δq, sums)
            if !isempty(cases)
                idxs_of_vals = shuffle!(everything[rand(cases)][2])
                push!(seq, idxs_of_vals...)
                return true
            end
        end
    end
    return false
end

# Function provided by Mark Birtwistle in stackoverflow
"""
    all_possible_sums(summands, n)
Compute all possible sums from combining `n` elements from `summands`
(with repetition), only using unique combinations.

Return a vector of tuples: the first
entry of each tuple is the sum, while the second is the indices of summands
used to compute the sum.
"""
function all_possible_sums(summands::Vector{T}, n) where {T}
    m = length(summands)
    r = Vector{Tuple{T, Vector{Int}}}(undef, binomial(m + n - 1, n))
    s = with_replacement_combinations(eachindex(summands), n)
    for (j, i) in enumerate(s)
        r[j] = (sum(summands[j] for j in i), i)
    end
    return r
end

function _instantiate_sequence(motifs0::Vector{M}, motiflens, seq, translate) where M
    ret = M[]
    prev = 0
    for s in seq
        push!(ret, translate(motifs0[s], prev))
        prev += motiflens[s]
    end
    return ret
end



end#Module
