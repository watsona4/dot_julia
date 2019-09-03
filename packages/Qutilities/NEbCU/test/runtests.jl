using Qutilities
using Test

using LinearAlgebra: diagm, I, tr

@testset "Qutilities" begin

@testset "sigma_x, sigma_y, sigma_z" begin
    @test sigma_x^2 == I
    @test sigma_y^2 == I
    @test sigma_z^2 == I
    @test -im*sigma_x*sigma_y*sigma_z == I
end

@testset "ptrace, ptranspose" begin
    let A = Matrix{Int}(I, 2, 2),
        B = reshape(1:16, 4, 4),
        C = [[0, 0, 1] [0, 1, 0] [1, 0, 0]],
        ABC = kron(A, B, C),
        dims = (2, 4, 3)

        @test ptrace(ABC, dims, 1) == tr(A) * kron(B, C)
        @test ptranspose(ABC, dims, 1) == kron(A', B, C)
        @test ptrace(ABC, dims, 2) == tr(B) * kron(A, C)
        @test ptranspose(ABC, dims, 2) == kron(A, B', C)
        @test ptrace(ABC, dims, 3) == tr(C) * kron(A, B)
        @test ptranspose(ABC, dims, 3) == kron(A, B, C')
    end

    let M = reshape(1.0:16.0, 4, 4),
        MT1 = [[1.0, 2.0, 9.0, 10.0] [5.0, 6.0, 13.0, 14.0] [3.0, 4.0, 11.0, 12.0] [7.0, 8.0, 15.0, 16.0]],
        MT2 = [[1.0, 5.0, 3.0, 7.0] [2.0, 6.0, 4.0, 8.0] [9.0, 13.0, 11.0, 15.0] [10.0, 14.0, 12.0, 16.0]]

        @test ptrace(M, (1, 4), 1) == M
        @test ptranspose(M, (1, 4), 1) == M
        @test ptrace(M, (1, 4), 2) == fill(tr(M), 1, 1)
        @test ptranspose(M, (1, 4), 2) == transpose(M)
        @test ptrace(M, (2, 2), 1) == [[12.0, 14.0] [20.0, 22.0]]
        @test ptranspose(M, (2, 2), 1) == MT1
        @test ptrace(M, (2, 2), 2) == [[7.0, 11.0] [23.0, 27.0]]
        @test ptranspose(M, (2, 2), 2) == MT2
        @test ptrace(M, (4, 1), 1) == fill(tr(M), 1, 1)
        @test ptranspose(M, (4, 1), 1) == transpose(M)
        @test ptrace(M, (4, 1), 2) == M
        @test ptranspose(M, (4, 1), 2) == M

        @test ptrace(M, 1) == ptrace(M, (2, 2), 1)
        @test ptrace(M, 2) == ptrace(M, (2, 2), 2)
        @test ptranspose(M, 1) == ptranspose(M, (2, 2), 1)
        @test ptranspose(M, 2) == ptranspose(M, (2, 2), 2)

        @test ptrace(M) == ptrace(M, (2, 2), 2)
        @test ptranspose(M) == ptranspose(M, (2, 2), 2)
    end

    let M = [[1.0, im] [im, 1.0]]

        @test ptrace(M, (1, 2), 1) == M
        @test ptranspose(M, (1, 2), 1) == M
        @test ptrace(M, (1, 2), 2) == fill(tr(M), 1, 1)
        @test ptranspose(M, (1, 2), 2) == transpose(M)
    end
end

@testset "binent" begin
    @test binent(0.0) == 0.0
    @test binent(0.5) == 1.0
    @test binent(1.0) == 0.0
end

@testset "purity, S_vn, S_renyi" begin
    let rho1 = Matrix{Float64}(I, 4, 4) / 4.0,
        rho2 = [[2.0, im] [-im, 2.0]] / 2.0,
        eigs2 = [1.0, 3.0] / 2.0

        @test purity(rho1) == 0.25
        @test purity(rho2) == sum(eigs2.^2)

        @test S_renyi(rho1, 0) == 2.0
        @test S_renyi(rho2, 0) == 1.0

        @test S_vn(rho1) == 2.0
        @test S_vn(rho2) == -sum(eigs2 .* log2.(eigs2))

        @test S_renyi(rho1) == 2.0
        @test S_renyi(rho2) == -log2(sum(eigs2.^2))

        @test S_renyi(rho1, Inf) == 2.0
        @test S_renyi(rho2, Inf) == -log2(maximum(eigs2))
    end
end

@testset "mutinf" begin
    let rho = diagm(0 => [3, 2, 1, 2]) / 8.0

        @test isapprox(mutinf(rho), (1.5 - 5.0 * log2(5.0) / 8.0))
        @test isapprox(mutinf(rho, S_renyi), (1.0 + 2.0 * log2(3.0) - log2(17.0)))
    end
end


@testset "spinflip, concurrence, concurrence_lb, formation, negativity" begin
    let rho = reshape(1.0:16.0, 4, 4),
        rho_f = [[16.0, -15.0, -14.0, 13.0] [-12.0, 11.0, 10.0, -9.0] [-8.0, 7.0, 6.0, -5.0] [4.0, -3.0, -2.0, 1.0]]

        @test spinflip(rho) == rho_f
    end

    let rho = zeros(4, 4)

        rho[1, 1] = 0.5
        rho[4, 4] = 0.5

        let C = concurrence(rho)

            @test spinflip(rho) == rho
            @test C == 0.0
            @test concurrence_lb(rho) == 0.0
            @test formation(C) == 0.0
            @test negativity(rho) == 0.0
        end
    end

    let rho = zeros(4, 4)

        rho[1, 1] = 0.125
        for i in 2:3, j in 2:3
            rho[i, j] = 0.375
        end
        rho[4, 4] = 0.125

        let C = concurrence(rho),
            a = (2 + sqrt(3.0)) / 4.0,
            b = (2 - sqrt(3.0)) / 4.0

            @test spinflip(rho) == rho
            @test C == 0.5
            @test concurrence_lb(rho) == sqrt(3.0)/4.0
            @test formation(C) == -a * log2(a) - b * log2(b)
            @test negativity(rho) == log2(1.5)
        end
    end

    let rho = zeros(4, 4)

        for i in 2:3, j in 2:3
            rho[i, j] = 0.5
        end

        let C = concurrence(rho)

            @test spinflip(rho) == rho
            @test C == 1.0
            @test concurrence_lb(rho) == 1.0
            @test formation(C) == 1.0
            @test negativity(rho) == 1.0
        end
    end

    let rho = Matrix{ComplexF64}(undef, 4, 4)

        for i in 1:4
            for j in 1:4
                if i < j
                    rho[i, j] = 0.0625im
                elseif i == j
                    rho[i, j] = 0.25
                else
                    rho[i, j] = -0.0625im
                end
            end
        end

        let C = concurrence(rho),
            rho_f = copy(transpose(rho))

            rho_f[1, 4] *= -1
            rho_f[2, 3] *= -1
            rho_f[3, 2] *= -1
            rho_f[4, 1] *= -1

            @test spinflip(rho) == rho_f
            @test C == 0.0
            @test concurrence_lb(rho) == 0.0
            @test formation(C) == 0.0
            @test isapprox(negativity(rho), 0.0, atol=1e-15)
        end
    end
end

end
