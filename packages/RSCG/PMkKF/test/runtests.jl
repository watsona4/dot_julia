using Test,RSCG
using SparseArrays
using LinearMaps

function test1(n,M)
    σ = zeros(ComplexF64,M)
    σmin = -10.0*im
    σmax = 10.0*im
    for i=1:M
        σ[i] = (i-1)*(σmax-σmin)/(M-1) + σmin
    end
    A = make_mat(n)
    i = 1
    j = 1
    Gij = greensfunctions(i,j,σ,A)

    Ii = spzeros(ComplexF64,n,n)
    for ii=1:n
        Ii[ii,ii] = σ[1]
    end
    G = inv(Matrix(Ii-A))

    @test abs(G[1,1]-Gij[1]) < 1e-7
end

function test1(n,M)
    σ = zeros(ComplexF64,M)
    σmin = -10.0*im
    σmax = 10.0*im
    for i=1:M
        σ[i] = (i-1)*(σmax-σmin)/(M-1) + σmin
    end
    A = make_mat(n)
    i = 1
    j = 1
    Gij = greensfunctions(i,j,σ,A)

    Ii = spzeros(ComplexF64,n,n)
    for ii=1:n
        Ii[ii,ii] = σ[1]
    end
    G = inv(Matrix(Ii-A))
    println("Residual ",abs(G[1,1]-Gij[1]))
    @test abs(G[1,1]-Gij[1]) < 1e-7
end

function test2(n,M)
    σ = zeros(ComplexF64,M)
    σmin = -10.0*im
    σmax = 10.0*im
    for i=1:M
        σ[i] = (i-1)*(σmax-σmin)/(M-1) + σmin
    end
    A2 = make_matc(n)
    i = 1
    j = 1
    Gij = greensfunctions(i,j,σ,A2)

    Ii = spzeros(ComplexF64,2n,2n)
    for ii=1:2n
        Ii[ii,ii] = σ[1]
    end
    G = inv(Matrix(Ii-A2))
    println("Residual ",abs(G[1,1]-Gij[1]))
    @test abs(G[1,1]-Gij[1]) < 1e-7
end

function test3(n,M)
    σ = zeros(ComplexF64,M)
    σmin = -4.0*im+0.2
    σmax = 4.0*im -0.3
    for i=1:M
        σ[i] = (i-1)*(σmax-σmin)/(M-1) + σmin
    end
    A2 = make_matc(n)
    vec_i = [1,4,div(n,2),n]
    j = div(n,2)
    Gij = greensfunctions(vec_i,j,σ,A2)

    Ii = spzeros(ComplexF64,2n,2n)
    for ii=1:2n
        Ii[ii,ii] = σ[div(M,2)]
    end
    G = inv(Matrix(Ii-A2))

    for ii = 1:length(vec_i)
        i = vec_i[ii]
        println("Residual ",abs(G[i,j]-Gij[div(M,2),ii]) )
        @test abs(G[i,j]-Gij[div(M,2),ii]) < 1e-7
    end
end

function set_diff(v)
    function calc_diff!(y::AbstractVector, x::AbstractVector)
        n = length(x)
        length(y) == n || throw(DimensionMismatch())
        μ = -1.5
        for i=1:n
            dx = 1
            jp = i+dx
            jp += ifelse(jp > n,-n,0) #+1方向
            dx = -1
            jm = i+dx
            jm += ifelse(jm < 1,n,0) #-1方向
            y[i] = v*(x[jp]+x[jm])-μ*x[i]
        end

        return y
    end
    (y,x) -> calc_diff!(y,x)
end

function test4(n,M)
    σ = zeros(ComplexF64,M)
    σmin = -4.0*im-1.2
    σmax = 4.0*im +4.3
    for i=1:M
        σ[i] = (i-1)*(σmax-σmin)/(M-1) + σmin
    end
    A = set_diff(-1.0)
    D = LinearMap(A, n; ismutating=true,issymmetric=true)
    A2 = make_mat(n)

    vec_i = [2,4,div(n,2),n]
    j = n
    Gij = greensfunctions(vec_i,j,σ,D)

    Ii = spzeros(ComplexF64,n,n)
    for ii=1:n
        Ii[ii,ii] = σ[div(M,2)]
    end
    G = inv(Matrix(Ii-A2))

    for ii = 1:length(vec_i)
        i = vec_i[ii]
        println("Residual ",abs(G[i,j]-Gij[div(M,2),ii]) )
        @test abs(G[i,j]-Gij[div(M,2),ii]) < 1e-7
    end
end

function make_mat(n)
    A = spzeros(Float64,n,n)
    t = -1.0
    μ = -1.5
    for i=1:n
        dx = 1
        jp = i+dx
        jp += ifelse(jp > n,-n,0) #+1方向
        dx = -1
        jm = i+dx
        jm += ifelse(jm < 1,n,0) #-1方向
        A[i,jp] = t
        A[i,i] = -μ
        A[i,jm] = t
    end
    return A
end

function make_matc(n)
    A = make_mat(n)
    A2 = spzeros(ComplexF64,2n,2n)

    Delta = spzeros(ComplexF64,n,n)
    phi = rand(n)
    for i=1:n
        Delta[i,i] = exp(im*phi[i])
    end

    A2[1:n,1:n] = A[1:n,1:n]
    A2[1+n:2n,1+n:2n] = -conj(A[1:n,1:n])
    A2[1:n,1+n:2n] = Delta[1:n,1:n]
    A2[1+n:2n,1:n] = Delta'[1:n,1:n]

    return A2
end

@testset "SparseArrays" begin
    @testset "real" begin
        M = 100
        σ = zeros(M)
        n = 10
        println("n = $(n)")
        @time test1(n,M)
        n = 100
        println("n = $(n)")
        @time test1(n,M)
        n=  1000
        println("n = $(n)")
        @time test1(n,M)
    end

    @testset "complex" begin
        M = 100
        σ = zeros(M)
        n = 5
        println("n = $(2n)")
        @time  test2(n,M)
        n = 50
        println("n = $(2n)")
        @time  test2(n,M)
        n=  500
        println("n = $(2n)")
        @time  test2(n,M)
    end

    @testset "complex: multi values" begin
        M = 100
        σ = zeros(M)
        n = 5
        println("n = $(2n)")
        @time  test3(n,M)
        n = 50
        println("n = $(2n)")
        @time  test3(n,M)
        n=  500
        println("n = $(2n)")
        @time  test3(n,M)
    end
end

@testset "Linearmaps" begin
    @testset "complex: multi values" begin
        M = 100
        σ = zeros(M)
        n = 10
        println("n = $(n)")
        @time  test4(n,M)
        n = 100
        println("n = $(n)")
        @time  test4(n,M)
        n=  1000
        println("n = $(n)")
        @time  test4(n,M)
    end
end
