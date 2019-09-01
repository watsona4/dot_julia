#!/usr/bin/env julia
if VERSION < v"0.7.0-DEV.2004"
    using Base.Test
else
    using Test
end
import Plots
import Granular
import CurveFit

verbose=false

@info "Testing performance with many interacting grains"

function timeSingleStepInDenseSimulation(nx::Int; verbose::Bool=true,
                                         profile::Bool=false,
                                         grid_sorting::Bool=true,
                                         include_atmosphere::Bool=false)

    sim = Granular.createSimulation()
    #nx, ny = 25, 25
    #nx, ny = 250, 250
    ny = nx
    dx, dy = 40., 40.
    sim.ocean = Granular.createRegularOceanGrid([nx, ny, 2], [nx*dx, ny*dy, 10.])
    if !grid_sorting
        sim.ocean.input_file = false  # fallback to all-to-all contact search
    end
    r = min(dx, dy)/2.
    if include_atmosphere
        sim.atmosphere = Granular.createRegularAtmosphereGrid([nx, ny, 2],
                                                            [nx*dx, ny*dy, 10.])
    end

    # add grains in regular packing
    for iy=1:ny
        for ix=1:nx
            x = r + (ix - 1)*dx
            y = r + (iy - 1)*dy
            fixed = false
            if ix == 1 || iy == 1 || ix == nx || iy == ny
                fixed = true
            end
            Granular.addGrainCylindrical!(sim, [x, y], r*1.1, 1.,
                                          fixed=fixed, verbose=false)
        end
    end
    printstyled("number of grains: $(length(sim.grains))\n",
                       color=:green)
    if grid_sorting
        if include_atmosphere
            printstyled("using cell-based spatial decomposition " *
                             " (ocean + atmosphere)\n", color=:green)
        else
            printstyled("using cell-based spatial " * 
                             "decomposition (ocean)\n", color=:green)
        end
    else
        printstyled("using all-to-all contact search\n", color=:green)
    end

    Granular.setTotalTime!(sim, 1.0)
    Granular.setTimeStep!(sim)
    Granular.run!(sim, single_step=true, verbose=true)
    if profile
        @profile Granular.run!(sim, single_step=true, verbose=true)
        if verbose
            Profile.print()
        end
        Granular.run!(sim, single_step=true, verbose=true)
    end
    n_runs = 4
    t_elapsed = 1e12
    for i=1:n_runs
        tic()
        @time Granular.run!(sim, single_step=true, verbose=true)
        t = toc()
        if t < t_elapsed
            t_elapsed = t
        end
    end

    #Granular.writeVTK(sim)

    @test sim.grains[1].n_contacts == 0
    @test sim.grains[2].n_contacts == 1
    @test sim.grains[3].n_contacts == 1
    @test sim.grains[nx].n_contacts == 0
    @test sim.grains[nx + 1].n_contacts == 1
    @test sim.grains[nx + 2].n_contacts == 4
    return t_elapsed, Base.summarysize(sim)
end

#nx = Int[4 8 16 32 64 96]
nx = round.(logspace(1, 2, 16))
elements = zeros(length(nx))
t_elapsed = zeros(length(nx))
t_elapsed_all_to_all = zeros(length(nx))
t_elapsed_cell_sorting = zeros(length(nx))
t_elapsed_cell_sorting2 = zeros(length(nx))
memory_usage_all_to_all = zeros(length(nx))
memory_usage_cell_sorting = zeros(length(nx))
memory_usage_cell_sorting2 = zeros(length(nx))
for i=1:length(nx)
    @info "nx = $(nx[i])"
    t_elapsed_all_to_all[i], memory_usage_all_to_all[i] =
        timeSingleStepInDenseSimulation(Int(nx[i]), grid_sorting=false)
    t_elapsed_cell_sorting[i], memory_usage_cell_sorting[i] =
        timeSingleStepInDenseSimulation(Int(nx[i]), grid_sorting=true)
    t_elapsed_cell_sorting2[i], memory_usage_cell_sorting2[i] =
        timeSingleStepInDenseSimulation(Int(nx[i]), grid_sorting=true, 
                                        include_atmosphere=true)
    elements[i] = nx[i]*nx[i]
end

#Plots.gr()
Plots.pyplot()
Plots.scatter(elements, t_elapsed_all_to_all,
              xscale=:log10,
              yscale=:log10,
              label="All to all")
fit_all_to_all = CurveFit.curve_fit(CurveFit.PowerFit,
                                    elements, t_elapsed_all_to_all)
label_all_to_all = @sprintf "%1.3g n^%3.2f" fit_all_to_all.coefs[1] fit_all_to_all.coefs[2]
Plots.plot!(elements, fit_all_to_all(elements),
            xscale=:log10,
            yscale=:log10,
            label=label_all_to_all)

Plots.scatter!(elements, t_elapsed_cell_sorting,
               xscale=:log10,
               yscale=:log10,
               label="Cell-based spatial decomposition (ocean only)")
fit_cell_sorting = CurveFit.curve_fit(CurveFit.PowerFit,
                                    elements, t_elapsed_cell_sorting)
label_cell_sorting = @sprintf "%1.3g n^%3.2f" fit_cell_sorting.coefs[1] fit_cell_sorting.coefs[2]
Plots.plot!(elements, fit_cell_sorting(elements),
            xscale=:log10,
            yscale=:log10,
            label=label_cell_sorting)

Plots.scatter!(elements, t_elapsed_cell_sorting2,
               xscale=:log10,
               yscale=:log10,
               label="Cell-based spatial decomposition (ocean + atmosphere)")
fit_cell_sorting2 = CurveFit.curve_fit(CurveFit.PowerFit,
                                       elements, t_elapsed_cell_sorting2)
label_cell_sorting2 = @sprintf "%1.3g n^%3.2f" fit_cell_sorting2.coefs[1] fit_cell_sorting2.coefs[2]
Plots.plot!(elements, fit_cell_sorting2(elements),
            xscale=:log10,
            yscale=:log10,
            label=label_cell_sorting2)

Plots.title!("Dense granular system " * "(host: $(gethostname()))")
Plots.xaxis!("Number of grains")
Plots.yaxis!("Wall time per time step [s]")
Plots.savefig("profiling-cpu.pdf")

Plots.scatter(elements, memory_usage_all_to_all .÷ 1024,
              xscale=:log10,
              yscale=:log10,
              label="All to all")
fit_all_to_all = CurveFit.curve_fit(CurveFit.PowerFit,
                                    elements, memory_usage_all_to_all .÷ 1024)
label_all_to_all = @sprintf "%1.3g n^%3.2f" fit_all_to_all.coefs[1] fit_all_to_all.coefs[2]
Plots.plot!(elements, fit_all_to_all(elements),
            xscale=:log10,
            yscale=:log10,
            label=label_all_to_all)

Plots.scatter!(elements, memory_usage_cell_sorting .÷ 1024,
               xscale=:log10,
               yscale=:log10,
               label="Cell-based spatial decomposition (ocean only)")
fit_cell_sorting = CurveFit.curve_fit(CurveFit.PowerFit,
                                    elements, memory_usage_cell_sorting .÷ 1024)
label_cell_sorting = @sprintf "%1.3g n^%3.2f" fit_cell_sorting.coefs[1] fit_cell_sorting.coefs[2]
Plots.plot!(elements, fit_cell_sorting(elements),
            xscale=:log10,
            yscale=:log10,
            label=label_cell_sorting)

Plots.scatter!(elements, memory_usage_cell_sorting2 .÷ 1024,
               xscale=:log10,
               yscale=:log10,
               label="Cell-based spatial decomposition (ocean + atmosphere)")
fit_cell_sorting2 = CurveFit.curve_fit(CurveFit.PowerFit,
                                       elements,
                                       memory_usage_cell_sorting2 .÷ 1024)
label_cell_sorting2 = @sprintf "%1.3g n^%3.2f" fit_cell_sorting2.coefs[1] fit_cell_sorting2.coefs[2]
Plots.plot!(elements, fit_cell_sorting2(elements),
            xscale=:log10,
            yscale=:log10,
            label=label_cell_sorting2)

Plots.title!("Dense granular system " * "(host: $(gethostname()))")
Plots.xaxis!("Number of grains")
Plots.yaxis!("Memory usage [kb]")
Plots.savefig("profiling-memory-usage.pdf")
