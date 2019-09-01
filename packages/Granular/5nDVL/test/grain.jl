#!/usr/bin/env julia

# Check the basic icefloe functionality

@info "Writing simple simulation to VTK file"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 1., verbose=false)
Granular.printGrainInfo(sim.grains[1])

@info "Testing grain value checks "
@test_throws ErrorException Granular.addGrainCylindrical!(sim, [.1, .1, .1, .1],
                                                          10., 1.)
@test_throws ErrorException Granular.addGrainCylindrical!(sim, [.1, .1],
                                                          10., 1., 
                                                          lin_vel=[.2,.2,.2,.2])
@test_throws ErrorException Granular.addGrainCylindrical!(sim, [.1, .1],
                                                          10., 1., 
                                                          lin_acc=[.2,.2,.2,.2])
@test_throws ErrorException Granular.addGrainCylindrical!(sim, [.1, .1],
                                                          0., 1.)
@test_throws ErrorException Granular.addGrainCylindrical!(sim, [.1, .1],
                                                          10., 1., density=-2.)
@test_throws ErrorException Granular.disableGrain!(sim, 0)

@info "Testing grain comparison "
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 1., verbose=false)
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 1., verbose=false)
Granular.compareGrains(sim.grains[1], sim.grains[2])
Granular.findContacts!(sim)

global gnuplot = true
try
    run(`gnuplot --version`)
catch return_signal
    if isa(return_signal, Base.IOError)
        @warn "Skipping plotting routines: Could not launch gnuplot process"
        global gnuplot = false
    end
end
if gnuplot
    @info "Testing GSD plotting "
    Granular.plotGrainSizeDistribution(sim)
    @test isfile("test-grain-size-distribution.png")
    rm("test-grain-size-distribution.png")

    Granular.plotGrainSizeDistribution(sim, skip_fixed=false)
    @test isfile("test-grain-size-distribution.png")
    rm("test-grain-size-distribution.png")

    Granular.plotGrainSizeDistribution(sim, size_type="areal")
    @test isfile("test-grain-size-distribution.png")
    rm("test-grain-size-distribution.png")

    @test_throws ErrorException Granular.plotGrainSizeDistribution(sim, size_type="asdf")

    @info "Testing grain plotting"
    Granular.plotGrains(sim, show_figure=false)
    @test isfile("test/test.grains.0.png")
    rm("test/test.grains.0.png")

    @info "  - contact_radius"
    Granular.plotGrains(sim, palette_scalar="contact_radius", show_figure=false)
    @test isfile("test/test.grains.0.png")
    rm("test/test.grains.0.png")
    @info "  - areal_radius"
    Granular.plotGrains(sim, palette_scalar="areal_radius", show_figure=false)
    @test isfile("test/test.grains.0.png")
    rm("test/test.grains.0.png")
    @info "  - color"
    Granular.plotGrains(sim, palette_scalar="color", show_figure=false)
    @test isfile("test/test.grains.0.png")
    rm("test/test.grains.0.png")

    @info "  - invalid field"
    @test_throws ErrorException Granular.plotGrains(sim, palette_scalar="asdf",
                                                   show_figure=false)
end

@info "Testing external body force routines"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 1., verbose=false)
Granular.setBodyForce!(sim.grains[1], [1., 2., 0.])
@test sim.grains[1].external_body_force ≈ [1., 2., 0.]
Granular.addBodyForce!(sim.grains[1], [1., 2., 0.])
@test sim.grains[1].external_body_force ≈ [2., 4., 0.]

@info "Testing zeroKinematics!()"
sim.grains[1].force .= ones(3)
sim.grains[1].lin_acc .= ones(3)
sim.grains[1].lin_vel .= ones(3)
sim.grains[1].torque .= ones(3)
sim.grains[1].ang_acc .= ones(3)
sim.grains[1].ang_vel .= ones(3)
Granular.zeroKinematics!(sim)
@test Granular.totalGrainKineticTranslationalEnergy(sim) ≈ 0.
@test Granular.totalGrainKineticRotationalEnergy(sim) ≈ 0.
