module RSCG
    using LinearAlgebra
    using LinearMaps
    using SparseArrays

    export greensfunctions

    @doc raw"""
        greensfunctions(i::Integer,j::Integer,σ::Array{ComplexF64,1},A)

    Calculate the matrix element of the Green's function:
    ```math
    G_{ij}(\sigma_k) = \left[ (\sigma_k I - A)^{-1} \right]_{ij},
    ```
    with the use of the reduced-shifted conjugate gradient method
    (See, Y. Nagai, Y. Shinohara, Y. Futamura, and T. Sakurai,[arXiv:1607.03992v2 or DOI:10.7566/JPSJ.86.014708]).
    One can obtain ``G_{ij}(\sigma_k)`` with different frequencies ``\sigma_k``, simultaneously.

    Inputs:

    * `i` :index of the Green's function

    * `j` :index of the Green's function

    * `σ` :frequencies

    * `A` :hermitian matrix. We can use Arrays,LinearMaps, SparseArrays

    * `eps` :residual (optional) Default:`1e-12`

    * `maximumsteps` : maximum number of steps (optional) Default:`20000`

    Output:
    * `Gij[1:M]`: the matrix element Green's functions at M frequencies defined by ``\sigma_k``.
    """
    function greensfunctions(i::Integer,j::Integer,σ,A;eps=1e-12,maximumsteps=20000)

        M=length(σ)
        N=size(A,1)
        atype = eltype(A)
        σtype = eltype(σ)
        b = zeros(atype,N)
        b[j] = 1.0

    #--Line 2 in Table III.
        x = zeros(atype,N)
        r = copy(b)
        p = copy(b)
        αm = 1.0
        βm = 0.0

        m = 1
    #--
        Σ =zeros(atype,m)
        Σ[1] = b[i] #Line 3

        Θ = zeros(σtype,M)
        Π = ones(σtype,M,m)
        for mm=1:m
            Π[:,mm] *= Σ[mm]
        end
        ρk = ones(σtype,M)
        ρkm = copy(ρk)
        ρkp = copy(ρk)
        Ap = similar(p)

        for k=0:maximumsteps
            mul!(Ap,A,-p)
            #A_mul_B!(Ap,A,-p)
            rnorm = dot(r,r)
            α = rnorm/dot(p,Ap)
            @. x += α*p #Line 7
            @. r += -α*Ap #Line 8
            β = r'*r/rnorm #Line9
            @. p = r + β*p #Line 10

            Σ[1] = r[i] #Line 11

            for j = 1:M
                if abs(ρk[j]) > eps
                    ρkp[j] = ρk[j]*ρkm[j]*αm/(ρkm[j]*αm*(1.0+α*σ[j])+α*βm*(ρkm[j]-ρk[j]))#Line 13
                    αkj = α*ρkp[j]/ρk[j]#Line 14
                    Θ[j] += αkj*Π[j,1] #Line 15
                    βkj = ((ρkp[j]/ρk[j])^2)*β #Line 16
                    Π[j,:] = ρkp[j]*Σ+ βkj*Π[j,:] #Line 17
                    ρkm[j] = ρk[j]
                    ρk[j] = ρkp[j]
                end

            end
            αm = α
            βm = β
            hi = real(rnorm)*maximum(abs.(ρk))
            if hi < eps
                return Θ
            end
        end


        println("After $maximumsteps steps, this was not converged")
        return Θ

    end


    @doc raw"""
        greensfunctions(vec_left::Array{<:Integer,1},j::Integer,σ::Array{ComplexF64,1},A)

    Calculate the matrix element of the Green's function:
    ```math
    G_{ij}(\sigma_k) = \left[ (\sigma_k I - A)^{-1} \right]_{ij},
    ```
    with the use of the reduced-shifted conjugate gradient method
    (See, Y. Nagai, Y. Shinohara, Y. Futamura, and T. Sakurai,[arXiv:1607.03992v2 or DOI:10.7566/JPSJ.86.014708]).
    One can obtain ``G_{ij}(\sigma_k)`` with different frequencies ``\sigma_k``, simultaneously.

    Inputs:

    * `vec_left` :i indices of the Green's function

    * `j` :index of the Green's function

    * `σ` :frequencies

    * `A` :hermitian matrix. We can use Arrays,LinearMaps, SparseArrays

    * `eps` :residual (optional) Default:`1e-12`

    * `maximumsteps` : maximum number of steps (optional) Default:`20000`

    Output:
    * `Gij[1:M,1:length(vec_left)]`: the matrix element Green's functions at M frequencies defined by ``\sigma_k``.
    """
    function greensfunctions(vec_left::Array{<:Integer,1},j::Integer,σ,A;eps=1e-12,maximumsteps=20000)

        M=length(σ)
        N=size(A,1)
        atype = eltype(A)
        σtype = eltype(σ)
        b = zeros(atype,N)
        b[j] = 1.0
        m = length(vec_left)

    #--Line 2 in Table III.
        x = zeros(atype,N)
        r = copy(b)
        p = copy(b)
        αm = 1.0
        βm = 0.0

    #--
        Σ =zeros(atype,m)
        for mm=1:m
            Σ[mm] = b[vec_left[mm]] #Line 3
        end

        Θ = zeros(σtype,M,m)
        Π = ones(σtype,M,m)
        for mm=1:m
            Π[:,mm] *= Σ[mm]
        end
        ρk = ones(σtype,M)
        ρkm = copy(ρk)
        ρkp = copy(ρk)
        Ap = similar(p)

        for k=0:maximumsteps
            mul!(Ap,A,-p)
            #A_mul_B!(Ap,A,-p)
            rnorm = dot(r,r)
            α = rnorm/dot(p,Ap)
            @. x += α*p #Line 7
            @. r += -α*Ap #Line 8
            β = r'*r/rnorm #Line9
            @. p = r + β*p #Line 10

            for mm=1:m
                Σ[mm] = r[vec_left[mm]] #Line 11
            end

            for j = 1:M
                update = ifelse(abs(ρk[j]) > eps,true,false)
                if update
                    ρkp[j] = ρk[j]*ρkm[j]*αm/(ρkm[j]*αm*(1.0+α*σ[j])+α*βm*(ρkm[j]-ρk[j]))#Line 13
                    αkj = α*ρkp[j]/ρk[j]#Line 14
                    @. Θ[j,:] += αkj*Π[j,:] #Line 15
                    βkj = ((ρkp[j]/ρk[j])^2)*β #Line 16
                    Π[j,:] = ρkp[j]*Σ+ βkj*Π[j,:] #Line 17

                end
                ρkm[j] = ρk[j]
                ρk[j] = ρkp[j]
            end
            αm = α
            βm = β
            hi = real(rnorm)*maximum(abs.(ρk))
            if hi < eps
                return Θ
            end
        end


        println("After $maximumsteps steps, this was not converged")
        return Θ

    end


end # module
