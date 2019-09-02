module Hermetic
import Combinatorics: doublefactorial
import Base: *, +, ^, size, show, convert
import Calculus: integrate
using Documenter
using Compat
using LinearAlgebra
import LinearAlgebra: rmul!
using Markdown

@doc doc"""
`mono_rank_grlex(m, x)`

returns the graded lexicographic ordering rank of a monomial in m dimensions.

Agrs:

- `m::Int`:  spatial dimension
- `x::Array{Int,1}`:  the `m` dimensional vector representing the monomial.

Returns:

The rank of the monomial.

Details:

The graded lexicographic ordering is used, over all M dimensional vectors with sum 0, then 1, then 2, ...

For example, if m = 3, the monomials are ordered in a sequence that begins

    #  x[1]  x[2]  x[3]     SUM
      +------------------------
    1 |  0     0     0        0
      |
    2 |  0     0     1        1
    3 |  0     1     0        1
    4 |  1     0     0        1
      |
    5 |  0     0     2        2
    6 |  0     1     1        2
    7 |  0     2     0        2
    8 |  1     0     1        2
    9 |  1     1     0        2
   10 |  2     0     0        2
      |
   11 |  0     0     3        3
   12 |  0     1     2        3
   13 |  0     2     1        3
   14 |  0     3     0        3
   15 |  1     0     2        3
   16 |  1     1     1        3
   17 |  1     2     0        3
   18 |  2     0     1        3
   19 |  2     1     0        3
   20 |  3     0     0        3
      |
   21 |  0     0     4        4
   22 |  0     1     3        4
   23 |  0     2     2        4
   24 |  0     3     1        4
   25 |  0     4     0        4
   26 |  1     0     3        4
   27 |  1     1     2        4
   28 |  1     2     1        4
   29 |  1     3     0        4
   30 |  2     0     2        4
   31 |  2     1     1        4
   32 |  2     2     0        4
   33 |  3     0     1        4
   34 |  3     1     0        4
   35 |  4     0     0        4

In the case of m = 1

       x[1]
      +----
    1 |  0
    2 |  1
    3 |  2

- The monomial (1,0,3) has rank 26, and we could determine this by the
    call `rank = mono_rank_grlex (3, [1, 0, 3])`;
- The monomial (0,1,0) has rank 3, and we could determine this by the
    call `rank = mono_rank_grlex ( 3, [0, 1, 0])`;

Example:

`mono_rank_grlex(3, [1,0,3])` return `26`.

First compares the total degree (sum of all exponents), and in case of a tie
applies lexicographic order. This ordering is not only a well ordering, it also
has the property that any monomial is preceded only by a finite number of other
monomials; this is not the case for lexicographic order, where all (infinitely
many) powers of x are less than y (that lexicographic order is nevertheless a
well ordering is related to the impossibility to construct an infinite
decreasing chain of monomials).
In other words,

x^\alpha >_{grlex} x^{\beta} if deg x^\alpha > deg x^\beta or if deg
x^\alpha > deg x^\beta if x^\alpha >_{lex} x^\beta

where in the lexycographic order the power of the first variable is used to
determine the order, with powers of the second variable only looked at when the
first variable appears to the same power in two monomials.
"""
function mono_rank_grlex(m::T, x::Array{T, 1}) where T<:Int

    # @assert m > 0 "The dimension `M` must be > 1"
    # @assert m == length(x) "The monimial size is incompatible with the
    # dimension of the polynomial"

    # for i = 1 : m
    #     if (x[i] < 0)
    #         throw()
    #     end
    # end

    if m==1
        return x[1]+1
    end

    nm = sum(x)

    # Convert to KSUBSET format.

    ns = nm + m - 1;
    ks = m - 1;

    xs = cumsum(x[1:m-1].+1)

    ##  Compute the rank.

    rank = 1;

    @inbounds for i = 1:ks
        tim1 = i == 1 ? 0 : xs[i-1];

        if (tim1 + 1 <= xs[i] - 1)
            for j = tim1 + 1:xs[i] - 1
                rank += binomial(ns - j, ks - i)
            end
        end
    end

    @inbounds for n = 0:nm - 1
        rank += binomial(n + m - 1, n)
    end

    return rank
end

@doc doc"""
`mono_grlex!(X::Array{Int, 2}, m::Int)`

Fills `x::Array{Int, 2}` with the grlx ordering for spacial dimension `m`.
"""
function mono_grlex!(X::Array{Int, 2}, m::Int)
    n, s = size(X)
    @assert s==m

    X[1,:] .= 0

    @inbounds for j = 2:n
        x = view(X, j, :)
        X[j,:] = mono_next_grlex!(vec(X[j-1, :]), m)
    end
    return X
end


@doc doc"""
get_inter_idx(X::Array{Int, 2})

Return the index of interaction terms of order equal to `Ki` of a multivariate
polynomial of order `k` and dimension `m`.

`X::Array{Int, 2}` is obtained from a call to `mono_grlex!(X, m)`.

When `Ki==1` or `Ki=0` return the
index of all interactions.

        XC(1) XC(2) XC(3)  Degree
      +------------------------
    1 |  0     0     0        0
    2 |  0     0     1        1
    3 |  0     1     0        1
    4 |  1     0     0        1
    5 |  0     0     2        2
    6 |  0     1     1        2
    7 |  0     2     0        2
    8 |  1     0     1        2
    9 |  1     1     0        2
   10 |  2     0     0        2
   11 |  0     0     3        3
   12 |  0     1     2        3
   13 |  0     2     1        3
   14 |  0     3     0        3
   15 |  1     0     2        3
   16 |  1     1     1        3
   17 |  1     2     0        3
   18 |  2     0     1        3
   19 |  2     1     0        3
   20 |  3     0     0        3

    So, for Ki = 2

    Bool[true
     true
     true
     true
     true
     true
     true
     true
     true
     true
     true
     false
     false
     true
     false
     false
     false
     false
     false
     true]

"""
function get_inter_idx(X::Array{T, 2}, ki::T) where T<:Int
    n, m = size(X)
    rank = sum(X, dims=2)
    k = maximum(rank)
    nz = sum(map(x -> x == 0 ? 1 : 0, X), dims=2) ## Number of zero in composition

    ## Interactions are those allocation with more than 1 zero. Or, non
    ## interaction are thos allocations with exactly M-1 zeros plus the case with
    ## M zeros
    idx::BitArray = (nz .>= m-1)

    if ki == k
        idx = BitArray([1 for i = 1:n])
    elseif ki > 1 & ki < k
        ## Interactions of order ki corresponds to those allocations λᵢ with
        ## more than 1 zero and sum(λᵢ) == ki
        idx = BitArray((!idx & (rank .== ki)) | idx)
    end
    return idx
end

@doc doc"""
`mono_unrank_grlex{T <: Int}(m::T, rank::T)`

Computes the composition of given grlex rank.

Args:

    - `m` the spatial dimension of the product poly
    - `r` the rank of the composition

Output:
    - `f` the composition of the given rank


Example:

`mono_unrank_grlex(3, 26)` returns [1,0,3]
f = Array{Int}(3, 1)
`mono_unrank_grlex!(f, 3, 26)
println(f)
"""
function mono_unrank_grlex(m::T, rank::T) where T<:Int
    if (m == 1)
        return [rank-1]
    end

    rank1 = 1;
    nm = -1;
    while  true
        nm = nm + 1
        r = binomial(nm + m - 1, nm)
        if (rank < rank1 + r)
            break
        end
        rank1 = rank1 + r
    end

    rank2 = rank - rank1

    ks = m - 1
    ns = nm + m - 1
    nksub = binomial(ns, ks)
    xs = zeros(T, ks, 1);
    j = 1;

    @inbounds for i = 1:ks
        r = binomial(ns - j, ks - i)
        while (r <= rank2 && 0 < r)
            rank2 = rank2 - r
            j = j + 1
            r = binomial(ns - j, ks - i)
        end
        xs[i] = j
        j +=  1
    end

    x = zeros(T, m)
    x[1] = xs[1] - 1
    @inbounds for i = 2:m - 1
        x[i] = xs[i] - xs[i-1] - 1
    end
    x[m] = ns - xs[ks];

    return x
end


function mono_unrank_grlex!(x::Array{T, 1}, m::T, rank::T) where T<:Int
    if (m == 1)
        x[1] = rank-1
        return x
    end

    rank1 = 1;
    nm = -1;
    while  true
        nm = nm + 1
        r = binomial(nm + m - 1, nm)
        if (rank < rank1 + r)
            break
        end
        rank1 = rank1 + r
    end

    rank2 = rank - rank1

    ks = m - 1
    ns = nm + m - 1
    nksub = binomial(ns, ks)
    xs = zeros(T, ks, 1);
    j = 1;

    @inbounds for i = 1:ks
        r = binomial(ns - j, ks - i)
        while (r <= rank2 && 0 < r)
            rank2 = rank2 - r
            j = j + 1
            r = binomial(ns - j, ks - i)
        end
        xs[i] = j
        j +=  1
    end

    x[1] = xs[1] - 1
    @inbounds for i = 2:m - 1
        x[i] = xs[i] - xs[i-1] - 1
    end
    x[m] = ns - xs[ks];

    return x
end

@doc doc"""
`mono_next_grlex!{T <: Int}(m::T, x::Array{T, 1})`

Returns the next monomial in grlex order.

"""
function mono_next_grlex!(x::Array{T, 1}, m::T) where  T<:Int
    @assert m >= 0
    @assert all(x.>=0)

    i = 0
    @inbounds for j = m:-1:1
        if 0 < x[j]
            i = j
            break
        end
    end

    if i == 0
        x[m] = 1
        return x
    elseif i == 1
        t = x[1] + 1
        im1 = m
    elseif 1 < i
        t = x[i]
        im1 = i - 1
    end

    @inbounds x[i] = 0
    @inbounds x[im1] = x[im1] + 1
    @inbounds x[m] = x[m] + t - 1

    return x
end

@doc doc"""
`mono_value!(v, x, λ)`

Evaluates a monomial.

Args:

- `x::Array{Float,2}` the coordinates of the evaluation points.
- `λ::Array{Float,1}` the exponents of the monomial (m×1)


Return the evaluated monomial `v::Array{Float,1}`.

"""
function mono_value(x, λ)
    n, m = size(x)
    v = ones(eltype(x), n)
    m == length(λ) || throw()
    n == length(v) || throw()
    for i = 1:m
        @simd for j = 1:n
            @inbounds v[j] *= x[j, i]^λ[i]
        end
    end
    return v
end

# function mono_value(x::Real, λ)
#     1 == length(λ) || throw()
#     return x^λ[1]
# end

@doc doc"""
`Hen_coefficients(n)`

Calculate the coefficient of Hen(n, x), where `Hen(n, x)` is the
normalized polynomial probabilist Hermite polynomial of degree `n`

Details:

The normalized probabilist Hermite polynomails is defined as


\$\int H_{en_j}(x)H_{en_k}(x) w(x) dx = \delta_{jk}\$

where w(x) is the normal density function.

Args:

- `n` the order of the polynomial

Output:

- `n` the order of the polynomial
- `c` the coefficients
- `e` the exponents of the polynomial

"""
function Hen_coefficients(n)
    κ = 1/sqrt(factorial(n))
    ct = zeros(n+1, n+1)
    ct[1,1] = 1.0

    if n > 0
        ct[2,2] = 1.0
    end

    @inbounds for i = 2:n
        ct[i+1,1]     = - ( i - 1 ) * ct[i-1,1]
        for j=2:i-1
            ct[i+1,j] = ct[i, j-1] - (i - 1)*ct[i-1, j]
        end
        ct[i+1,  i  ] = ct[i, i-1]
        ct[i+1,  i+1] = ct[i, i  ]
    end

    ##  Extract the nonzero data from the alternating columns of the last row.

    o = floor( Int, (n+2)/2)

    c = zeros(o)
    f = zeros(Int, o)

    k = o
    @inbounds for j = n+1:-2:1
        c[k] = ct[n+1, j]
        f[k] = j - 1
        k += - 1
    end

    return (o, rmul!(c, κ), f)
end

function He_coefficients(n)
    ct = zeros(n+1, n+1)
    ct[1,1] = 1.0

    if n > 0
        ct[2,2] = 1.0
    end

    @inbounds for i = 2:n
        ct[i+1,1]     = - ( i - 1 ) * ct[i-1,1]
        for j=2:i-1
            ct[i+1,j] = ct[i, j-1] - (i - 1)*ct[i-1, j]
        end
        ct[i+1,  i  ] = ct[i, i-1]
        ct[i+1,  i+1] = ct[i, i  ]
    end

    ##  Extract the nonzero data from the alternating columns of the last row.

    o = floor( Int, (n+2)/2)

    c = zeros(o)
    f = zeros(Int, o)

    k = o
    @inbounds for j = n+1:-2:1
        c[k] = ct[n+1, j]
        f[k] = j - 1
        k += - 1
    end

    return (o, c, f)
end

@doc doc"""
`Hen_value(n, x)`

evaluates `Hen(n,x)` polynomial

Args:

- `o::Int` the degree of the polynomial
- `x::Array{Float64, 1}` the evaluation points
"""
function Hen_value(n, x::Array{T, 1}) where T<:AbstractFloat
    r = length(x)
    κ = 1/sqrt(factorial(n))
    value = Array{T}(undef, r)

    v = zeros(r, n+1)
    v[1:r, 1] .= 1.0

    if (0 >= n)
        return rmul!(ones(T, r), κ)
    end

    @simd for j = 1:r
         @inbounds v[j, 2] = x[j]
    end

    for j = 2:n
        @simd for i = 1:r
            @inbounds v[i, j+1] = x[i] * v[i, j] - (j - 1) * v[i, j-1]
        end
    end

    @simd for i = 1:r
        @inbounds value[i] = v[i, n + 1]*κ
    end

    return value
end


@doc doc"""
polynomial_value

    Input, int M, the spatial dimension.

    Input, int O, the "order" of the polynomial.

    Input, double C[O], the coefficients of the polynomial.

    Input, int E[O], the indices of the exponents
    of the polynomial.


    Input, double X[NX, M], the coordinates of the evaluation points.
"""
function polynomial_value(m::T, o::T, c::Vector{F}, e::Vector{T}, x::Matrix{F})  where {T <: Int, F <: Real}
    f = Array{Int}(undef,m)
    p = zeros(F, size(x, 1))
    @inbounds for j = 1:o
        mono_unrank_grlex!(f, m, e[j])
        v = mono_value(x, f)
        @simd for i = eachindex(p)
            p[i] = p[i] + c[j]*v[i]
        end
    end
    p
end

# function polynomial_value{T <: Int, F <: Real}(m::T, o::T,
#                                                c::Array{F, 1},
#                                                e::Array{T, 1},
#                                                x::F)
#     p = zero(F)
#     @inbounds for j = 1:o
#           f = mono_unrank_grlex(m, e[j])
#           v = mono_value(x, f)
#           p = p + c[j]*v
#         end
#     p
# end

@doc doc"""
`He_value(n, x)`

evaluates `He(n,x)` polynomial

Args:

- `o::Int` the degree of the polynomial
- `x::Array{Float64, 1}` the evaluation points

"""
function He_value(n, x::Array{T, 1}) where T<:AbstractFloat
    r = length(x)
    κ = 1/sqrt(factorial(n))
    value = Array{T}(r)

    v = zeros(r, n+1)
    v[1:r, 1] = 1.0

    if (0 >= n)
        return rmul!(ones(T, r), κ)
    end

    @simd for j = 1:r
         @inbounds v[j, 2] = x[j]
    end

    for j = 2:n
        @simd for i = 1:r
            @inbounds v[i, j+1] = x[i] * v[i, j] - (j - 1) * v[i, j-1]
        end
    end

    @simd for i = 1:r
        @inbounds value[i] = v[i, n + 1]*κ
    end

    return value
end

@doc doc"""
`polynomial_compress( o, c, e )`

Args:

- `o` the order of the polynomial
- `c` the coefficients of the polynomial
- `e` the indices of the exponents of the polynomial.

Output:

- `o` the order of the compressed polynomial
- `c` the coefficients of the compressed polynomial
- `e` the indices of the exponents of the compressed polynomial.

"""
function polynomial_compress(o::F, c::Vector{T}, e::Vector{F}, retain_zero = false) where {T<:Real, F<:Int}

    # ϵ = sqrt(eps(T))

    c2 = zeros(T, o)
    e2 = zeros(F, o)

    get = 0
    put = 0

    @inbounds while ( get < o )
        get = get + 1;
        if !retain_zero
            if c[get] ≈ 0
                continue
            end
        end
        if 0 == put
            put = put + 1
            c2[put] = c[get]
            e2[put] = e[get]
        else
            if e2[put] == e[get]
                c2[put] = c2[put] + c[get]
            else
                put = put + 1;
                c2[put] = c[get]
                e2[put] = e[get]
            end
        end
    end
    return (put, c2[1:put], e2[1:put])
end


function polynomial_print(m, o, c, e; title = "P(z) = ")
    println(title)
    if o == 0
        println( "      0.")
    else
        for j = 1:o
            print("    ")
            if c[j] < 0.0
                print("- ")
            else
                print("+ ")
            end
            print(abs(c[j])," z^(")

            f = mono_unrank_grlex(m, e[j])

            for i = 1:m
                print(f[i])
                if i < m
                    print(",")
                else
                    print(")")
                end
            end

            if j == o
                print( "." )
            end
            print( "\n" )

        end
    end
end

function polynomial_print_hermite(m, o, c, e; title = "P(z) = ")
    println(title)
    if o == 0
        println( "      0.")
    else
        for j = 1:o
            print("    ")
            if c[j] < 0.0
                print("- ")
            else
                print("+ ")
            end
            print(abs(c[j])," Hen(")

            f = mono_unrank_grlex(m, e[j])

            for i = 1:m
                print(f[i])
                if i < m
                    print(",")
                else
                    print(")")
                end
            end

            if j == o
                print( "." )
            end
            print( "\n" )

        end
    end
end

@doc doc"""

`Henp_to_polynomial (m::Int, l::Array{Int, 1})`

writes a Hermite Product Polynomial as a standard polynomial.

Details:

Hen(i,x) represents the probabilist's normalized Hermite polynomial.

For example, if
   M = 3,
   L = [1, 0, 2 ]

then

   Hen(1,0,2)(X,Y,Z) = Hen(1)(X) * Hen(0)(Y) * Hen(2)(Z)
                     = X * 0.707107*(Y^2-1) *


Args:

- `m::Int` the spatial dimension of the hermite's normalized product (Hnp)
  polynomial
- `l::Array{Int, 1}` the index of the Hnp

Output:

- `o::Int` the "order" of the polynomial product
- `c::Array{int,1}` the coefficients of the polynomial product
- `e::Array{Int,1}` the indices of the exponents of the polynomial product.

"""
function Henp_to_polynomial(m::Int, l::Array{Int, 1})
    o1 = 1
    c1 = [1.0]
    e1 = Int[1];

    c = eltype(1.0)[]
    e = Int[]
    p = Array(Int, 3)
    o = 9

    @inbounds for i = 1:m
        o2, c2, f2  = Hen_coefficients(l[i])
        o = 0;

        for j2 = 1:o2
            for j1 = 1:o1
                o = o + 1;
                push!(c, c1[j1] * c2[j2])
                if (1 < i)
                    p = mono_unrank_grlex(i - 1, e1[j1])
                end
                push!(p, f2[j2])
                push!(e, mono_rank_grlex( i, p ))
            end
        end
        polynomial_sort!(c, e)
        o, c, e = polynomial_compress(o, c, e)
        o1 = copy(o)
        c1 = copy(c)
        e1 = copy(e1)
    end

    return o, c, e
end


function Henp_to_polynomial_fullw(m, o, c, e)
    f1 = Array(Int, m)
    Hermetic.mono_unrank_grlex!(f1, m, e[1])
    o0, c0, e0 = Hermetic.Henp_to_polynomial(m, f1)
    c0 = c0*c[1]
    for j = 2:o
        Hermetic.mono_unrank_grlex!(f1, m, e[j])
        o1, c1, e1 = Hermetic.Henp_to_polynomial(m, f1)
        c1 = c1*c[j]
        o0, c0, e0 = Hermetic.polynomial_add(o0, c0, e0, o1, c1, e1)
    end
    return o0, c0, e0
end

@doc doc"""
`polynomial_sort! ( c, e )`

sorts the information in a polynomial.

Details:

The coefficients `c` and exponents `e` are rearranged so that the
elements of `e` are in ascending order.

- `c::Array{Float64,1}` the coefficients of the polynomial.
- `e::Array{Int,1}` the indices of the exponents of the polynomial.

Output:

- `c::Array{Float,1}` the coefficients of the **sorted** polynomial.
- `e::Array{Int,1}` the indices of the exponents of the **sorted** polynomial.
"""
function polynomial_sort!(c::Vector{F}, e::Vector{T}) where {T <: Integer, F <: Real}
    i = sortperm(e)
    c[:] = c[i]
    e[:] = e[i]
end


@doc doc"""
`polynomial_add(o1, c1, e1, o2, c2, e2)`

Adds two polynomial

Args:

      - o1::Int the "order" of polynomial 1.

      - c1::Array{Float64,1}, the `O1×1` coefficients of polynomial 1.

      - e1::Array{Float64,1}, the `O1×1`, the indices of the exponents
    of polynomial 1.

      - o2::Int the "order" of polynomial 2.

      - c2::Array{Float64,1}, the `O2×1` coefficients of polynomial 2

      - e1::Array{Float64,1}, the `O2×1`, the indices of the exponents
    of polynomial 2.

"""
function polynomial_add(o1::F, c1::Vector{T}, e1::Vector{F}, o2::F, c2::Vector{T}, e2::Vector{F}) where {T <: AbstractFloat, F <: Int}
    o = o1 + o2
    c = [c1; c2]
    e = [e1; e2]

    polynomial_sort!(c, e)
    return polynomial_compress(o, c, e)
end


@doc doc"""
`polynomial_mul(m, o1, c1, e1, o2, c2, e2)`

Multiply two polynomials

Args:

      - m::Int the spatial dimension of the product polynomial

      - o1::Int the "order" of polynomial 1.

      - c1::Array{Float64,1}, the `O1×1` coefficients of polynomial 1.

      - e1::Array{Float64,1}, the `O1×1`, the indices of the exponents
    of polynomial 1.

      - o2::Int the "order" of polynomial 2.

      - c2::Array{Float64,1}, the `O2×1` coefficients of polynomial 2

      - e1::Array{Float64,1}, the `O2×1`, the indices of the exponents
    of polynomial 2.


"""
function polynomial_mul(m::F, o1::F, c1::AbstractArray, e1::Vector{F}, o2::F, c2::AbstractArray, e2::Vector{F}) where F<:Int
    o  = zero(F)
    f  = Array{F}(undef,m)
    f1 = Array{F}(undef,m)
    f2 = Array{F}(undef,m)
    c  = Array{eltype(c1)}(undef, o1*o2)
    e  = Array{F}(undef, o1*o2)
    @inbounds for j = 1:o2
        for i = 1:o1
            o += 1
            c[o] = c1[i] * c2[j]
            Hermetic.mono_unrank_grlex!(f1, m, e1[i])
            Hermetic.mono_unrank_grlex!(f2, m, e2[j])
            for k = 1:m
                f[k] = f1[k] + f2[k]
            end
            e[o] = Hermetic.mono_rank_grlex(m, f)
        end
    end
    polynomial_sort!(c, e)
    return polynomial_compress(o, c, e)
end


function polynomial_pow2(m::F, o1::F, c1::AbstractArray, e1::Vector{F}) where F<:Int
    polynomial_mul(m::F, o1, c1, e1, o1, c1, e1)
end



function polynomial_mul_unc(m::F, o1::F, c1::AbstractArray, e1::Vector{F}, o2::F, c2::AbstractArray, e2::Vector{F}) where F<:Int
    o  = zero(F)
    f  = Array{F}(undef,m)
    f1 = Array{F}(undef,m)
    f2 = Array{F}(undef,m)
    c  = Array{eltype(c1)}(undef,o1*o2)
    e  = Array{F}(undef,o1*o2)
    @inbounds for j = 1:o2
        for i = 1:o1
            o += 1
            c[o] = c1[i] * c2[j]
            Hermetic.mono_unrank_grlex!(f1, m, e1[i])
            Hermetic.mono_unrank_grlex!(f2, m, e2[j])
            for k = 1:m
                f[k] = f1[k] + f2[k]
            end
            e[o] = Hermetic.mono_rank_grlex(m, f)
        end
    end
    polynomial_sort!(c, e)
    return (o, c, e)
end

@doc doc"""
`polynomial_scale{T <: AbstractFloat, F <: Int}(s, m::F, o::F,
    c::Array{T, 1}, e::Array{F, 1})`

Scales a polynomial.

Args:
    - `s` the scale factor
    - `m` the spatial dimension
    - `o` the order of the polynomial
    - `c` the coefficients
    - `e` the exponent

Output:
    - o
    - c
    - e
"""
function polynomial_scale(s, m::F, o::F, c::AbstractArray, e::Vector{F}) where F<:Int
    @simd for i = 1:o
        @inbounds c[i] = c[i] * s
    end
    return polynomial_compress(o, c, e)
end


@doc doc"""

fall_fact(x, n)


Input, int X, the argument of the falling factorial function.

    Input, int N, the order of the falling factorial function.
    If N = 0, FALL = 1, if N = 1, FALL = X.  Note that if N is
    negative, a "rising" factorial will be computed.

"""
function fall_fact(x::T, n::Int) where T<:Int
  @assert n >= 0
  value = one(T)
  for i in 1:n
    value *= x
    x -=  1
  end
  return value
end


@doc doc"""

polynomial_dif

Differentiates a polynomial

dif::Array{T}(m) indicates the number of differentiations in each component

"""
function polynomial_dif(m, o, c, e, dif)
  c1 = copy(c)
  o1 = copy(o)
  e1 = similar(e)
  for j in 1:o
    f1 = mono_unrank_grlex(m, e[j])
    for i in 1:m
      c1[j] = c1[j]*fall_fact(f1[i], dif[i])
      f1[i] = max(f1[i]-dif[i], 0)
    end
    e1[j] = mono_rank_grlex(m, f1)
  end
  polynomial_sort!(c1, e1)
  o1, c1, e1 = polynomial_compress(o1, c1, e1)
end

@doc doc"""
gamma_half_integer(j)

Calculate Gamma(j/2)/√π
"""
function gamma_half_integer(j::Int)
    if j == 1
        return 1.0
    elseif j == 2
        return 7.071067811865474760643777948402871575373580514923
    elseif j == 3
        return 0.5
    elseif j == 4
        return 7.071067811865475870866802573559434528841817345661
    elseif j == 5
        return 0.75
    elseif j == 6
        return 1.414213562373095174173360514711886905768363469132
    elseif j == 7
        return 1.875
    elseif j == 8
        return 4.242640687119285522520081544135660717305090407396692888115451607036320300977011
    elseif j == 9
        return 6.5625
    elseif j == 11
        return 29.53125
    elseif j == 12
        return 8.485281374238571045040163088271321434610180814793385776230903214072640601954105e+01
    elseif j == 13
        return 162.421875
    else
      Float64(doublefactorial(j-2)/(2^((j-1)/2)))
    end
end


@doc doc"""
calculate the expectation of the monomial with exponent e with respect
to n(0,1)
"""
function expectation_monomial(m, e)
    f = Array{Int}(m)
    expectation_monomial!(f, m, e)
end

function expectation_monomial!(f, m, e)
    Hermetic.mono_unrank_grlex!(f, m, e)
    g = 0.0
    @inbounds if all(map(iseven, f))
        g = 1.0
        for r = 1:m
            g *= (2^(f[r]/2) * gamma_half_integer(1+f[r]))
        end
    end
    return g
end

function expectation_monomial!(f, m)
    g = 0.0
    @inbounds if all(map(iseven, f))
        g = 1.0
        for r = 1:m
            g *= (2^(f[r]/2) * gamma_half_integer(1+f[r]))
        end
    end
    return g
end

@doc doc"""
Calculate ∫ P(z) phi(z; 0, I) dz

Note: Gamma((1+j)/2) for j even is a gamma evaluated on half integer.

Int general
Gamma(n/2) = (n-2)!!/(2^(n-1)/2)√π

Thus

gamma((1+f1[r])/2))/√π = (f1[r]-1)!!/2^(f1[r]/2)

"""
function integrate_polynomial(m::Int, o::Int, c::AbstractArray, e::Vector{Int})
    f = Array{Int}(undef,m)
    h = zero(eltype(c))
    @inbounds for j = 1:o
        g = expectation_monomial!(f, m, e[j])
        h += g*c[j]
    end
    return h
end

@doc doc"""
Calculate ∫P(z) phi(z; 0, I) dz
"""
function integrate_polynomial_times_xn(m::Int, o::Int, c::AbstractArray, e::Vector{Int},
                                       n::Float64 = 1.0)
    f1 = Array{Int}(undef,m)
    f2 = Array{Int}(undef,m)
    h = zeros(eltype(c), m)
    for j = 1:o
        Hermetic.mono_unrank_grlex!(f1, m, e[j])
        for k = 1:m
            @simd for r = 1:m
                @inbounds f2[r] = ifelse(r == k, f1[r] + n, f1[r])
            end
            g = expectation_monomial!(f2, m)
            h[k] += g*c[j]
        end
    end
    return h
end


@compat abstract type PolyType end
mutable struct Hermite <: PolyType end
mutable struct Standard <: PolyType end

struct ProductPoly{F <: PolyType, T<:Int, V <: AbstractArray, S<:AbstractArray}
    m::T
    k::T
    o::T
    c::V
    e::S
    polytype::F
end


function _set_ppoly(m, k, inter_max_order)
    na = binomial(m+k, k)
    inter_max_order >= 0 && inter_max_order <= k || throw("Condition not
                               satisfied: `0 ≤ inter_max_order ≤ k`")
    L = zeros(Int, na, m)
    mono_grlex!(L, m)
    idx = findall(get_inter_idx(L, inter_max_order))
    e = getindex(1:na, idx)
    c = [1.0; zeros(eltype(1.0), length(e)-1)]
    (m, k, length(c), c, e)
end

function _set_ppoly(m, k, coef_, inter_max_order)
    na = binomial(m+k, k)
    inter_max_order >= 0 && inter_max_order <= k || throw("Condition not
                               satisfied: `0 ≤ inter_max_order ≤ k`")
    L = zeros(Int, na, m)
    mono_grlex!(L, m)
    idx = find(get_inter_idx(L, inter_max_order))
    e = getindex(1:na, idx)
    c = coef_
    (m, k, length(c), c, e)
end

function ProductPoly(::Type{Hermite}, m::Int, k::Int; Iz::Int = k)
    ProductPoly(_set_ppoly(m, k, Iz)...,  Hermite())
end

function ProductPoly(::Type{Standard}, m::Int, k::Int; Iz::Int = k)
    ProductPoly(_set_ppoly(m, k, Iz)...,  Standard())
end

function ProductPoly(::Type{Hermite}, m::Int, k::Int, coef_::AbstractArray; Iz::Int = k)
    ProductPoly(_set_ppoly(m, k, coef_, Iz)...,  Hermite())
end

function ProductPoly(::Type{Standard}, m::Int, k::Int, coef_::AbstractArray; Iz::Int = k)
    ProductPoly(_set_ppoly(m, k, coef_, Iz)...,  Standard())
end




ProductPoly(m::Int, k::Int;  args...) = ProductPoly(Standard, m, k; args...)


function convert(::Type{ProductPoly{Standard}},
                 p::ProductPoly{Hermite})
    o, c, e = Henp_to_polynomial_fullw(p.m, p.o, p.c, p.e)
    ProductPoly(p.m, p.k, o, c, e, Standard())
end

function *(p::ProductPoly{Standard},
    q::ProductPoly{Standard}, retain_zero = false)
    @assert p.m == q.m
    o, c, e = polynomial_mul_unc(p.m, p.o, p.c, p.e, q.o, q.c, q.e)
    o, c, e = polynomial_compress(o, c, e, retain_zero)
    ## Calculate real order of product polynomial (that is, the higher
    ## exponent)
    ## This is in general equal to p.k, but if some coefficient is zero
    ## need to calculate this
    g = 0
    for j in e
        g = max(g, maximum(Hermetic.mono_unrank_grlex(p.m, j)))
    end
    ProductPoly(p.m, g, o, c, e, Standard())
end

function +(p::ProductPoly{Standard},
           q::ProductPoly{Standard})
    @assert p.m == q.m
    o, c, e = polynomial_add(p.o, p.c, p.e, q.o, q.c, q.e)
    ProductPoly(p.m, p.k + q.k, o, c, e, Standard())
end

function *(p::ProductPoly{Hermite},
           q::ProductPoly{Standard})
    p = convert(ProductPoly{Standard}, p)
    p * q
end

function *(p::ProductPoly{Standard},
           q::ProductPoly{Hermite})
    q = convert(ProductPoly{Standard}, q)
    p * q
end

function *(p::ProductPoly{Hermite},
           q::ProductPoly{Hermite})
    q = convert(ProductPoly{Standard}, q)
    p = convert(ProductPoly{Standard}, p)
    p * q
end

function ^(p::ProductPoly{Standard}, j::Integer)
    if j == 1
        return p
    end
    for h in 2:j
        o, c, e = polynomial_pow2(p.m, p.o, p.c, p.e)
        g = 0
        for j in e
            g = max(g, maximum(Hermetic.mono_unrank_grlex(p.m, j)))
        end
        p = ProductPoly(p.m, g, o, c, e, Standard())
    end
    return p
end

function Base.broadcast(::typeof(*), s::Real, p::ProductPoly{Standard})
    c = copy(p.c)
    o, c, e = polynomial_scale(s, p.m, p.o, c, p.e)
    ProductPoly(p.m, p.k, o, c, e, Standard())
end

function LinearAlgebra.rmul!(p::ProductPoly{Standard}, s::Real)
    polynomial_scale(s, p.m, p.o, p.c, p.e)
end


function polyval(p::ProductPoly{Standard}, x::Array{T, 2}) where T<:Real
    polynomial_value(p.m, p.o, p.c, p.e, x)
end

function polyval(p::ProductPoly{Hermite}, x::Array{T, 2}) where T<:Real
    polynomial_value(p.m, p.o, p.c, p.e, x)
end

integrate(p::ProductPoly{Standard}) = integrate_polynomial(p.m, p.o, p.c, p.e)


function show(io::IO, p::ProductPoly{Standard})
    println("ProductPoly{Standard} - Dimension: ", p.m, " - Order: ",
    p.k)
    polynomial_print(p.m, p.o, p.c, p.e; title = "P(z) = ")
end

function show(io::IO, p::ProductPoly{Hermite})
    println("ProductPoly{Hermite} - Dimension: ", p.m, " - Order: ",
    p.k)
    polynomial_print_hermite(p.m, p.o, p.c, p.e; title = "P(z) = ")
end

function setcoef!(p::ProductPoly, α)
    nc = length(p.c)
    @assert length(α) == nc || throw()
    copyto!(p.c, α)
    p
end

poly_order(p::ProductPoly) = p.k

export ProductPoly, setcoef!, polyval, Hermite, Standard, integrate, poly_order, scale

end # module
