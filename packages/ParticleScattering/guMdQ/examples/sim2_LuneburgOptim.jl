using PyPlot, ParticleScattering
import Optim, JLD

output_dir = homedir()
er = 4.5
k0 = 2π
l0 = 2π/k0
a_lens = 0.2*l0
R_lens = 10*a_lens

kin = k0*sqrt(er)
N_cells = Int(round(2*R_lens/a_lens))
centers, ids_lnbrg, rs_lnbrg = luneburg_grid(R_lens, N_cells, er)
φs = zeros(Float64, length(ids_lnbrg))
pw = PlaneWave(0.0)
P = 5

fmm_options = FMMoptions(true, acc = 6, dx = 2*a_lens, method = "pre")

optim_options =  Optim.Options(x_tol = 1e-6, outer_x_tol = 1e-6,
                        iterations = 100, outer_iterations = 100,
                        store_trace = true, extended_trace = true,
                        show_trace = false, allow_f_increases = true)

points = [R_lens 0.0]
r_max = (a_lens/1.15/2)*ones(size(centers,1))
r_min = (a_lens*1e-3)*ones(size(centers,1))
rs0 = (0.25*a_lens)*ones(size(centers,1))

ids_max = collect(1:length(rs0))
test_max = optimize_radius(rs0, r_min, r_max, points, ids_max, P, pw, k0, kin, #precompile
                centers, fmm_options, optim_options, minimize = false)
optim_time = @elapsed begin
    test_max = optimize_radius(rs0, r_min, r_max, points, ids_max, P, pw, k0, kin,
                centers, fmm_options, optim_options, minimize = false)
end
rs_max = test_max.minimizer

# plot near fields
border = (R_lens + a_lens)*[-1;1;-1;1]

sp1 = ScatteringProblem([CircleParams(rs_lnbrg[i]) for i in eachindex(rs_lnbrg)],
        ids_lnbrg, centers, φs)
Ez1 = plot_near_field(k0, kin, P, sp1, pw, x_points = 300, y_points = 300,
        opt = fmm_options, border = border)

sp2 = ScatteringProblem([CircleParams(rs_max[i]) for i in eachindex(rs_max)],
        ids_max, centers, φs)
Ez2 = plot_near_field(k0, kin, P, sp2, pw, x_points = 300, y_points = 300,
            opt = fmm_options, border = border)

sp3 = ScatteringProblem([CircleParams(rs0[i]) for i in eachindex(rs0)],
        collect(1:length(rs0)), centers, φs)
Ez3 = plot_near_field(k0, kin, P, sp3, pw, x_points = 300, y_points = 300,
        opt = fmm_options, border = border)

#plot convergence
inner_iters = length(test_max.trace)
iters = [test_max.trace[i].iteration for i=1:inner_iters]
fobj = -[test_max.trace[i].value for i=1:inner_iters]
gobj = [test_max.trace[i].g_norm for i=1:inner_iters]
rng = iters .== 0

trace_of_r = [test_max.trace[i].metadata["x"] for i=1:inner_iters]
JLD.@save(joinpath(output_dir, "luneburg_optim.jld"), sp1, sp2, sp3,Ez1, Ez2, Ez3,
        inner_iters, iters, fobj, gobj, rng, optim_time, rs_max, border)

figure()
plot(0:inner_iters-1, fobj, "b", label="\$f_{\\mathrm{obj}}\$")
plot(0:inner_iters-1, log10.(gobj), "r--", label="\$\\Vert \\mathbf{g}_{\\mathrm{obj}}\\Vert_{\\infty}\$")
plot((0:inner_iters-1)[rng], fobj[rng],"bo")
plot((0:inner_iters-1)[rng], gobj[rng],"r^")
xlabel("Iterations")
legend(loc="best")

################ Testing with symmetry ######################
@assert length(ids_max)==size(centers,1)
centers_abs = centers[:,1] + 1im*abs.(centers[:,2])
ids_sym, centers_abs = ParticleScattering.uniqueind(centers_abs)
J = length(centers_abs)
r_max = (a_lens/1.15/2)*ones(J)
r_min = (a_lens*1e-3)*ones(J)
rs0 = (0.25*a_lens)*ones(J)

sym_time = @elapsed begin
    test_max_sym = optimize_radius(rs0, r_min, r_max, points, ids_sym, P, pw, k0, kin,
                centers, fmm_options, optim_options, minimize = false)
end
JLD.@save joinpath(output_dir, "luneburg_optim_sym.jld") test_max_sym sym_time

rs_sym = test_max_sym.minimizer
sp4 = ScatteringProblem([CircleParams(rs_sym[i]) for i in eachindex(rs_sym)],
        ids_sym, centers, φs)
Ez4 = plot_near_field(k0, kin, P, sp4, pw, x_points = 300, y_points = 300,
        opt = fmm_options, border = border, method = "recurrence")

u1 = calc_near_field(k0, kin, 7, sp1, points, pw; opt = fmm_options)
u2 = calc_near_field(k0, kin, 7, sp2, points, pw; opt = fmm_options)
u3 = calc_near_field(k0, kin, 7, sp3, points, pw; opt = fmm_options)
u4 = calc_near_field(k0, kin, 7, sp4, points, pw; opt = fmm_options)
abs.([u1[1];u2[1];u3[1];u4[1]])
