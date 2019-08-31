"""
	transferoperator_exact(t::AbstractTriangulation)

Compute the transfer operator from a triangulation.
"""
function transferoperator_exact(t::AbstractTriangulation)
    n_simplices = size(t.simplex_inds, 1)
    dim = size(t.points, 2)

    #=
    Mismatch for the markovity of the Markov matrix is at most δ if ϵ tolerance
	as below
    =#
    δ::Float64 = 1/10^5
    ϵ::Float64 = δ/n_simplices

    #=
    Tolerance for similary of convex expansion coefficients of simplex vertices in
    simplexintersection function.
    =#
    convex_params_tol::Float64 = 1/10^12

    TO = zeros(Float64, n_simplices, n_simplices) # intersecting volumes

    for i in 1:n_simplices
        imvol = t.volumes_im[i]
        for j in 1:n_simplices
            vol = t.volumes[j]
            if vol * imvol > 0 && (vol/imvol) > ϵ
                # Intersecting volume between these two simplices
                TO[i, j] = simplexintersection(
                                transpose(t.points[t.simplex_inds[j, :], :]),
                                transpose(t.impoints[t.simplex_inds[i, :], :])
                            ) / imvol
            end
        end
    end
    return ExactSimplexTransferOperator(TO)
end

"""
    transferoperator_exact_p(t::AbstractTriangulation)

Estimate the transfer operator from a triangulation of a state space.
Will run in parallel if `nprocs() > 1`.
"""
function transferoperator_exact_p(t::AbstractTriangulation)

    n_simplices = size(t.simplex_inds, 1)
    dim = size(t.points, 2)

    #=
    Mismatch for the markovity of the Markov matrix is at most δ if ϵ
    tolerance as below.
    =#
    δ::Float64 = 1/10^5
    ϵ::Float64 = δ/n_simplices

    #=
    Tolerance for similary of convex expansion coefficients of simplex vertices
    in simplexintersection function.
    =#
    convex_params_tol::Float64 = 1/10^12

    TO = SharedArray{Float64}(n_simplices, n_simplices)

    @sync @distributed for i in 1:n_simplices
        imvol = t.volumes_im[i]
        for j in 1:n_simplices
            vol = t.volumes[j]
            if vol * imvol > 0 && (vol/imvol) > ϵ
                # Intersecting volume between these two simplices
                TO[i, j] = simplexintersection(
                                transpose(t.points[t.simplex_inds[j, :], :]),
                                transpose(t.impoints[t.simplex_inds[i, :], :])
                            ) / imvol
            end
        end
    end

    return ExactSimplexTransferOperator(Array(TO))
end


transferoperator_triang_exact = transferoperator_exact
export transferoperator_triang_exact
