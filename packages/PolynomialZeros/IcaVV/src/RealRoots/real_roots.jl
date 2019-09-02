module RealRoots
using Random
using LinearAlgebra
import Roots: find_zero, AlefeldPotraShi
using Printf




## Find real roots of a polynomial using a DesCartes Method
##
## State of the art for this approach is summarized here:
## Cf. "Computing Real Roots of Real Polynomials ... and now For Real!" by Alexander Kobel, Fabrice Rouillier, Michael Rouillier
## (https://arxiv.org/abs/1605.00410) 
## 
## Earlier work of a Descartes-like method  [Vincent's theorem](http://en.wikipedia.org/wiki/Vincent's_theorem)
## are here "Efficient isolation of polynomial’s real roots" by
## Fabrice Rouillier; Paul Zimmermann
##
## This implementation doesn't take nearly enough care with the details, but takes some ideas
## to implement a means to find real roots of non-pathological polynomials (lowish degree, roots separated)
##
## XXX Needs work XXX

## Polynomial transformations
##
## The Taylor shift here is the most expensive operation
## https://arxiv.org/pdf/1605.00410.pdf has a better strategy
## of partial Taylor shifts, using just the nearby roots
## 


using Polynomials
import Roots: fzero
using ..AGCD

# for interface
struct PolyType{T}
    p::Vector{T}
end
(p::PolyType)(x) = poly_eval(p.p, x)


Polynomials.degree(p::Vector{T}) where {T} = findlast(!iszero,p) - 1


## Interval with [a,b], N
## N is for Newton-Test
mutable struct Intervalab{T,S}
    a::T
    b::S
    N::Int
    bnd::Int
end
width(I::Intervalab) = I.b-I.a
midpoint(I::Intervalab) = I.a + (0.5) * width(I)


## how we store the state of our algorithm to find zero in [0,1]
struct State{T}
    Internal::Vector{Intervalab{T,T}}                    # DesBound > 1
    Isol::Vector{Intervalab{T,T}}                        # DesBound == 1
    Unresolved::Vector{Intervalab{T,T}}
    p::Vector{T}
end

State(p::Vector{T}) where {T} = State(Intervalab{T,T}[], Intervalab{T,T}[], Intervalab{T,T}[], p)
(st::State)(x) = poly_eval(st.p, x)

# polys over vectors mutating first

# poly is [p_0, p_1, ..., p_n] where there may be zeros in last terms

# p + q
function poly_add!(p::Vector{T}, q::Vector{S}) where {T, S}
    n,m = length(p), length(q)
    l = min(n, m)
    for i in 1:l
        p[i] += q[i]
    end
    for i in l:m
        push!(p, q[i])
    end
end

# p-q
poly_sub!(p::Vector{T}, q::Vector{S}) where {T, S} = poly_add(p, -q)

# may be more than one way
function poly_mul!(p1::Vector{T}, p2::Vector{S}) where {T, S}
    R = promote_type(T,S)

    n = length(p1)
    m = length(p2)
    
    a = zeros(R,m+n+1)

    for i = 1:n
        for j = 1:m
            a[i+j+1] += p1[i] * p2[j]
        end
    end
    p1[:] = a

end


function poly_deriv!(p::Vector{T}) where {T}
    for i = 1:length(p)-1
        p[i] = i * p[i+1]
    end
    p[end] = zero(T)
    p
end


function poly_eval(p::Vector{T}, x::S) where {T, S}
    R = promote_type(T,S)

    y = convert(R, p[end])

    for i = (lastindex(p)-1):-1:1
        y = p[i] + x*y
    end
    return y
end


" `p(x + λ)`: Translate polynomial left by λ "
function poly_translate!(p::Vector{T}, lambda=1) where {T}
    p1 = copy(p)
    p[1] = poly_eval(p1, lambda)
    m = one(T)
    for k in 2:length(p1)
        p[k] = poly_eval(poly_deriv!(p1), lambda) / m
        m *= k
    end
    p
end
Tλ(p, lambda=1)   = poly_translate!(copy(p), lambda)

" `R(p)` finds  `x^n p(1/x)` which is a reversal of coefficients "
function poly_reverse!(p)
    reverse!(p)
end
R(p) = poly_reverse!(copy(p))

" `p(λ x)`: scale x axis by λ "
function poly_scale!(p, lambda)
    for i in 2:length(p)
        p[i] *= lambda^(i-1)
    end
end
Hλ(p::Vector{T}, λ=one(T)) where {T} = poly_scale!(copy(p), λ)

"q = p(-x)"
function poly_flip!(p::Vector{T}) where {T}
    for i in 2:2:length(p)
        p[i] = -p[i]
    end
end


## Upper bound on size of real roots that is tighter than cauchy
## titan.princeton.edu/papers/claire/hertz-etal-99.ps
function upperbound(p::Vector{T}) where {T}
    p = p[findfirst(!iszero, p):end]
    descartes_bound(p) == 0 && return zero(T)

    p = p[findfirst(!iszero, p):end]
    
    q, d = p/p[end], length(p)-1
    
    d == 0 && error("degree 0 is a constant")
    d == 1 && abs(q[1])


    a1 = abs(q[d])
    B = maximum([abs(q[i]) for i in 1:(d-1)])

    a,b,c = 1, -(1+a1), a1-B
    (-b + sqrt(b^2 - 4a*c))/2
end

function lowerbound(p::Vector{T}) where {T <: Real}
    p = p[findfirst(!iszero, p):end]
    
    poly_flip!(p)
    ret = -upperbound(p)
    poly_flip!(p)
    ret
end





## Descartes Bounds

" Descartes bound on (0,oo). Just count sign changes"
function descartes_bound(p::Vector{T}) where {T}
    length(p) == 0 && return -1
    cnt, sgn = 0, sign(p[1])
    for i in 2:length(p)
        nsgn = sign(p[i])
        if nsgn * sgn < 0
            sgn = nsgn
            cnt += 1
        end
    end
    cnt
end


# shift polynomial so (a,b) -> (0, oo)
function translate_ab(p::Vector{T}, a, b) where {T}
    #    p0 = Tλ(p, a)
    #    p1 = Hλ(p0, b-a)
    #    p2 = Tλ(R(p1),1)

    p1 = copy(p)
    poly_translate!(p1, a)
    poly_scale!(p1, b-a)
    poly_reverse!(p1)
    poly_translate!(p1, one(T))
    p1
end

" Descartes bound on (a, b)"
descartes_bound_ab(p::Vector{T}, a, b) where {T} = descartes_bound(translate_ab(p, a, b))
DescartesBound_ab(st, node) = descartes_bound_ab(st.p, node.a, node.b)

## Tests

## Return true or false
zero_test(st::State, node)  =   DescartesBound_ab(st, node) == 0 
one_test(st::State, node)  =   DescartesBound_ab(st, node) == 1  

## return count -1 (can't tell), 0, 1, or more
zero_one_test(st::State, node) = DescartesBound_ab(st, node)  


# find admissible point
# XXX improve me
function find_admissible_point(st::State{T},  I::Intervalab, m=midpoint(I), Ni::T=one(T), c::T=one(T)) where {T}
    N = ceil(Int, c * Polynomials.degree(st.p)/2)
    ep = min(m-I.a, I.b - m) / (4*Ni)
    mis = [m + i/N * ep for i in -N:N]
    curmin = min(norm(st(I.a)), norm(st(I.b)))/100
    for m in shuffle(mis)
        (m < I.b || m > I.a) || continue
        descartes_bound_ab(st.p, I.a, m) == -1 && continue
        descartes_bound_ab(st.p, m, I.b) == -1 && continue        
        norm(st(m)) > 0 && return m
    end

    error("No admissible point found")
#    mx, i = findmax(norm.(st.p.(mis)))
#    mis[i]
end


# find splitting point
# find an admissible point that can be used to split interval. Needs to have all
# coefficients not straddle 0
# return (logical, two intervals)
function split_interval(st::State{T},I::Intervalab,  m=midpoint(I), Ni=one(T), c=one(T)) where {T}
    N = ceil(Int, c * Polynomials.degree(st.p)/2)
    ep = min(1, width(I)) / (16*Ni)
    mis = T[m + i/N * ep for i in -N:N]
    mis = filter(m -> m > I.a && m < I.b, mis)
    mx, i = findmax(norm.(st.(mis)))

    ## Now, we need a point that is bigger than max and leaves conclusive
    for i in eachindex(mis)
        mi = mis[i]
        abs(st(mi)) >= min(mx/4, one(T)) || continue
        ileft = Intervalab(I.a, mi, I.N, -2)
        nl = DescartesBound_ab(st, ileft)
        #nl = descartes_bound_ab(fatten(st.p), ileft.a, ileft.b)                
        nl == -1 && continue
        iright = Intervalab(mi, I.b, I.N, -2)
        nr = DescartesBound_ab(st, iright)
        #nr = descartes_bound_ab(fatten(st.p), iright.a, iright.b)                        
        nr == -1 && continue

        # XXX improve this XXX
        # identify degenerate cases here. This is not good.
        # if nl + nr < I.bnd
        #     if nl == 0 || nr == 0
        #         if (nl == 0 && rem(I.bnd - nr,2) == 1) || ( nl == 0 && rem(I.bnd - nr,2) == 1)
        #             println("nl=$nl, nr=$nr, bnd=$(I.bnd) -- is this an error")
        #             return(false, I, I)
        #         end
        #     elseif nl + nr < I.bnd
        #         println("nl=$nl, nr=$nr, bnd=$(I.bnd) -- is this an error")
        #         return(false, I, I)
        #     end
        # end
        
        ileft.bnd = nl; iright.bnd=nr

##        println("Split $(I.a) < $mi < $(I.b): $(nl) & $(nr)")
        
        
        return (true, ileft, iright)
    end
    #    println("DEBUG: $I is a bad interval for splitting?")
    return (false, I, I)
end


## split interval
## adds to intervals if successful
## adds node to Unresolved if not
function linear_step(st::State{T}, node) where {T}
    succ, I1, I2 = split_interval(st, node)

    if succ
        push!(st.Internal, I1)
        push!(st.Internal, I2)
    else
        push!(st.Unresolved, node)
    end
    return true
    
end



## return (true, I), (false, node)
## I will be smaller interval containing all roots in node
function newton_test(st::State{T}, node) where {T}
    NMAX = 1024  # 2147483648 = 2^31
    (node.N > NMAX) && return (false, node) 
    (zero_one_test(st, node) in (0,1)) && return(false, node)

    a, b, m, w, N, bnd  = node.a, node.b, midpoint(node), width(node), node.N, node.bnd

    pprime = poly_deriv!(copy(st.p))
    
    a1 = a - st(a) / poly_eval(pprime, a)
    b1 = b - st(b) / poly_eval(pprime, b)

    if a < a1 && zero_test(st, Intervalab(a, a1, N, 0))
        if b1 < b && zero_test(st, Intervalab(b1, b, N, 0))
            return (true, Intervalab(a1, b1, N*N, -2))
        else
            return(true, Intervalab(b1, b, N*N, -2))
        end
    elseif b1 < b && zero_test(st, Intervalab(b1, b, N, 0))
        return (true, Intervalab(a, b, N*N, -2))
    end

    ## boundary test?

    mlstar::T = find_admissible_point(st, node, a + w/(2N))
    if mlstar > a && zero_test(st, Intervalab(mlstar, b, N,-2))
        return (true, Intervalab(a, mlstar, N,-2))
    end

    mrstar::T = find_admissible_point(st, node, b - w/(2N))
    if mrstar < b && zero_test(st, Intervalab(a, mrstar, N,-2))
        return (true, Intervalab(mrstar, b, N,-2))
    end
    return (false, node)
end



## Add successors to I
## We have
function addSucc(st::State{T}, node) where {T}

    val, I = newton_test(st, node)

    if val
        ## a,b = node.a, node.b
        ## println("Newton test: a=$a <= $(I.a) <= $(I.b) <= $b=b")
        push!(st.Internal, I)
    else
        ##        println("linear step")
        succ = linear_step(st, node)
        if !succ
            warn("node $node was a failure")
        end
    end
    true
end

## m, M should bound the roots
## essentially algorithm 4
function ANewDsc(p::Vector{T}, m = lowerbound(p), M=upperbound(p)) where {T <: Real}

    st = State(p)

    base_node = Intervalab(m, M, 4, -2)    
    base_node.bnd = DescartesBound_ab(st, base_node)


    if base_node.bnd == -1
        append!(st.Internal, break_up_interval(st, base_node, 4))
    else
        push!(st.Internal, base_node)
    end
    
    while length(st.Internal) > 0
        node = pop!(st.Internal)

        bnd = node.bnd
        if bnd == -2
            bnd = DescartesBound_ab(st, node) 
            node.bnd = bnd
        end

        if bnd < 0
            # this is a bad node!
            warn("Bad node, how did it get here: $node")
        elseif bnd == 0
            continue
        elseif bnd == 1
            push!(st.Isol, node)
            continue
        else
            addSucc(st, node)
        end
    end
    st
end


# populate `Isol`
# p must not have any roots with even degree. (e.g. no (x-c)^(2k) exists as a factor for any c,k
# assumed square free (at least no roots of even multiplicity)
function isolate_roots(p::Vector{T}, m, M) where {T <: Real}

#    try
    st = ANewDsc(p, m, M)
    return st
    # catch err
    #     if  !(T <: BigFloat)
    #         try
    #             st = ANewDsc(convert(Poly{BigFloat}, p), m, M)
    #             return st
    #         catch err
    #             rethrow(err)
    #         end
    #     end
    # end
        
end



"""

     real_roots(p, [m], [M]; square_free=true)

Returns real roots of a polynomial presented via its coefficients `[p_0, p_1, ..., p_n]`. 

* `p`: polynomial coefficients, `Vector{T<:Real}`
* `m`: lower bound on real roots. Defaults to `lowerbound(p)`
* `M`: upper bound on real roots. Defaults to `upperbound(p)`
* `square_free`::Bool. If false, the polynomial `agcd(p, polyder(p))` is used. This polynomial---in theory--- would have the
same real roots as `p`, however in practice the approximate `gcd` can be off.

"""
real_roots(p::Poly{T}, args...; kwargs...) where {T <: Real} = real_roots(p.a, args...; kwargs...)
function real_roots(p::Vector{T}, m = lowerbound(p), M=upperbound(p); square_free::Bool=false) where {T <: Real}

    # deflate zero
    nzroots = 0
    while iszero(p[1])
        popfirst!(p)
        nzroots += 1
    end

    if !square_free
        u,v,w,err = AGCD.agcd(Poly(p), polyder(Poly(p)))
        p = v.a
    end

    
    st = isolate_roots(p, m, M)
    
    if length(st.Unresolved) > 0
        println("Some intervals are unresolved:")
        println("------------------------------")
        for node in st.Unresolved
            @printf "* There may be up to %d roots in (%0.16f, %0.16f).\n" node.bnd node.a node.b
        end
        println("------------------------------")                
    end

    rts = zeros(T, length(st.Isol))
    for i in eachindex(st.Isol)
        node = st.Isol[i]
        rt = find_zero(PolyType(p), (node.a, node.b), AlefeldPotraShi())
        #find_zero(PolyType(p), big.((node.a, node.b)), AlefeldPotraShi())
        rts[i] = rt
    end

    nzroots > 0 && push!(rts, zero(T))
    rts
end
        
end
