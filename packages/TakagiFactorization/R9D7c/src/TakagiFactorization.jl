module TakagiFactorization

using LinearAlgebra

import Base.showerror

export takagi_factor!, takagi_factor, ConvergenceError

function takagi_factor(
    A :: AbstractArray{Complex{T}, 2};
    sort = 0,
    maxsweeps = 50,
    enforce_symmetric = true
) where {T <: AbstractFloat}
    if enforce_symmetric && !issymmetric(A)
        throw(ArgumentError("A must be a symmetric complex matrix"))
    end
    U = zeros(Complex{T}, size(A))
    d = zeros(T, size(A, 1))
    takagi_factor!(copy(A), d, U; sort=sort, maxsweeps=maxsweeps)
    Diagonal(d), U
end

struct ConvergenceError <: Exception
    msg :: String
end

Base.showerror(io::IO, e::ConvergenceError) = print(io, e.msg)

function takagi_factor!(
    A :: AbstractArray{Complex{T}, 2},
    d :: AbstractArray{T, 1},
    U :: AbstractArray{Complex{T}, 2};
    sort = 0,
    maxsweeps = 50
) where {T <: AbstractFloat}

    n = size(A, 1)
    if size(A, 2) ≠ n
        throw(ArgumentError("A must be a square matrix"))
    end
    if size(U) ≠ size(A)
        throw(ArgumentError("U must be a square matrix with the same dimensions as A"))
    end
    if size(d, 1) ≠ n
        throw(ArgumentError("d must have length n for a n×n matrix A"))
    end
    if n < 2
        throw(ArgumentError("A must be at least 2×2"))
    end
    ev = zeros(Complex{T}, 2, n)

    for p in 1:n
        ev[1,p] = zero(T)
        ev[2,p] = A[p,p]
    end

    fill!(U, zero(T))
    for p in 1:n
        U[p,p] = one(T)
    end

    red = T(0.04) / n^4

    done = false
    nsweeps = 0
    while !done && (nsweeps += 1) ≤ maxsweeps

        off = sum(abs2(A[p,q]) for q in 2:n for p in 1:q-1)
        if off ≤ sym_eps(T)
            done = true
            continue
        end

        thresh = (nsweeps < 4) ? off*red : zero(T)

        for q in 2:n
            for p in 1:q-1
                off = abs2(A[p,q])
                sqp = abs2(ev[2,p])
                sqq = abs2(ev[2,q])
                if nsweeps > 4 && off < sym_eps(T)*(sqp+sqq)
                    A[p,q] = zero(T)
                elseif off > thresh
                    t = abs(sqp-sqq) / 2
                    f = if t > eps(T)
                        sign(sqp-sqq) * (ev[2,q]*A[p,q]' + ev[2,p]'*A[p,q])
                    else
                        (sqp == 0) ? one(T) : √(ev[2,q]/ev[2,p])
                    end
                    t += √(t^2 + abs2(f))
                    f /= t

                    ev[2,p] = A[p,p] + (ev[1,p] += A[p,q]*f')
                    ev[2,q] = A[q,q] + (ev[1,q] -= A[p,q]*f )

                    t = abs2(f)
                    c⁻¹ = √(t + 1)
                    f /= c⁻¹
                    t /= c⁻¹*(c⁻¹+1)

                    for j in 1:p-1
                        x = A[j,p]
                        y = A[j,q]
                        A[j,p] = x + (f'*y - t*x)
                        A[j,q] = y - (f*x + t*y)
                    end

                    for j in p+1:q-1
                        x = A[p,j]
                        y = A[j,q]
                        A[p,j] = x + (f'*y - t*x)
                        A[j,q] = y - (f*x + t*y)
                    end

                    for j in q+1:n
                        x = A[p,j]
                        y = A[q,j]
                        A[p,j] = x + (f'*y - t*x)
                        A[q,j] = y - (f*x + t*y)
                    end

                    A[p,q] = zero(T)

                    for j in 1:n
                        x = U[p,j]
                        y = U[q,j]
                        U[p,j] = x + (f*y - t*x)
                        U[q,j] = y - (f'*x + t*y)
                    end
                end # elseif off > thresh
            end # for p in 1:q
        end # for q in 2:n

        for p in 1:n
            ev[1,p] = zero(T)
            A[p,p] = ev[2,p]
        end
    end # for nsweeps in 1:maxsweeps

    if !done
        throw(ConvergenceError("Bad convergence in takagi_factor!"))
    else
        # Make the diagonal elements non-negative
        for p in 1:n
            # d[p] = abs(A[p,p])
            # if d[p] > eps(T) && d[p] ≠ real(A[p,p])
            #     U[:,p] .*= √(A[p,p]/d[p])
            # end
            d[p] = abs(A[p,p])
            if d[p] > eps(T) && d[p] ≠ real(A[p,p])
                f = √(A[p,p]/d[p])
                for q in 1:n
                    U[p,q] *= f
                end
            end
        end

        if sort ≠ 0
            # Sort the eigenvalues
            for p in 1:n-1
                j = p
                t = d[p]
                for q in p+1:n
                    if sort*(t-d[q]) > 0
                        j = q
                        t = d[q]
                    end

                    if j ≠ p
                        d[j] = d[p]
                        d[p] = t
                        for q in 1:n
                            x = U[p,q]
                            U[p,q] = U[j,q]
                            U[j,q] = x
                        end
                    end # if j ≠ p
                end # for q in p+2:n
            end # for p in 1:n-1
        end # if sort ≠ 0
    end
end

sq_eps(x)  = 4*eps(x)^2
sym_eps(x) = 2*eps(x)^2

end # module
