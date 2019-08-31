
"""
Prepares the triangulation for a discrete approximation of the Markov matrix.
Creates alternative representations of the simplices that allow for efficient
(mostly non-allocating) checking if a point lies inside a simplex.
"""
function prepare_for_discrete_approx(t::AbstractTriangulation)

    n_simplices = size(t.simplex_inds, 1)
    n_vertices = size(t.simplex_inds, 2)
    dim = n_vertices - 1

    # The [:, j, i] th entry of these two arrays holds the jth vertex of the
    # ith simplex, but instead of having just `dim` vertices, we append a `1`
    # to the end of the vectors. This allows for efficent (non-allocating)
    # computation within the `contains_point_lessalloc!` function. If we instead
    # would have appended the 1's inside that function, we would be performing
    # memory-allocating operations, which are very expensive. Doing this instead
    # gives orders of magnitude speed-ups for sufficiently large triangulations.
    S1 = Array{Float64}(undef, dim + 1, dim + 1, n_simplices)
    IS1 = Array{Float64}(undef, dim + 1, dim + 1, n_simplices)

    # Collect simplices in the form of (dim+1)^2-length column vectors. This
    # also helps with the
    simplices = Size((dim+1)^2, n_simplices)(zeros((dim+1)^2, n_simplices))
    imsimplices = Size((dim+1)^2, n_simplices)(zeros((dim+1)^2, n_simplices))

    @inbounds for i in 1:n_simplices
        for j in 1:n_vertices
            S1[:, j, i] = vcat(t.points[t.simplex_inds[i, j], :], 1.0)
            IS1[:, j, i] = vcat(t.impoints[t.simplex_inds[i, j], :], 1.0)
        end

        simplices[:, i] = reshape(S1[:, :, i], (dim+1)^2)
        imsimplices[:, i] = reshape(IS1[:, :, i], (dim+1)^2)
    end

    return simplices, imsimplices
end

@inline function rezero!(a)
    @inbounds for i in eachindex(a)
        a[i] = 0.0
    end
end

@inline function fill_into!(into, from)
    @inbounds for i in eachindex(into)
        into[i] = from[i]
    end
end

@inline function fill_at_inds!(into, from, inds)
    @inbounds for i in 1:length(inds)
        into[inds[i]] = from[i]
    end
end

function contained!(signs, s_arr, sx, point, dim)
    # Redefine the temporary simplex. This is in-place, so we don't allocate
    # memory. We could also have re-initialised `signs`, but since we're never
    # comparing more than two consecutive signs, this is not necessary.
    rezero!(s_arr)
    rezero!(signs)
    fill_into!(s_arr, sx)

    #Replace first vertex with the point
    fill_at_inds!(s_arr, point, 1:dim)

    # Signed volume
    signs[1] = sign(det(reshape(s_arr, dim + 1, dim + 1)))

    rezero!(s_arr)
    fill_into!(s_arr, sx) #reset

    for κ = 2:dim # Check remaining signs and stop if sign changes
        # Replace the ith vertex with the point we're cheking (leaving the
        # 1 appended to Vi intact.)
        idxs = ((dim + 1)*(κ - 1)+1):((dim + 1)*(κ - 1)+ 1 + dim - 1)
        fill_at_inds!(s_arr, point, idxs) # ith change

        signs[κ] = sign(det(reshape(s_arr, dim + 1, dim + 1)))

        if !(signs[κ-1] == signs[κ])
            return false
        end

        rezero!(s_arr)
        fill_into!(s_arr, sx)
    end

    # Last the last vertex with the point in question
    idxs = ((dim + 1)*(dim)+1):((dim+1)^2-1)
    fill_at_inds!(s_arr, point, idxs)

    signs[end] = sign(det(reshape(s_arr, dim + 1, dim + 1)))

    if !(signs[end-1] == signs[end])
       return false
    else
        return true
    end
end

function innerloop!(inds::Vector{Int}, signs, s_arr, Sj, pt, dim::Int, M, i::Int)
    for j in 1:length(inds)
        if contained!(signs, s_arr, Sj[j], pt, dim)
            M[inds[j], i] += 1.0
        end
    end
end

function get_simplices_at_inds!(simps, inds::Vector{Int}, simplices)
    for i in 1:length(inds)
        simps[i] = simplices[:, inds[i]]
    end
end

"""
    transferoperator_approx(t::Triangulation;
                        n_pts::Int = 200,
                        sample_randomly::Bool = false)

Estimates the Perron Frobenius operator (Transfer operator) from a simplex-based
partitioning of the state space.

## Transition probabilities
Calculates transition probabilities between volumes based on approximate
intersections between the simplices. This is done by approximating simplices
as a distribution of minimum `n_pts` points contained inside each simplex.
The actual number of points used may be slightly higher.

The default number of points (`n_pts = 200`) usually gives a maximum error
in the entries of the transfer operator of < 10%.

## Subsampling the simplices
By default, points are distributed regularly inside simplices
according to a shape-preserving simplex splitting. Points can also be
distributed according to a uniform distribution by setting
`sample_randomly = true`, but this decreases accuracy and is not recommended.

"""
function transferoperator_approx(t::AbstractTriangulation;
                            n_pts::Int = 200,
                            sample_randomly::Bool = false)

    # Some constants used throughout the funciton
    n_simplices::Int = size(t.simplex_inds, 1)
    dim = size(t.points, 2)

    #=
    # Prepare memory-efficient representations of the simplices, and the convex
    # coefficients needed to generate points.
    =#
    simplices, imsimplices = prepare_for_discrete_approx(t)

    convex_coeffs = subsample_coeffs(dim, n_pts, sample_randomly)
    #=
    # update number of points in case a regular grid of points was employed
    # (if so, because the number of subsimplices generated by the
    # shape-preserving splitting depends only on the dimension of the space,
    # there will be more points than we asked for).
    =#

    n_coeffs::Int = size(convex_coeffs, 2)

    # Pre-allocated arrays (SizedArrays, for efficiency)
    pt          = Size(1, dim)(zeros(Float64, 1, dim))
    s_arr       = Size((dim+1)^2)(zeros(Float64, (dim+1)^2))
    signs       = Size(dim + 1)(zeros(Float64, dim + 1))

    # Re-arrange simplices so that look-up is a bit more efficient
    simplex_arrs = Vector{Array{Float64, 2}}(undef, n_simplices)
    imsimplex_arrs = Vector{Array{Float64, 2}}(undef, n_simplices)
    for i in 1:n_simplices
        simplex_arrs[i] = t.points[t.simplex_inds[i, :], :]
        imsimplex_arrs[i] = t.impoints[t.simplex_inds[i, :], :]
    end

    # The Markov matrix
    M = zeros(Float64, n_simplices, n_simplices)

    for i in 1:n_simplices
        inds::Vector{Int} = maybeintersecting_simplices(t, i)
        Sj = Vector{AbstractArray}(undef, length(inds))
        get_simplices_at_inds!(Sj, inds, simplices)

        @views is = imsimplex_arrs[i]

        for k in 1:n_coeffs
            @! pt = transpose(convex_coeffs[:, k]) * is
            innerloop!(inds, signs, s_arr, Sj, pt, dim, M, i)
        end
    end

    return ApproxSimplexTransferOperator(transpose(M) ./ n_coeffs)
end


function transferoperator_approx(E::Embeddings.AbstractEmbedding;
                            n_pts::Int = 200,
                            sample_randomly::Bool = false)
    transferoperator_approx(triangulate(E))
end
