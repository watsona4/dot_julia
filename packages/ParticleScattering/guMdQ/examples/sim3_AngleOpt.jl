using PyPlot, ParticleScattering
import JLD, Optim, LineSearches
input_dir = homedir()
output_dir = homedir()
Ns = 100
k0 = 2π
kin = 3*k0
l0 = 2π/k0
a1=0.3*l0; a2=0.1*l0; a3=5;
dmin = R_multipole*2*(a1+a2)
θ_i = 0.5π; ui = PlaneWave(θ_i)

width = 21l0
height = 7l0
myshapefun(N) = rounded_star(a1,a2,a3,N)
points = [range(0.0, stop=width, length=20) height*ones(20)]

if !isfile(joinpath(input_dir), "sim3data.jld")
    centers = randpoints(Ns, dmin, width, height, points)
else
    JLD.@load(joinpath(input_dir, "sim3data.jld"), centers)
end

N,errN = (934, 9.97040926753751e-7) #
#N,errN = minimumN(k0,kin,myshapefun, tol = 1e-6, N_points = 20_000)
shapes = [myshapefun(N)]
P,errP = (12, 8.538711552646218e-7)#
#P,errP = minimumP(k0, kin, shapes[1], tol = 1e-6, N_points = 20_000, P_min = 1, P_max = 120)

φs = zeros(Float64,Ns)
ids = ones(Int, Ns)

fmm_options = FMMoptions(true, acc = 6, nx = 9, method="pre")

divideSpace(centers, fmm_options; drawGroups = false)

draw_fig = true

# verify and draw
begin
    @assert verify_min_distance(shapes, centers, ids, points)
    if draw_fig
        figure()
        #draw shapes and points
        draw_shapes(shapes, ids, centers, φs)
        plot(points[:,1], points[:,2], "r*")
        tight_layout()
        axis("equal")
    end
end

border = shapes[1].R*[-1;1;-1;1] + [0.0; width; 0.0; height]

optim_options =  Optim.Options(f_tol = 1e-6,
                                iterations = 150,
                                store_trace = true,
                                extended_trace = false,
                                show_trace = true,
                                allow_f_increases = true)

optim_method = Optim.BFGS(;linesearch = LineSearches.BackTracking())

#precompile
test_max = optimize_φ(φs, points, P, ui, k0, kin, shapes, centers, ids,
            fmm_options, optim_options, optim_method; minimize = false)
optim_time = @elapsed begin
    test_max = optimize_φ(φs, points, P, ui, k0, kin, shapes, centers, ids,
                fmm_options, optim_options, optim_method; minimize = false)
end

sp_before = ScatteringProblem(shapes, ids, centers, φs)
Ez1 = plot_near_field(k0, kin, P, sp_before, ui,
                x_points = 600, y_points = 200, border = border, method="recurrence")
colorbar()
clim([0;5])

sp_after = ScatteringProblem(shapes, ids, centers, test_max.minimizer)
Ez2 = plot_near_field(k0, kin, P, sp_after, ui,
                x_points = 600, y_points = 200, border = border, method="recurrence")
colorbar()
clim([0;5])

inner_iters = length(test_max.trace)
fobj = -[test_max.trace[i].value for i=1:inner_iters]
gobj = [test_max.trace[i].g_norm for i=1:inner_iters]

figure()
plot(0:inner_iters-1, fobj, label="\$f_{\\mathrm{obj}}\$")
plot(0:inner_iters-1, gobj, label="\$\\Vert\\mathbf{g}_{\\mathrm{obj}}\\Vert\$")
legend(loc="best")
xlabel("Iterations")

JLD.@save joinpath(output_dir, "angle_optim2.jld")
