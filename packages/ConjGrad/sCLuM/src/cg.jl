@doc raw"""
    `struct CGData{ T :< Real }`

This structure represent the data container for the ConjGrad module, and
contain the preallocated vectors necessary for the functions.
If nothing is provided, these vectors will bel allocated at each call

In the follow instance is shown the container creation
    `cgdata = CGData(n, T)`
where `n` is the problem dimension and `T` represent the data type that are
used in the problem.
"""

struct CGData{ T <: Real }
    r::Array{T}
    z::Array{T}
    p::Array{T}
    Ap::Array{T}
    CGData{T}(n::Int) where T <: Real = new(zeros(T, n), zeros(T, n),
                                            zeros(T, n), zeros(T, n))
end

@doc raw"""
    `function cg!(A, b::Array, x::Array; tol::Float64=1e-6,
                 maxIter::Int64=1000, precon=copy!,
                 data=CGData{Float64}(length(b)),
                 verbose=false)`

This is the typical conjugate gradient algorithm in order to solve problems
like A x = b. Some hints about it are mandatory: The matrix `A` and the
preconditioner `precon` have to be expressed as functions. A scholar exsample
is given by the matrix product. If you know the complete representation of the
matrix `A` and if you use `SparseMatrixCSC` you may write its representation
using an enclosure function:

    `cg!((x)->(A * b), b)`

The same for the `precon` representation. If you don't know the complete
representation of the A matrix, you may define a effective function that's
works guess matrix A. The last case is often used for large-scale problems
where A matrix the complete representation is too big.

The algorithm was written using this reference:
["Fondamenti di Calcolo Numerico - Giovanni Monegato", pag. 77-81]


"""
function cg!(A, b::Array, x::Array;
             tol::Float64=1e-6,
             maxIter::Int64=1000, precon=copy!,
             data=CGData{Float64}(length(b)),
             verbose=false, comm=missing)

    n = length(b)
    n_iter = 0

    if genblas_nrm2(b) == 0.0
        x .= 0.0
        return 1, 0
    end

    x .= A(data.r)

    genblas_scal!(-1.0, data.r)
    # r_0 = b
    genblas_axpy!(1.0, b, data.r)
    residual_0 = sqrt(genblas_dot(data.r, data.r, comm))

    if residual_0 <= tol
        return 2, 0
    end

    # M z_0 = r
    precon(data.z, data.r)
    @. data.p = data.z

    for iter = 1:maxIter
        data.Ap .= A(data.p)
        gamma = genblas_dot(data.r, data.z, comm)
        alpha = gamma/genblas_dot(data.p, data.Ap, comm)

        if alpha == Inf || alpha < 0
            return -13, iter
        end

        genblas_axpy!(alpha, data.p, x)
        genblas_axpy!(-alpha, data.Ap, data.r)
        residual = sqrt(genblas_dot(data.r, data.r, comm))/residual_0

        if verbose
            println(residual)
        end

        if residual <= tol
            return 30, iter
        end

        precon(data.z, data.r)
        beta = genblas_dot(data.z, data.r, comm)/gamma

        genblas_scal!(beta, data.p)
        genblas_axpy!(1.0, data.z, data.p)
    end
    return -2, maxIter
end


@doc raw"""
    `function cg(A, b::Array; tol::Float64=1e-6, maxIter::Int64=1000,
                precon=copy!, data=CGData{Float64}(length(b)), verbose=false)`

A nice interface for `cg!()` function. For the whole algorithm description
you may see the `cg!()` description.
"""
function cg(A, b::Array; tol::Float64=1e-6, maxIter::Int64=1000,
            precon=copy!, data=CGData{Float64}(length(b)), verbose=false, comm=missing)
    x = zeros(length(b))
    exit_code, num_iters = cg!(A, b, x, tol=tol, maxIter=maxIter,
                               precon=precon, data=data, verbose=verbose, comm=comm)
    return x, exit_code, num_iters
end
