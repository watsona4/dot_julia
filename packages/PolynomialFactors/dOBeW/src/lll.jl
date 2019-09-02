### LLL method

### f = prod(fs) over Zp, find factors over Z
function mu(i,j,B,Bs)
    dot(B[i,:], Bs[j,:]) // dot(Bs[j,:], Bs[j,:] )
end
function swaprows!(A, i, j, tmp)
    tmp[:] = A[i,:]
    A[i,:] = A[j,:]
    A[j,:] = tmp
    nothing
end


function _reduce(i, T, B, U)
    j = i - 1
    while j > 0
        rij = round(T, digits=U[i,j])
        B[i,:] -= rij * B[j, :]
        U[i,:] -= rij * U[j, :]
        j -= 1
    end
end

# Find a short vector for B = [f1;f2;...;fn]
# short vector if f1 after the work is done
# http://algo.epfl.ch/_media/en/projects/bachelor_semester/rapportetiennehelfer.pdf .
# Algo 2
function LLL_basis_reduction!(B::Matrix{T}, c=4//3) where {T <: Integer} # c > 4/3

    m, n = size(B)

    Bstar =  Matrix{Rational{T}}(I, m, m)
    U = Matrix{Rational{T}}(I, m, m)

    tmpZ = zeros(T, 1, m)
    tmpQ = zeros(Rational{T}, 1, m)


    ONE, ZERO = one(Rational{T}), zero(Rational{T})

    ## initialize Bstar, U
    Bstar[1,:] = B[1,:]  # b^*_1 = b_1
    for i in 2:n
        Bstar[i,:] = B[i,:]
        for j in 1:(i-1)
            U[i,j] = mu(i,j,B,Bstar) #vecdot(bi, bstar_j) // vecdot(bstar_j, bstar_j)
            Bstar[i,:] -= U[i,j] * Bstar[j,:]
        end

        _reduce(i, T, B, U)
    end

    i = 1
    while i < m
        if norm(B[i,:],2) < c * norm(B[i+1,:],2)
            i += 1
        else
            # Modify Q and R in order to keep the relation B = QR after the swapping
            Bstar[i+1, :] += U[i+1,i] * Bstar[i, :]

            U[i, i] = mu(i, i+1, B, Bstar)
            U[i, i+1] = U[i+1, i] = ONE
            U[i+1, i+1] = ZERO

            Bstar[i, :] -= U[i,i] * Bstar[i+1, :]

            swaprows!(U, i, i+1, tmpQ)
            swaprows!(Bstar, i, i+1, tmpQ)
            swaprows!(B, i, i+1, tmpZ)

            for k in (i+2):m
                U[k,i] = mu(k, i, B, Bstar)
                U[k,i+1] = mu(k, i+1, B, Bstar)
            end

            if abs(U[i+1,i]) > 1//2
                _reduce(i+1, T, B, U)
            end
            i = max(i-1, 1)
        end
    end
end




## For a polynomial p, create a lattice of p, xp, x^2p, ... then find a short vector.
## This will be a potential factor of f
function short_vector(u::AbstractAlgebra.Generic.Poly, m, j, d)
    us = poly_coeffs(u)
    T = eltype(us)
    F = zeros(T, j, j)

    # coefficients of us*x^i
    for i in 0:(j-d-1)
        F[1 + i, (1 + i):(1+i+d)] = us
    end
    # coefficients of mx^i
    for i in 0:(d-1)
        F[1 + j - d + i, 1 + i] = m
    end

    LLL_basis_reduction!(F)
    x = variable(u)
    # short vector is first row
    as_poly(vec(F[1,:]), x)
end


## u is a factor over Zp
## we identify irreducible gstar of f
## return gstar, fstar = f / gstar (basically), and reduced Ts
function identify_factor(u::AbstractAlgebra.Generic.Poly, fstar::AbstractAlgebra.Generic.Poly, Ts::Vector, p::T, l, b, B) where {T}

    d, nstar = degree(u), degree(fstar)
    d < nstar || throw(DomainError())
    m = p^l
    j = d + 1
    gstar = u
    Tsp = as_poly_Zp.(Ts, p)

    while j <= nstar+1
        gstar = short_vector(u,m,j,d)

        gstarp = as_poly_Zp(gstar, p)
        inds = Int[]
        for (i,t) in enumerate(Tsp)
            divides(gstarp, Tsp[i])[1] && push!(inds, i)  # allocates
        end


        notinds = setdiff(1:length(Ts), inds)
        Ssp = Tsp[notinds]

        # find hstar = prod(Ts)
        hstar = as_poly(mod(b, m) * (isempty(Ssp) ? one(gstarp) : prod(Ssp)))

        pd = onenorm(primpart(gstar)) * onenorm(primpart(hstar))

        if pd < B
            gstar, hstar = primpart(gstar), primpart(hstar)
            Ts = Ts[notinds] # modify Ts (Ts[:])or make a copy?
            fstar = primpart(hstar)
            break
        end
        j = j + 1
    end

    primpart(gstar), fstar, Ts
end

"""
Use LLL basis reduction to identify factors of square free f from its factors over Zp
"""
function identify_factors_lll(f, facs, p, l, b, B)

    Ts = sort(facs, by=degree, rev=true)

    Gs = similar(Ts, 0)
    fstar = primpart(f)
    m = p^l


    while length(Ts) > 0
        u = popfirst!(Ts)
        if length(Ts) == 0
            push!(Gs, fstar)
            break
        end
        if degree(fstar) == degree(u)
             push!(Gs, fstar)
            break
        end
        #        return (u, fstar, Ts, p, l, b, B)
        gstar, fstar, Ts = identify_factor(u, fstar, Ts, p, l, b, B)
        push!(Gs, gstar)
    end
    Gs
end
