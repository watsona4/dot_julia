#!/usr/bin/env julia

verbose=false

@info "## Inactive/Periodic BCs"

@info "Testing assignment and reporting of grid boundary conditions"
ocean = Granular.createEmptyOcean()

@test ocean.bc_west == 1
@test ocean.bc_east == 1
@test ocean.bc_north == 1
@test ocean.bc_south == 1

if !Sys.iswindows()
    const originalSTDOUT = stdout
    (out_r, out_w) = redirect_stdout()
    Granular.reportGridBoundaryConditions(ocean)
    close(out_w)
    redirect_stdout(originalSTDOUT)
    output = String(readavailable(out_r))
    @test output == """West  (-x): inactive\t(1)
    East  (+x): inactive\t(1)
    South (-y): inactive\t(1)
    North (+y): inactive\t(1)
    """

    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "periodic", "south, west",
                                        verbose=true)
    close(out_w)
    redirect_stdout(originalSTDOUT)
    output = String(readavailable(out_r))
    @test output == """West  (-x): periodic\t(2)
    East  (+x): inactive\t(1)
    South (-y): periodic\t(2)
    North (+y): inactive\t(1)
    """
    @test ocean.bc_west == 2
    @test ocean.bc_east == 1
    @test ocean.bc_north == 1
    @test ocean.bc_south == 2

    Granular.setGridBoundaryConditions!(ocean, "inactive", "all", verbose=false)
    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "periodic", "-y, -x",
                                        verbose=true)
    close(out_w)
    redirect_stdout(originalSTDOUT)
    output = String(readavailable(out_r))
    @test output == """West  (-x): periodic\t(2)
    East  (+x): inactive\t(1)
    South (-y): periodic\t(2)
    North (+y): inactive\t(1)
    """
    @test ocean.bc_west == 2
    @test ocean.bc_east == 1
    @test ocean.bc_north == 1
    @test ocean.bc_south == 2

    Granular.setGridBoundaryConditions!(ocean, "inactive", "all", verbose=false)
    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "periodic", "north, east",
                                        verbose=true)
    close(out_w)
    redirect_stdout(originalSTDOUT)
    output = String(readavailable(out_r))
    @test output == """West  (-x): inactive\t(1)
    East  (+x): periodic\t(2)
    South (-y): inactive\t(1)
    North (+y): periodic\t(2)
    """
    @test ocean.bc_west == 1
    @test ocean.bc_east == 2
    @test ocean.bc_north == 2
    @test ocean.bc_south == 1

    Granular.setGridBoundaryConditions!(ocean, "inactive", "all", verbose=false)
    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "periodic", "+y, +x",
                                        verbose=true)
    close(out_w)
    redirect_stdout(originalSTDOUT)
    output = String(readavailable(out_r))
    @test output == """West  (-x): inactive\t(1)
    East  (+x): periodic\t(2)
    South (-y): inactive\t(1)
    North (+y): periodic\t(2)
    """
    @test ocean.bc_west == 1
    @test ocean.bc_east == 2
    @test ocean.bc_north == 2
    @test ocean.bc_south == 1

    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "inactive", "all", verbose=false)
    close(out_w)
    redirect_stdout(originalSTDOUT)
    output = String(readavailable(out_r))
    @test output == ""
    @test ocean.bc_west == 1
    @test ocean.bc_east == 1
    @test ocean.bc_north == 1
    @test ocean.bc_south == 1

    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "periodic", "all")
    close(out_w)
    output = String(readavailable(out_r))
    redirect_stdout(originalSTDOUT)
    @test output == """West  (-x): periodic\t(2)
    East  (+x): periodic\t(2)
    South (-y): periodic\t(2)
    North (+y): periodic\t(2)
    """
    @test ocean.bc_west == 2
    @test ocean.bc_east == 2
    @test ocean.bc_north == 2
    @test ocean.bc_south == 2

    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "inactive")
    close(out_w)
    output = String(readavailable(out_r))
    redirect_stdout(originalSTDOUT)
    @test output == """West  (-x): inactive\t(1)
    East  (+x): inactive\t(1)
    South (-y): inactive\t(1)
    North (+y): inactive\t(1)
    """
    @test ocean.bc_west == 1
    @test ocean.bc_east == 1
    @test ocean.bc_north == 1
    @test ocean.bc_south == 1

    (out_r, out_w) = redirect_stdout()
    Granular.setGridBoundaryConditions!(ocean, "periodic")
    close(out_w)
    output = String(readavailable(out_r))
    redirect_stdout(originalSTDOUT)
    @test output == """West  (-x): periodic\t(2)
    East  (+x): periodic\t(2)
    South (-y): periodic\t(2)
    North (+y): periodic\t(2)
    """
    @test ocean.bc_west == 2
    @test ocean.bc_east == 2
    @test ocean.bc_north == 2
    @test ocean.bc_south == 2

    @test_throws ErrorException Granular.setGridBoundaryConditions!(ocean,
                                                                    "periodic",
                                                                    "asdf")

    @test_throws ErrorException Granular.setGridBoundaryConditions!(ocean,
                                                                    "asdf")
end

@info "Testing granular interaction across periodic boundaries"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic")
Granular.addGrainCylindrical!(sim, [0.1, 0.5], 0.11, 0.1, verbose=false)
Granular.addGrainCylindrical!(sim, [0.9, 0.5], 0.11, 0.1, verbose=false)

# there should be an error if all-to-all contact search is used
@test_throws ErrorException Granular.findContacts!(sim)
@test_throws ErrorException Granular.findContacts!(sim, method="all to all")
@test_throws ErrorException Granular.findContactsAllToAll!(sim)

Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=false)
Granular.findContacts!(sim, method="ocean grid")
@test 2 == sim.grains[1].contacts[1]
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts


@info "Test grain position adjustment across periodic boundaries"
# do not readjust inside grid, inactive boundaries
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "inactive", verbose=false)
Granular.addGrainCylindrical!(sim, [0.1, 0.5], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.1, 0.5, 0.] ≈ sim.grains[1].lin_pos

# do not readjust inside grid, periodic boundaries
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=false)
Granular.addGrainCylindrical!(sim, [0.1, 0.5], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.1, 0.5, 0.] ≈ sim.grains[1].lin_pos

# do not readjust outside grid, inactive boundaries
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "inactive", verbose=false)
Granular.addGrainCylindrical!(sim, [-0.1, 0.5], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [-0.1, 0.5, 0.] ≈ sim.grains[1].lin_pos

# readjust outside grid, periodic boundaries, -x
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=false)
Granular.addGrainCylindrical!(sim, [-0.1, 0.5], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.9, 0.5, 0.] ≈ sim.grains[1].lin_pos

# readjust outside grid, periodic boundaries, +x
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=false)
Granular.addGrainCylindrical!(sim, [1.1, 0.5], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.1, 0.5, 0.] ≈ sim.grains[1].lin_pos

# readjust outside grid, periodic boundaries, -y
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=false)
Granular.addGrainCylindrical!(sim, [0.3, -0.1], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.3, 0.9, 0.] ≈ sim.grains[1].lin_pos

# readjust outside grid, periodic boundaries, +y
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=false)
Granular.addGrainCylindrical!(sim, [0.3, 1.1], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.3, 0.1, 0.] ≈ sim.grains[1].lin_pos

# throw error if atmosphere and ocean BCs differ
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
sim.atmosphere = Granular.createRegularAtmosphereGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=false)
Granular.addGrainCylindrical!(sim, [0.3, 1.1], 0.11, 0.1, verbose=false)
@test_throws ErrorException Granular.moveGrainsAcrossPeriodicBoundaries!(sim)


@info "## Impermeable BCs"

@info "Test grain velocity adjustment across impermeable boundaries"
# do not readjust inside grid, inactive boundaries
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([5, 5, 2], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "inactive", verbose=false)
Granular.addGrainCylindrical!(sim, [0.1, 0.5], 0.11, 0.1, verbose=false)
Granular.moveGrainsAcrossPeriodicBoundaries!(sim)
@test [0.1, 0.5, 0.] ≈ sim.grains[1].lin_pos
