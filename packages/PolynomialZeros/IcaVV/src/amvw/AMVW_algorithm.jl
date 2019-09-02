
## Main algorithm of AMV&W
## This follows that given in the paper very closely
## should trace algorithm better with `verbose`
function AMVW_algorithm(state::FactorizationType{T, St, P, Tw}) where {T,St,P,Tw}

    it_max = 20 * state.N
    kk = 0
    while kk <= it_max
        ## finished up!
        state.ctrs.stop_index <= 0 && return

        state.ctrs.it_count += 1


        check_deflation(state)
        kk += 1

#        @info kk, "step"
#        println(sprint(io -> show(io, "text/plain", AMVW.full_matrix(state))), "\n")
#        verbose=true
#        verbose && show_status(state)

        k = state.ctrs.stop_index

        if state.ctrs.stop_index - state.ctrs.zero_index >= 2
            bulge_step(state)
            state.ctrs.tr -= 2

        elseif state.ctrs.stop_index - state.ctrs.zero_index == 1

            diagonal_block(state,  k + 1)
            eigen_values(state)


            state.REIGS[k], state.IEIGS[k] = state.e2
            state.REIGS[k+1], state.IEIGS[k+1] = state.e1

            if k > 1
                diagonal_block(state,  k)
                eigen_values(state)
            end

            diagonal_block(state, 2)

            if state.ctrs.stop_index == 2
                diagonal_block(state, 2)
                e1 = state.A[1,1]
                state.REIGS[1] = real(e1)
                state.IEIGS[1] = imag(e1)
            end
            state.ctrs.zero_index = 0
            state.ctrs.start_index = 1
            state.ctrs.stop_index = state.ctrs.stop_index - 2

        elseif state.ctrs.stop_index - state.ctrs.zero_index == 0

            diagonal_block(state, state.ctrs.stop_index + 1)
            e1, e2 = state.A[1,1], state.A[2,2]

            if state.ctrs.stop_index == 1
                state.REIGS[1], state.IEIGS[1] = real(e1), imag(e1)
                state.REIGS[2], state.IEIGS[2] = real(e2), imag(e2)
                state.ctrs.stop_index = 0
            else
                state.REIGS[k+1], state.IEIGS[k+1] = real(e2), imag(e2)
                state.ctrs.zero_index = 0
                state.ctrs.start_index = 1
                state.ctrs.stop_index = k - 1
            end
        end
    end

    @warn "Not all roots were found. The first $(state.ctrs.stop_index-1) are missing."
end





## We have ps = [a0, a1, ..., an]
## for QR factorization we need monic (an=1) and then -[a1, a2, ..., an_1, a0, 1]
## This adjusts last two terms by a factor (-1)^N
function basic_decompose(ps::Vector{T}) where {T}
    #    ps, k = deflate_leading_zeros(ps)  ## ASSUMED
    n = length(ps) - 1
    p0, pNi = ps[1], 1/ps[end]
    qs = Vector{T}(undef, n+1) #zeros(T, n+1)
    @inbounds for i in 1:n-1
        qs[i] = -ps[i+1] * pNi
    end

    par = iseven(n) ? one(T) : -one(T)
    qs[n]= par * p0 * pNi
    qs[n+1] = -par * one(T)

    qs
end

## A pencil function takes
## ps = [a0, a1, a2, ..., an] and splits into vs, ws with:
## v1 = a0,
## wn = an, and
## v_{i+1} + w_i = a_i for i-1,2,...,n-1.
##
## This gives matrices:
## V = [0 ....     -v1   W = [1  .... w1
##      1 0 .....  -v2        0 1 ... w2
##      0 1 .....  -v3        0 0 1 . w3
##          .....               .....
##      0 0 .... 1 -vn]       0 ....0 wn]
## V is Hessenberg, W upper triangular.
##
## The default, `basic_pencil`, is
## vs = [a0, a1, ..., a_{n-1}], ws = [0,0,..., an] (minus signs on vs handled internally)
##
function basic_pencil(ps::Vector{T}) where {T}
    N = length(ps)-1

    qs = zeros(T, N)
    qs[N]  = ps[end]

    ps = ps[1:end-1]
    ps, qs

end

## Twisting
## Compute sigma
##
function CMV(ps)
    n = length(ps) - 1
    sigma=vcat(1:2:n, 2:2:n)
    sigma
end
const basic_twist = CMV




## for real like 8e-6 * N^2 run time
##     allocations like c + 3n where c covers others.
## for complex   1e-5 * N^2 run time (1.25 more)
##     allocations like  3n too?
function amvw(ps::Vector{T}) where {T <: Real}
    state = convert(FactorizationType{T, Val{:DoubleShift}, Val{:NoPencil}, Val{:NotTwisted}}, ps)
    init_state(state, basic_decompose)
    state
end

function amvw(ps::Vector{Complex{T}}) where {T <: Real}
    state = convert(FactorizationType{T, Val{:SingleShift}, Val{:NoPencil}, Val{:NotTwisted}}, ps)
    init_state(state, basic_decompose)
    state
end


## decomposition of ps into vs, ws needs to be expanded to work with framework
function adjust_pencil(vs::Vector{T}, ws::Vector{T}) where {T}
    N = length(vs)
    qs = vcat(ws, -one(T))
    par = iseven(N) ? one(T) : -one(T)
    ps = vcat(-vs[2:end], par * vs[1], par*one(T))
    ps, qs
end

function amvw_pencil(ps::Vector{T}, pencil=basic_pencil) where {T <: Real}
    state = convert(FactorizationType{T, Val{:DoubleShift}, Val{:HasPencil}, Val{:NotTwisted}}, ps)
    init_state(state, xs -> adjust_pencil(pencil(xs)...))
    state
end

function amvw_pencil(ps::Vector{Complex{T}}, pencil=basic_pencil) where {T <: Real}
    state = convert(FactorizationType{T, Val{:SingleShift}, Val{:HasPencil}, Val{:NotTwisted}}, ps)
    init_state(state, xs -> adjust_pencil(pencil(xs)...))
    state
end



function amvw_twist(ps::Vector{T}, twist=basic_twist) where {T}
    " XXX .... XXX "
end

function amvw_pencil_twist(ps::Vector{T}, pencil=basic_pencil, twist=basic_twist) where {T}
    " XXX .... XXX "
end

## amvw
"""

Use an algorithm of AMVW to find roots of a polynomial over the reals of complex numbers.

ps: The coefficients [p0, p1, p2, ...., pn] of the polynomial p0 + p1*x + p2*x^2 + ... + pn*x^n

pencil: if given, a function `ps -> (vs, ws)` that balances off the coefficients. It satisfies: vs[1] = p0; ws[end] = pn and vs[i+1] + ws[i] = pi

twist: if given, a function `ps -> sigma` which twists the "Q" matrix. Sigma is a permutation of {1, 2, ..., n-1}. The function `AMVW.CMV` creates the "CMV" pattern.

Examples;
```
using AMVW, Polynomials
p = poly(1.0:12)
ps = coeffs(p)
poly_roots(ps)                                           # use QR algorithm
poly_roots(ps, pencil=AMVW.basic_pencil)                 # use QZ algorithm
poly_roots(ps, twist=AMVW.CMV)                           # use twisted QR algorithm
poly_roots(ps, pencil=AMVW.basic_pencil, twist=AMVW.CMV) # use twisted QZ algorithm
```

References:


"""
function poly_roots(ps::Vector{T}; pencil=nothing, twist=nothing, verbose=false) where {T}
    # deflate 0s
    ps, K = deflate_leading_zeros(ps)

    ## solve simple cases length(ps) = 1, 2, 3
    length(ps) <= 3 && return solve_simple_cases(ps)

    if twist == nothing
        if pencil == nothing
            state = amvw(ps)
        else
            state = amvw_pencil(ps, pencil)
        end
    else
        if pencil == nothing
            state = amvw_twist(ps, twist)
        else
            state = amvw_pencil_twist(ps, pencil, twist)
        end
    end

    AMVW_algorithm(state)

    if K > 0
        ZS = zeros(T, K)
        if T <: Complex
            append!(state.REIGS, real.(ZS))
            append!(state.IEIGS, real.(ZS))
        else
            append!(state.REIGS, ZS)
            append!(state.IEIGS, ZS)
        end
    end

    complex.(state.REIGS, state.IEIGS)
end
