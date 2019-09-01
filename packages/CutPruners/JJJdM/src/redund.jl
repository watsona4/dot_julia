function normalizedcut(A::AbstractMatrix{T}, b::AbstractVector{T}, k::Int, 
                        isfun::Bool, tol::Float64) where {T}
    a = @view A[k, :]
    β = b[k]
    na = norm(a, 2)
    if isfun || na < tol
        a, β
    else
        a / na, β / na
    end
end

"""
    checkredundancy{T}(A::AbstractMatrix{T}, b::AbstractVector{T},
                       Anew::AbstractMatrix{T}, bnew::AbstractVector{T},
                       isfun::Bool, islb::Bool, tol::Float64, ident::Bool=false)

Check redundant cuts between the Polyhedra (A,b) and (Anew, bnew).
Return index of redundant cuts in `Anew`.

# Arguments
* `isfun::Bool`
    States if the Polyhedra defines a function
* `islb::Bool`
    States if the Polyhedra is a lower-bound or an upper-bound
* `tol::Float64`
    Tolerance of redundancy check
* `ident::Bool`
    States whether (A,b)==(Anew,bnew) if we want to remove redundant
    lines in a single Polyhedra

"""
function checkredundancy(A::AbstractMatrix{T}, b::AbstractVector{T},
                            Anew::AbstractMatrix{T}, bnew::AbstractVector{T},
                            isfun::Bool, islb::Bool, tol::Float64, 
                            ident::Bool=false) where {T}
    # index of redundants cuts
    redundants = Int[]
    # number of new lines
    nnew = size(Anew, 1)

    for kk in 1:nnew
        a, β = normalizedcut(Anew, bnew, kk, isfun, tol)
        chk, indk = isinside(A, b, a, isfun, tol)
        # if ident is true, we need to take care of the possible match
        # of the cut a with itself in the matrix Anew
        if chk && (~ident || indk!=kk)
            ared, βred = normalizedcut(A, b, indk, isfun, tol)
            if islb ? β <= βred+tol : β+tol >= βred
                push!(redundants, kk)
            end
        end
    end

    redundants
end


"""Check if `λ` is a line of matrix `A`. `λ` might not have the same `eltype`
as `A` and `b` as it might have been scaled by `normalizecut`."""
function isinside(A::AbstractMatrix{T}, b::AbstractVector{T},
                     λ::AbstractVector, isfun::Bool, tol::Float64) where {T}
    nlines = size(A, 1)

    check = false
    k = 0
    while ~check && k < nlines
        k += 1
        a, β = normalizedcut(A, b, k, isfun, tol)
        check = (norm(a - λ, Inf) < tol)
    end
    check, k
end


checkredundancy(A, b, isfun, islb, tol)=checkredundancy(A, b, A, b, isfun, islb, tol, true)
