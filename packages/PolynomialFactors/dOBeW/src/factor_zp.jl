### factor_Zp code

## 14.3
## f in Zq[x]
## return g1, g2, ..., gs: g) is product of all monic irreducible polys in Fq[x] of degree i that divide f
function distinct_degree_factorization(f, q, x=gen(parent(f)))
    degree(f) > 0 || error("f is a constant poly")
    
    h, f0, i = x, f, 0
    gs = eltype(f)[]
    while true
        i += 1
        h = _powermod(h, q, f0)
        g = gcd(h - x, f)
        f = divexact(f, g)
        push!(gs, g)
        if degree(f) < 2(i+1)
            push!(gs, f)
            break
        end
    end
    gs
end


function _equal_degree_splitting(f::AbstractAlgebra.Generic.Poly{AbstractAlgebra.gfelem{T}}, q, x, d) where {T}
    n = degree(f)
    n <= 1 && return (f, false)

    # random poly of degree < n
    a = sum(convert(T, rand(0:(q-1))) * x^i for i in 0:(n-1))
    degree(a) <= 0 && return (f, false)

    g1 = gcd(a, f)
    !isone(g1) && return (g1, true)

    b = _powermod(a, (q^d-1) ÷ 2, f)
    g2 = gcd(b-1, f)
    
    !isone(g2) && g2 != f && return (g2, true)

    return (f, false)
end

# Algo 14.8
# f square free, monic in Fq[x]
# q odd prime power
# d divides n, all irreducible factors of f have degree d
# this calls _equal_degree_splitting which has probability 2^(1-r) of success
# returns a proper monic factor (g,true) or (f,false)
function equal_degree_splitting(f, q, x, d)
    K = 50
    while K > 0
        g, val = _equal_degree_splitting(f, q, x, d)
        val && return (g, true)
        K -= 1
    end
    return (f, false)
end
    


# f square free in F_q[x]
# d divides degree(f)
# all irreducible factors of f have degree d
# return all monic factors of f in F_q[x]
function equal_degree_factorization(f, q, x, d)
    degree(f) == 0 && return (f, )
    degree(f) == d && return (f, )
    g, val = equal_degree_splitting(f, q, x, d)

    if val
        return tuplejoin(equal_degree_factorization(g, q, x, d),
                         equal_degree_factorization(divexact(f, g), q, x, d))
    else
        return (f,)
    end
end

# Cantor Zazzenhaus factoring of a polynomial of Zp[x]
# Algorithm 14.13 from von Zur Gathen and Gerhard, Modern Computer Algebra v1, 1999
# f in Zq[x], q prime
function factor_Zp(f, q, x=variable(f))

    h = x
    v = f * inv(lead(f)) # monic
    i = 0
    U = Dict{typeof(f), Int}()

    while true
        i += 1
        h = _powermod(h, q, f)
        g = gcd(h - x, v)

        if !isone(g)
            gs = equal_degree_factorization(g, q, x, i)
            for (j,gj) in enumerate(gs)
                e = 0
                while true
                    qu,re = divrem(v, gj)
                    if iszero(re)
                        v = qu
                        e += 1
                    else
                        break
                    end
                end
                U[gj] = e
            end
        end
        isone(v) && break
    end
    U
end


# slightly faster?
# this saves a `divrem` per factor
function factor_Zp_squarefree(f, q, x=variable(f))
    h = x
    v = f * inv(lead(f)) # monic
    i = 0

    facs = typeof(f)[]
    while true
        i += 1
        h = _powermod(h, q, f)
        g = gcd(h - x, v)

        if !isone(g)
            gs = equal_degree_factorization(g, q, x, i)
            for (j,gj) in enumerate(gs)
                qu,re = divrem(v, gj)
                if iszero(re)
                    push!(facs, gj)
                    v = qu
                end
            end
        end
        isone(v) && break
    end
    facs
end

function factormod(f::AbstractAlgebra.Generic.Poly{T}, p::Integer) where {T <: Integer}
    x = string(var(parent(f)))
    fp = as_poly_Zp(f, p, x)
    c = lead(fp)
    fp = fp * inv(c)
    us = factor_Zp(fp, p)
    if !isone(c)
        us[c*one(fp)] = 1
    end
    us
end

function factormod(fs::Vector{T}, p::Integer) where {T <: Integer}
    f = as_poly_Zp(fs, p, "x")
    factor_Zp(fp, p)
end

