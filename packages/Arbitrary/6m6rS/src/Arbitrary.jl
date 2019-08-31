module Arbitrary

using Base.Iterators
using Random

using IterTools

export arbitrary
export Generate
export ArbState
export Small
export Fun, fun_isequal



# TODO: Create a SimpleTrait "Arbitrary"



# Create an iterator from a stateful function
struct Generate{T}
    fun::Function
end

Base.IteratorEltype(::Type{Generate{T}}) where {T} = Base.HasEltype()
Base.IteratorSize(::Type{Generate{T}}) where {T} = Base.IsInfinite()
Base.eltype(::Type{Generate{T}}) where {T} = T
Base.iterate(gen::Generate{T}, state::Nothing = nothing) where {T} =
    (gen.fun()::T, nothing)



# Internal state for arbitrary iterators
mutable struct ArbState
    rng::AbstractRNG
end

# Provide a default state
arbitrary(::Type{T}) where {T} = arbitrary(T, ArbState(MersenneTwister()))
arbitrary(::Type{T}, seed::UInt) where {T} =
    arbitrary(T, ArbState(MersenneTwister(seed)))



# Produce arbitrary values based on an RNG
random_arbitrary(::Type{T}, ast::ArbState) where {T} =
    Generate{T}(() -> rand(ast.rng, T))
random_arbitrary(r::AbstractRange{T}, ast::ArbState) where {T} =
    Generate{T}(() -> rand(ast.rng, r))



# Methods for particular types
arbitrary(::Type{Nothing}, ast::ArbState) = repeated(nothing)

arbitrary(::Type{Bool}, ast::ArbState) = random_arbitrary(Bool, ast)

arbitrary(::Type{Char}, ast::ArbState) =
    flatten([Char['a', 'b', 'c', 'A', 'B', 'C', '0', '1', '2',
                  '\'', '"', '`', '\\', '/',
                  ' ', '\t', '\r', '\n',
                  '\0'],
             random_arbitrary(Char, ast)])

arbitrary(::Type{S}, ast::ArbState) where {S<:Signed} =
    flatten([S[0, 1, 2, 3, -1, -2, 10, 100, -10,
               typemax(S), typemax(S)-1, typemin(S), typemin(S)+1],
             random_arbitrary(S, ast)])

arbitrary(::Type{U}, ast::ArbState) where {U<:Unsigned} =
    flatten([U[0, 1, 2, 3, 10, 100, typemax(U), typemax(U)-1],
             random_arbitrary(U, ast)])

const Floating = Union{Float16, Float32, Float64}
arbitrary(::Type{F}, ast::ArbState) where {F<:Floating} =
    flatten([F[0, 1, 2, 3, -1, -2, 10, 100, -10,
               1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
               F(-0.0), F(Inf), F(-Inf), eps(F), 1+eps(F), 1-eps(F),
               F(NaN)],
             random_arbitrary(F, ast)])

arbitrary(::Type{BigInt}, ast::ArbState) =
    flatten([BigInt[0, 1, 2, 3, -1, -2, 10, 100, -10,
                    big(10)^10, big(10)^100, -big(10)^10],
             imap(big, random_arbitrary(Int, ast))])

arbitrary(::Type{BigFloat}, ast::ArbState) =
    flatten([BigFloat[0, 1, 2, 3, -1, -2, 10, 100, -10,
                      1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
                      big(10)^10, big(10)^100, big(10)^1000, -big(10)^10,
                      big(10)^-10, big(10)^-100, big(10)^-1000, -big(10)^-10],
             imap(big, random_arbitrary(Float64, ast))])

const BigRational = Rational{BigInt}
function mkrat(arb::Iterators.Stateful)::BigRational
    enum = big(popfirst!(arb)::Int)
    denom = big(0)
    while denom == 0
        denom = big(popfirst!(arb)::Int)
    end
    BigRational(enum, denom)
end
arbitrary(::Type{BigRational}, ast::ArbState) =
    flatten([BigRational[0, 1, 2, 3, -1, -2, 10, 100, -10,
                         1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
                         big(10)^10, big(10)^100, -big(10)^10,
                         1//big(10)^10, 1//big(10)^100, -1//big(10)^10],
             Generate{BigRational}(
                 let iter = Iterators.Stateful(random_arbitrary(Int, ast))
                     () -> mkrat(iter)
                 end)])

struct Small{T}
    value::T
end
Base.getindex(s::Small{T}) where {T} = s.value

arbitrary(::Type{Small{U}}, ast::ArbState) where {U <: Unsigned} =
    imap(Small{U}, flatten([U[0, 1, 2, 3, 10, 100, 1000],
                            random_arbitrary(U(0):U(1000), ast)]))

arbitrary(::Type{Ref{T}}, ast::ArbState) where {T} =
    imap(x -> Ref{T}(x), arbitrary(T, ast))

arbitrary(::Type{Tuple{}}, ast::ArbState) =
    repeated(Tuple{}())

arbitrary(::Type{Tuple{T}}, ast::ArbState) where {T} =
    imap(x -> Tuple{T}((x,)), arbitrary(T, ast))

arbitrary(::Type{Tuple{T1, T2}}, ast::ArbState) where {T1, T2} =
    imap((x, y) -> Tuple{T1, T2}((x, y)),
         arbitrary(T1, ast), arbitrary(T2, ast))

@generated function arbitrary(::Type{T}, ast::ArbState) where {T <: Tuple}
    N = fieldcount(T)
    @assert N > 2
    quote
        zip($((:(arbitrary($(fieldtype(T, i)), ast)) for i in 1:N)...))
    end
end

arbitrary(::Type{Array{T, 0}}, ast::ArbState) where {T} =
    imap(x -> fill(x, ()), arbitrary(T, ast))

function arbitrary(::Type{Array{T, 1}}, ast::ArbState) where {T}
    lengths = Iterators.Stateful(arbitrary(Small{UInt}, ast))
    elems = Iterators.Stateful(arbitrary(T, ast))
    Generate{Array{T, 1}}(
        () -> begin
                  len = popfirst!(lengths)
                  xs = Array{T, 1}(undef, len[] % 100)
                  for i in eachindex(xs)
                      xs[i] = popfirst!(elems)
                  end
                  xs
              end)
end

function arbitrary(::Type{Array{T, 2}}, ast::ArbState) where {T}
    lengths =
        Iterators.Stateful(arbitrary(Tuple{Small{UInt}, Small{UInt}}, ast))
    elems = Iterators.Stateful(arbitrary(T, ast))
    Generate{Array{T, 2}}(
        () -> begin
                  len1, len2 = popfirst!(lengths)
                  xs = Array{T, 2}(undef, len1[] % 10, len2[] % 10)
                  for i in eachindex(xs)
                      xs[i] = popfirst!(elems)
                  end
                  xs
              end)
end



mutable struct Fun{T, R}
    arb
    dict::Dict{T, R}
    function Fun{T, R}(arb) where {T, R}
        new{T, R}(Iterators.Stateful(arb), Dict{T, R}())
    end
end

function arbitrary(::Type{Fun{T, R}}, ast::ArbState) where {T, R}
    # TODO: Use different ArbStates for different functions
    Generate{Fun{T, R}}(() -> Fun{T, R}(arbitrary(R, ast)))
end

struct NotFound end
function (f::Fun{T,R})(x::T)::R where {T, R}
    r = get(f.dict, x, NotFound())
    r !== NotFound() && return r
    f.dict[x] = popfirst!(f.arb)
end

function fun_isequal(::Type{T}, f, g) where {T}
    # T = common(argtype(f), argtype(g))
    xs = collect(take(arbitrary(T), 100))
    all(isequal(f(x), g(x)) for x in xs)
end

end
