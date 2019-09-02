## Utilities for working with the bases.

"""
    num_vectors(N::Int, K::Int)

Compute the number of vectors in a basis with `N` particles and `K` sites.
"""
num_vectors(N::Int, K::Int) = binomial(N+K-1, K-1)

# Global cache of generalized Pascal's triangles for restricted num_vectors.
const triangles = Dict{Int, Matrix{Int}}()

"""
    num_vectors(N::Int, K::Int, M::Int)

Compute the number of vectors in a basis with `N` particles and `K` sites, and
a limit of `M` particles per site.
"""
function num_vectors(N::Int, K::Int, M::Int)
    0 <= N <= M * K || return 0
    N == K == 0 && return 1

    # Create a new triangle.
    if !haskey(triangles, M)
        triangles[M] = zeros(Int, 1, 1)
        triangles[M][1, 1] = 1
    end

    # Extend an existing triangle.
    if size(triangles[M], 1) < K + 1
        t_old = triangles[M]
        K_old = size(t_old, 1) - 1
        t = zeros(Int, K+1, M*K+1)
        for k in 0:K_old
            for n in 0:(M*k)
                t[k+1, n+1] = t_old[k+1, n+1]
            end
        end
        for k in (K_old+1):K
            for n in 0:(M*k)
                for m in 0:min(M, n)
                    t[k+1, n+1] += t[k, n+1-m]
                end
            end
        end
        triangles[M] = t
    end

    triangles[M][K+1, N+1]
end

"""
    num_vectors(basis::AbstractSzbasis, N::Int, K::Int)

Compute the number of vectors in a basis with `N` particles and `K` sites, and
a limit of as many particles per site as in `basis`.
"""
num_vectors(::Szbasis, N::Int, K::Int) = num_vectors(N, K)
num_vectors(basis::RestrictedSzbasis, N::Int, K::Int) = num_vectors(N, K, basis.M)


"""
    site_max(basis::AbstractSzbasis)

Get the maximum number of particles on a site in `basis`.
"""
site_max(basis::Szbasis) = basis.N
site_max(basis::RestrictedSzbasis) = basis.M


"""
    serial_num(K::Int, N::Int, v::AbstractVector{Int})

Compute the serial number of occupation vector `v` in a basis with `K` sites
and `N` particles.
"""
function serial_num(K::Int, N::Int, v::AbstractVector{Int})
    I = 1

    for mu in 1:K
        s = 0
        for nu in (mu+1):K
            s += v[nu]
        end
        for i in 0:(v[mu]-1)
            I += num_vectors(N-s-i, mu-1)
        end
    end

    I
end

"""
    serial_num(K::Int, N::Int, M::Int, v::AbstractVector{Int})

Compute the serial number of occupation vector `v` in a basis with `K` sites
and `N` particles, and a limit of `M` particles per site.
"""
function serial_num(K::Int, N::Int, M::Int, v::AbstractVector{Int})
    I = 1

    for mu in 1:K
        s = 0
        for nu in (mu+1):K
            s += v[nu]
        end
        for i in 0:(v[mu]-1)
            I += num_vectors(N-s-i, mu-1, M)
        end
    end

    I
end

"""
    serial_num(basis::AbstractSzbasis, v::AbstractVector{Int})

Compute the serial number of occupation vector `v` in `basis`.
"""
serial_num(basis::Szbasis, v::AbstractVector{Int}) = serial_num(basis.K, basis.N, v)
serial_num(basis::RestrictedSzbasis, v::AbstractVector{Int}) = serial_num(basis.K, basis.N, basis.M, v)

"""
    serial_num(basis::AbstractSzbasis, K::Int, N::Int, v::AbstractVector{Int})

Compute the serial number of occupation vector `v` in a basis with `N`
particles and `K` sites, and a limit of as many particles per site as in
`basis`.
"""
serial_num(::Szbasis, K::Int, N::Int, v::AbstractVector{Int}) = serial_num(K, N, v)
serial_num(basis::RestrictedSzbasis, K::Int, N::Int, v::AbstractVector{Int}) = serial_num(K, N, basis.M, v)


"""
    sub_serial_num(basis::AbstractSzbasis, v::AbstractVector{Int})

Compute the serial number of the reduced occupation vector `v`, which has only
a subset of the sites present in `basis`.
"""
function sub_serial_num(::Szbasis, v::AbstractVector{Int})
    K = length(v)
    N = sum(v)

    # Only one way to have no sites.
    K >= 1 || return 1
    # Only one way to have no particles.
    N >= 1 || return 1

    # Count the zero-particle case.
    I = 1

    for n in 1:(N-1)
        I += num_vectors(n, K)
    end

    I + serial_num(K, N, v)
end

function sub_serial_num(basis::RestrictedSzbasis, v::AbstractVector{Int})
    K = length(v)
    N = sum(v)

    # Only one way to have no sites.
    K >= 1 || return 1
    # Only one way to have no particles.
    N >= 1 || return 1

    # Count the zero-particle case.
    I = 1

    for n in 1:(N-1)
        I += num_vectors(n, K, basis.M)
    end

    I + serial_num(K, N, basis.M, v)
end
