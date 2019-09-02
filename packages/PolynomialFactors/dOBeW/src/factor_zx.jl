
## Factor over Z[x]
## big prime

# Algo 15.2
# f is square free
function factor_Zx_big_prime_squarefree(f)
    n = degree(f)
    n == 1 && return f

    A = maxnorm(f)
    b = value(lead(f))

    # we use BigInt for p, B if we need to
    lambda = log(typemax(Int)/(4*A*b))/(1/2 + log(2))
    if n < -1 #lambda
        p = 0
        B = floor(Int, sqrt(n+1)*big(2)^n*big(A)*b)
    else
        p = big(0)
        B = floor(BigInt, sqrt(n+1)*big(2)^n*big(A)*b)
    end
    while true
        p = Primes.nextprime(rand(2B:4B))
        g = gcd(as_poly_Zp(f, p, "x"), as_poly_Zp(derivative(f), p, "x"))
        isone(g) && break
    end

    fZp = as_poly_Zp(f, p, "x")
    fZp = fZp * inv(lead(fZp))


    d = factor_Zp_squarefree(fZp, p, variable(fZp))
    gs = collect(keys(d))

    R,x = ZZ["x"] # big?
    Gs = as_poly.(poly_coeffs.(gs), x)

    _factor_combinations(f, Gs, p, 1, x, b, B)


end

##################################################

# algo 15.10
# g, h rel prime
# lifts f,g,h,s,t over F_m to values in F_m^2
function hensel_step(f, g, h, s, t, m)
    # f, g, h,s, t are in Z[x]

    isone(lead(h)) || error("h must be monic")
    degree(f) == degree(g) + degree(h) || error("degree(f) != degree(g) + degree(h)")
    degree(s) < degree(h) && degree(t) < degree(g) || error("degree(s) !< degree(h) or degree(t) !< degree(g)")


    e = as_poly_modp(as_poly(f) - as_poly(g) * as_poly(h), m^2)
    f, g, h, s, t = as_poly_modp.((f,g,h,s,t), m^2)
    q, r = divrem(s*e, h)

    gstar = g + t * e + q * g
    hstar = h + r

    b = s*gstar + t * hstar - one(t)
    c, d = divrem(s * b, hstar)

    sstar = s - d
    tstar = t - t*b - c*gstar


    iszero(f - gstar * hstar) || error("f != g^* * h^* mod m^2")
#    isone(sstar * tstar + tstar * hstar) || error("st + th != 1 mod m^2")



    as_poly.((gstar, hstar, sstar, tstar))
end


# collect factors into a tree for apply HenselStep
abstract type AbstractFactorTree end

mutable struct FactorTree <: AbstractFactorTree
    fg
    children
    s
    t
    FactorTree(fg) = new(fg, Any[])
end

mutable struct FactorTree_over_Zp <: AbstractFactorTree
    fg
    children
    s
    t
    FactorTree_over_Zp(fg, p) = new(fg, Any[])
end

function make_factor_tree_over_Zp(f, fs, p) # fs factors over Zp
    N = length(fs)
    n = ceil(Int, log2(N))
    tau = FactorTree(f)
    N == 1 && return tau

    k = 2^(n-1)
    fls = fs[1:k]
    fl = prod(as_poly.(fls))
    frs = fs[(k+1):end]
    fr = prod(as_poly.(frs))


    l, r = tau.children = Any[make_factor_tree_over_Zp(fl, fls, p),
                              make_factor_tree_over_Zp(fr, frs, p)]
    g, s, t = gcdx(as_poly_Zp(l.fg,p), as_poly_Zp(r.fg,p))

    gi = invmod(value(coeff(g, 0)), p)
    tau.s = as_poly(gi*s); tau.t = as_poly(gi*t)
    tau
end


function hensel_step_update_factor_tree!(tau, p)
    !has_children(tau) && return
    l,r = tau.children
    f, g,h,s,t = tau.fg, l.fg, r.fg, tau.s, tau.t

    g1,h1,s1,t1 = hensel_step(f, g, h, s, t, p)

    tau.s, tau.t = s1, t1
    l.fg, r.fg = g1, h1

    hensel_step_update_factor_tree!(l, p)
    hensel_step_update_factor_tree!(r, p)
end

has_children(tau::AbstractFactorTree) = length(tau.children) == 2

function all_children(tau::AbstractFactorTree)
   has_children(tau) ? vcat(all_children(tau.children[1]), all_children(tau.children[2])) : [tau.fg]
end


"""

Algo 15.17 multifactor Hensel lifting

"""
function hensel_lift(f, facs, m::T, a0, l) where {T}

    tau = make_factor_tree_over_Zp(f, facs, m)

    d = ceil(Int, log2(l))
    for j = 1:d
        a0 = mod(2*a0 - lead(f) * a0^2, m^2^j)
        tau.fg = a0 * f
        hensel_step_update_factor_tree!(tau, m^2^(j-1))
    end

    tau
end

# factor square free poly in Z[x] using hensel lifting techique
# can resolve factors of p^l using brute force or LLL algorith (which is
# not as competitive here)
# Could rewrite latter to use floating point numbers (http://perso.ens-lyon.fr/damien.stehle/downloads/LLL25.pdf)
function factor_Zx_prime_power_squarefree(f,lll=false)

    n = degree(f)

    n == 1 && return (f,)

    A = big(maxnorm(f))
    b = abs(value(lead(f)))

    B = sqrt(n+1)*big(2)^n * A * b
    C = big(n+1)^(2n) * A^(2n-1)

    gamma = 2*log2(C) + 1

    # hack to try and factor_Zp over small prime if possible
    #
    gb = 2 * gamma*log(gamma)
    if gb < (typemax(Int))^(1/10)
        gamma_bound = floor(Int, gb)
    else
        gamma_bound = floor(BigInt, gb)
    end

    gamma_bound_lower = floor(BigInt, sqrt(gb))



    fs = poly_coeffs(f)


    ## find p to factor over.
    ## for lower degree polynomials we choose more than 1 p, and select
    ## that with the fewest factors over Zp.
    ## This trades of more time factoring for less time resolving the factors

    p, l = zero(gamma_bound), 0
    fbar = f # not type stable, but can't be, as cycle through GF(p)["x"]
    hs = nothing

    P, M = 0, Inf
    for k in 1:(max(0,3-div(n,15)) + 1)

        while true
            P = Primes.prevprime(rand(gamma_bound_lower:gamma_bound))
            iszero(mod(b, P)) && continue
            fbar = as_poly_Zp(fs, P, "x")
            isone(gcd(fbar, derivative(fbar))) && break
        end

        L = floor(Int, log(P, 2B+1))
        d = factor_Zp(fbar, P)

        # modular factorization
        ds = collect(keys(d))
        nfacs = length(ds)

        if nfacs < M
            p = P
            l = L
            hs = ds
            M = nfacs
        end

    end

    # hensel lifting
    a = invmod(b, p)
    # set  up factor tree

    tau = make_factor_tree_over_Zp(f, hs, p)
    # use 15.17 to lift f = b * g1 ... gr mod p^l, gi = hi mod p
    d = ceil(Int, log2(1+l))
    for j = 1:d
        a = mod(2*a - lead(f) * a^2, p^2^j)
        tau.fg = a * f
        hensel_step_update_factor_tree!(tau, p^2^(j-1))
    end

    hs = all_children(tau)

    if lll
        # slower, and not quite right
        identify_factors_lll(f, hs, p, 2^d, b, B)
    else
        x = variable(hs[1])
        _factor_combinations(f, hs, p, 2^d, x, b, B)
    end


end


"""
Division algorithm for Z[x]

returns q,r with

* `a = q*b + r`
* `degree(r) < degree(b)`

If no such q and r can be found, then both `q` and `r` are 0.

"""
function exact_divrem(a, b)
    f,g = a, b
    x = variable(g)
    q, r = zero(f), f

    while degree(r) >= degree(g)
        u, v = divrem(lead(r), lead(g))
        v != 0 && return zero(a), zero(a)
        term = u * x^(degree(r) - degree(g))
        q = q + term
        r = r - term * g
    end
    (q, r)
end

# a = b^k c, return (c, k)
function deflate(a, b)
    k = 0
    while degree(a) >= degree(b)
        c, r = exact_divrem(a, b)
        iszero(c) && return(a, k)
        !iszero(r) && return (a, k)
        k += 1
        a = c
    end
    return (a, k)
end

## f in Z[x]
## find square free
## return fsq, g where fsq * g = f
function square_free(f)
    degree(f) <= 1 && return f

    g = gcd(f, derivative(f))
    d = degree(g)

    if  d > 0
        fsq = divexact(f, g) #faster than exact_divrem if r=0 is known
    else
        fsq = f
    end
    fsq, g
end

##################################################
### Resolve factors over F_p^l

# Brute force method
# f has factors G over Fp^l
function _factor_combinations(f, Gs, p, l, x, b, B)
    r = length(Gs)
    q = p^l

    r == 1 && return (as_poly(as_poly_modp(b*Gs[1],q,x)), )

    for s in 1:(r ÷ 2)
        for inds in Combinatorics.combinations(1:r, s)
            _inds = setdiff(1:r, inds)
            _gstar, _hstar = one(x), one(x)
            for i in inds
                _gstar *= Gs[i]
            end
            for j in _inds
                _hstar *= Gs[j]
            end
            gstar, hstar = as_poly.(as_poly_modp.((b*_gstar, b*_hstar), q))

            if onenorm(gstar) * onenorm(hstar) <= B
                Gs = Gs[_inds]
                f = as_poly(primpart(hstar))
                b = value(lead(f))
                return (primpart(gstar), _factor_combinations(f, Gs, p, l, x, b, B)...)
            end
        end
    end

    return (as_poly(as_poly_modp(b*prod(Gs),p)), )


end


### Interfaces

function poly_factor(f::AbstractAlgebra.Generic.Poly{Rational{T}}) where {T <: Integer}
    x, qs = variable(f), poly_coeffs(f)
    common_denom = lcm(denominator.(qs))
    fs = numerator.(common_denom * qs)
    fz = as_poly(fs)

    U = poly_factor(fz)
    V = Dict{typeof(f), Int}()
    for (k,v) in U
        j = as_poly(poly_coeffs(k), x)
        V[j] = v
    end
    a = 1//common_denom * one(f)
    if !isone(a)
        d = filter(kv -> degree(kv[1]) == 0, V)
        if length(d) == 0
            V[a] = 1
        else
            k,v = first(d)
            V[k*a] = 1
            delete!(V, k)
        end
    end
    V
end

function poly_factor(f::AbstractAlgebra.Generic.Poly{T}) where {T <: Integer}

    # want content free poly with positive leading coefficient
    degree(f) < 0 && return Dict(f=>1)
    c, pp = content(f), primpart(f)
    if sign(lead(f)) < 0
        c,f,pp = -c, -f, -pp
    end

    if degree(f) == 1
        isone(c) && return Dict(f=>1)
        return Dict(c * one(f)=>1, pp=>1)
    end

    fsq, g = square_free(pp)
    fs = factor_Zx_prime_power_squarefree(fsq)

    # get factors
    U = Dict(u=>1 for u in fs)
    if !isone(c)
        U[c*one(f)] = 1
    end

    # get multiplicities
    for u in fs
        g, k = deflate(g, u)
        if k > 0
            U[u] += k
        end
        degree(g) <= 0 && break
    end

    U

end

# an iterable yielding a0,a1, ..., an
# ? How wide a type signature do we want here
function poly_factor(f::Function)
    z = f(0)
    if isa(z, Rational)
        R,x = QQ["x"]
    elseif isa(z, Integer)
        R,x = ZZ["x"]
    else
        error("f(x) is not in ZZ[x] or QQ[x]")
    end

    poly_factor(f(x))
end
poly_factor(as) = poly_factor(as_poly(as))
