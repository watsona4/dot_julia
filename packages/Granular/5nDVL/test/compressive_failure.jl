#!/usr/bin/env julia
using Test
import Granular

verbose = false
debug = false
if debug
    import PyPlot
end

function plot_interaction(sim::Granular.Simulation, output::String)
    time = Float64[]
    force_n_1 = Float64[]
    force_n_2 = Float64[]
    force_t_1 = Float64[]
    force_t_2 = Float64[]
    torque_1 = Float64[]
    torque_2 = Float64[]
    compressive_failure = Bool[]
    while sim.time < sim.time_total
        Granular.run!(sim, verbose=verbose, single_step=true)
        append!(time, sim.time)
        append!(compressive_failure, sim.grains[1].compressive_failure[1])
        append!(force_n_1, sim.grains[1].force[1])
        append!(force_n_2, sim.grains[2].force[1])
        append!(force_t_1, sim.grains[1].force[2])
        append!(force_t_2, sim.grains[2].force[2])
        append!(torque_1, sim.grains[1].torque[3])
        append!(torque_2, sim.grains[2].torque[3])
    end
    PyPlot.clf()
    PyPlot.subplot(3,1,1)
    PyPlot.plot(time, force_n_1, "-b", label="1")
    PyPlot.plot(time, force_n_2, "--y", label="2")
    PyPlot.legend(loc="upper right")
    PyPlot.ylabel("\$f_x\$ [N]")
    PyPlot.subplot(3,1,2)
    PyPlot.plot(time, force_t_1, "-b", label="1")
    PyPlot.plot(time, force_t_2, "--y", label="2")
    PyPlot.legend(loc="upper right")
    PyPlot.ylabel("\$f_y\$ [N]")
    PyPlot.subplot(3,1,3)
    PyPlot.plot(time, torque_1, "-b", label="1")
    PyPlot.plot(time, torque_2, "--y", label="2")
    PyPlot.legend(loc="upper right")
    PyPlot.ylabel("Torque [Nm]")
    PyPlot.xlabel("Time [s]")
    PyPlot.tight_layout()
    PyPlot.savefig(output)
end

@info "Testing compressive failure: uniaxial compression"
sim = Granular.createSimulation("compressive_failure_uniaxial")
Granular.addGrainCylindrical!(sim, [0.0,0.0], 1.0, 0.5,
                              fracture_toughness=1285e3,
                              lin_vel=[1.0, 0.0], fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.0,0.0], 1.0, 0.5,
                              fracture_toughness=1285e3,
                              fixed=true, verbose=verbose)
@test count(x->x==true, sim.grains[1].compressive_failure) == 0
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)

if debug
    Granular.removeSimulationFiles(sim)
    Granular.setOutputFileInterval!(sim, 0.01)
    plot_interaction(sim, sim.id * ".pdf")
else
    Granular.run!(sim, verbose=verbose)
end

@test sim.grains[1].compressive_failure[1] == true
@test count(x->x==true, sim.grains[1].compressive_failure) == 1
@test sim.grains[1].force[1] < 0.0
@test sim.grains[1].force[2] ≈ 0.0
@test sim.grains[2].force[1] > 0.0
@test sim.grains[2].force[2] ≈ 0.0
@test sim.grains[1].torque ≈ zeros(3)
@test sim.grains[2].torque ≈ zeros(3)

@info "Testing compressive failure: shear"
sim = Granular.createSimulation("compressive_failure_shear")
Granular.addGrainCylindrical!(sim, [0.0,0.0], 1.0, 0.5,
                              fracture_toughness=1285e3,
                              lin_vel=[0.0, 1.0], fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [1.5,1.5], 1.0, 0.5,
                              fracture_toughness=1285e3,
                              fixed=true, verbose=verbose)
@test count(x->x==true, sim.grains[1].compressive_failure) == 0
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)

if debug
    Granular.removeSimulationFiles(sim)
    Granular.setOutputFileInterval!(sim, 0.01)
    plot_interaction(sim, sim.id * ".pdf")
else
    Granular.run!(sim, verbose=verbose)
end

@test sim.grains[1].compressive_failure[1] == true
@test count(x->x==true, sim.grains[1].compressive_failure) == 1
@test sim.grains[1].force[1] > 0.0
@test sim.grains[1].force[2] < 0.0
@test abs(sim.grains[1].force[1]) < abs(sim.grains[1].force[2])
@test sim.grains[2].force[1] < 0.0
@test sim.grains[2].force[2] > 0.0
@test abs(sim.grains[2].force[1]) < abs(sim.grains[2].force[2])
@test sim.grains[1].torque[1:2] ≈ zeros(2)
@test sim.grains[1].torque[3] < 0.0
@test sim.grains[2].torque[1:2] ≈ zeros(2)
@test sim.grains[2].torque[3] < 0.0

@info "Testing robustness of overlap calculations"
sim = Granular.createSimulation("overlap")
Granular.addGrainCylindrical!(sim, [0.0,0.0], 1.0, 0.5,
                              fracture_toughness=1285e3,
                              lin_vel=[0., 1.0], fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.0,0.0], 1.0, 0.5,
                              fracture_toughness=1285e3,
                              fixed=true, verbose=verbose)
@test count(x->x==true, sim.grains[1].compressive_failure) == 0
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=verbose)
@test sim.grains[1].compressive_failure[1] == false
@test sim.grains[1].contact_area[1] == 0.0
@test count(x->x==true, sim.grains[1].compressive_failure) == 0

sim = Granular.createSimulation("overlap")
Granular.addGrainCylindrical!(sim, [0.,0.], 1.0, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [0.0+1e-9,0.0], 1.0, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=verbose)
@test sim.grains[1].compressive_failure[1] == true
@test sim.grains[1].contact_area[1] ≈ π*1.0^2

sim = Granular.createSimulation("overlap")
Granular.addGrainCylindrical!(sim, [0.,0.], 1.0, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [0.1,0.], 1.0, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=verbose)
@test sim.grains[1].compressive_failure[1] == true
@test sim.grains[1].contact_area[1] < π*1.0^2
@test sim.grains[1].contact_area[1] > 0.

sim = Granular.createSimulation("overlap")
Granular.addGrainCylindrical!(sim, [0.0,0.0], 1.0, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [0.0+1e-9,0.0], 0.1, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
@test count(x->x==true, sim.grains[1].compressive_failure) == 0
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=verbose)
@test sim.grains[1].position_vector[1] ≈ [-1e-9, 0., 0.]
@test sim.grains[1].compressive_failure[1] == true
@test sim.grains[1].contact_area[1] ≈ π*0.1^2

sim = Granular.createSimulation("overlap")
Granular.addGrainCylindrical!(sim, [0.0,0.0], 1.0, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
Granular.addGrainCylindrical!(sim, [0.3,0.4], 0.1, 0.5,
                              fracture_toughness=1.0,
                              fixed=true, verbose=verbose)
@test count(x->x==true, sim.grains[1].compressive_failure) == 0
Granular.setTimeStep!(sim, verbose=verbose)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=verbose)
@test sim.grains[1].compressive_failure[1] == true
@test sim.grains[1].contact_area[1] ≈ π*0.1^2
