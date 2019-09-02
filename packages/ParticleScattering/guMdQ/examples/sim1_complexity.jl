# Here is a simulation of solution time as a function of M - number of shapes (or sqrt of number of shapes)
using ParticleScattering, IterativeSolvers, PyPlot
import JLD
import LinearMaps: LinearMap
import Statistics: mean
output_dir = homedir()
#loop definitions
sqrtM_vec = collect(5:30); M_vec = sqrtM_vec.^2
trials = 3
simlen = length(M_vec)
res_vec = Array{Float64}(undef, simlen, trials)
iter_vec = Array{Float64}(undef, simlen, trials)
mvp_vec = Array{Float64}(undef, simlen, trials)
setup_vec = Array{Float64}(undef, simlen, trials)

#variables
k0 = 10.0
kin = 1.5*k0
l0 = 2π/k0
a1 = 0.3*l0; a2 = 0.1*l0; a3 = 5
θ_i = 0.0
tol = 1e-6
dist = 0.9l0

myshapefun(N) = rounded_star(a1, a2, a3, N)
N = 342; errN = 9.97e-7
# N,errN = minimumN(k0, kin, myshapefun, tol = tol, N_points = 20_000)
shapes = [myshapefun(N)]
P = 10; errP = 9.57e-7
# P,errP = minimumP(k0, kin, shapes[1], tol = tol, N_points = 20_000,
#                             P_min = 1, P_max = 120)

scatteringMatrices,innerExpansions = particleExpansion(k0, kin, shapes, P, [1])
α = Complex{Float64}[exp(1.0im*p*(pi/2-θ_i)) for p=-P:P]
dt0 = @elapsed for i=1:trials
    global scatteringMatrices,innerExpansions = particleExpansion(k0, kin, shapes, P, [1])
    global α = Complex{Float64}[exp(1.0im*p*(pi/2-θ_i)) for p=-P:P]
end
dt0 /= trials

function time_FMM(is, it)
    #compute shape variables
    sqrtM = sqrtM_vec[is]
    M = sqrtM^2
    centers = square_grid(sqrtM, dist)
    φs = rand(M)
    ids = ones(Int, M)
    opt = FMMoptions(true, acc = Int(-log10(tol)), nx = div(sqrtM,2), method="pre")

    setup_vec[is,it] = @elapsed begin
        (groups, boxSize) = divideSpace(centers, opt)
        (P2, Q) = FMMtruncation(opt.acc, boxSize, k0)
        mFMM = FMMbuildMatrices(k0, P, P2, Q, groups, centers, boxSize, tri=true)

        #construct rhs
        rhs = repeat(α, M)
        for ic = 1:M
            rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
            if φs[ic] == 0.0
                rhs[rng] = scatteringMatrices[ids[ic]]*α
            else
                #rotate without matrix
                ParticleScattering.rotateMultipole!(view(rhs,rng),-φs[ic],P)
                rhs[rng] = scatteringMatrices[ids[ic]]*rhs[rng]
                ParticleScattering.rotateMultipole!(view(rhs,rng),φs[ic],P)
            end
            #phase shift added to move cylinder coords
            phase = exp(1.0im*k0*(cos(θ_i)*centers[ic,1] + sin(θ_i)*centers[ic,2]))
            rhs[rng] .*= phase
        end
        pre_agg_buffer = zeros(Complex{Float64},Q,length(groups))
        trans_buffer = Array{Complex{Float64}}(undef, Q)

        MVP = LinearMap{eltype(rhs)}((output_, x_) ->
                ParticleScattering.FMM_mainMVP_pre!(output_, x_, scatteringMatrices,
                    φs, ids, P, mFMM, pre_agg_buffer, trans_buffer),
                M*(2*P+1), M*(2*P+1), ismutating = true)
        x = zero(rhs)
    end

    res_vec[is,it] = @elapsed begin
        x,ch = gmres!(x, MVP, rhs, restart = M*(2*P+1), tol = opt.tol,
                log = true, initially_zero = true)
    end
    mvp_vec[is,it] = @elapsed begin
        rhs[:] = MVP*x
    end
    iter_vec[is,it] = ch.iters
end
#warmup
for is = 1:5:simlen
    time_FMM(is, 1)
end
display("starting main benchmark...")
#benchmark
for is = 1:simlen, it = 1:trials
    time_FMM(is, it)
end

#average over all simulations
res_vec = vec(mean(res_vec, dims=2))
iter_vec = vec(mean(iter_vec, dims=2))
mvp_vec = vec(mean(mvp_vec, dims=2))
setup_vec = vec(mean(setup_vec, dims=2))

JLD.@save(joinpath(output_dir, "complexity.jld"), M_vec, res_vec, mvp_vec, setup_vec)

########################
linreg(x, y) = hcat(fill!(similar(x), 1), x) \ y
a_total,b_total = linreg(log10.(M_vec), log10.(res_vec))
res_ana = (10^a_total)*(M_vec.^b_total)
a_mvp,b_mvp = linreg(log10.(M_vec), log10.(mvp_vec))
mvp_ana = (10^a_mvp)*(M_vec.^b_mvp)
a_setup,b_setup = linreg(log10.(M_vec), log10.(setup_vec))
setup_ana = (10^a_setup)*(M_vec.^b_setup)
semilogy(M_vec, res_vec,"bo")
semilogy(M_vec, res_ana, "b-")
semilogy(M_vec, mvp_vec, "k+")
semilogy(M_vec, mvp_ana, "k-")
semilogy(M_vec, setup_vec, "r^")
semilogy(M_vec, setup_ana, "r-")
legend(("Elapsed time (Sol.)", @sprintf("\$%fM^{%.2f}\$", 10^a_total, b_total),
        "Elapsed time (MVP.)", @sprintf("\$%fM^{%.2f}\$", 10^a_mvp, b_mvp),
        "Elapsed time (Setup)", @sprintf("\$%fM^{%.2f}\$", 10^a_setup, b_setup)), loc = "best")
xlabel("Number of Scatterers")
