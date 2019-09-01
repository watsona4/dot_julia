#!/usr/bin/env julia
using Test
import Granular

# Check the contact search and geometry of a two-particle interaction

@info "Testing interGrainPositionVector(...) and findOverlap(...)"
sim = Granular.createSimulation("test")
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [ 0.01, 0.01], 10., 1., verbose=false)
Granular.addGrainCylindrical!(sim, [18.01, 0.01], 10., 1., verbose=false)

position_ij = Granular.interGrainPositionVector(sim, 1, 2)
overlap_ij = Granular.findOverlap(sim, 1, 2, position_ij)

@test [-18., 0., 0.] ≈ position_ij
@test -2. ≈ overlap_ij


@info "Testing findContactsAllToAll(...)"
sim_copy = deepcopy(sim)
Granular.findContactsAllToAll!(sim)


@info "Testing findContacts(...)"
sim = deepcopy(sim_copy)
Granular.findContacts!(sim)

sim.grains[1].enabled = false
# The contact should be registered in ice floe 1, but not ice floe 2
@test 2 == sim.grains[1].contacts[1]
@test [-18., 0., 0.] ≈ sim.grains[1].position_vector[1]
for ic=2:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts

@info "Testing findContacts(...)"
sim = deepcopy(sim_copy)
Granular.findContacts!(sim)

@test 2 == sim.grains[1].contacts[1]
@test [-18., 0., 0.] ≈ sim.grains[1].position_vector[1]
for ic=2:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts

@test_throws ErrorException Granular.findContacts!(sim, method="")

sim = deepcopy(sim_copy)
sim.grains[1].enabled = false
sim.grains[2].enabled = false
Granular.findContacts!(sim)
for ic=1:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 0 == sim.grains[1].n_contacts
@test 0 == sim.grains[2].n_contacts


sim = deepcopy(sim_copy)
Granular.disableGrain!(sim, 1)
Granular.findContacts!(sim)
for ic=1:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 0 == sim.grains[1].n_contacts
@test 0 == sim.grains[2].n_contacts


sim = deepcopy(sim_copy)
Granular.disableGrain!(sim, 1)
Granular.disableGrain!(sim, 2)
Granular.findContacts!(sim)
for ic=1:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 0 == sim.grains[1].n_contacts
@test 0 == sim.grains[2].n_contacts

@info "Testing if interact(...) removes contacts correctly"
sim = deepcopy(sim_copy)
Granular.findContacts!(sim)
Granular.interact!(sim)
Granular.findContacts!(sim)

@test 2 == sim.grains[1].contacts[1]
@test [-18., 0., 0.] ≈ sim.grains[1].position_vector[1]
for ic=2:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts


@info "Testing findContactsGrid(...)"
sim = deepcopy(sim_copy)
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [80., 80., 2.])
Granular.sortGrainsInGrid!(sim, sim.ocean)
Granular.findContactsInGrid!(sim, sim.ocean)

@test 2 == sim.grains[1].contacts[1]
for ic=2:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts


sim = deepcopy(sim_copy)
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [80., 80., 2.])
sim.grains[1].fixed = true
Granular.sortGrainsInGrid!(sim, sim.ocean)
Granular.findContactsInGrid!(sim, sim.ocean)

@test 2 == sim.grains[1].contacts[1]
for ic=2:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts


sim = deepcopy(sim_copy)
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [80., 80., 2.])
sim.grains[1].enabled = false
sim.grains[2].enabled = false
Granular.sortGrainsInGrid!(sim, sim.ocean)
Granular.findContactsInGrid!(sim, sim.ocean)

for ic=1:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 0 == sim.grains[1].n_contacts
@test 0 == sim.grains[2].n_contacts

@info "Testing findContacts(...)"
sim = deepcopy(sim_copy)
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [80., 80., 2.])
Granular.sortGrainsInGrid!(sim, sim.ocean)
Granular.findContacts!(sim)

@test 2 == sim.grains[1].contacts[1]
for ic=2:sim.Nc_max
    @test 0 == sim.grains[1].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[1].contact_parallel_displacement[ic]
end
for ic=1:sim.Nc_max
    @test 0 == sim.grains[2].contacts[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].position_vector[ic]
    @test [0., 0., 0.] ≈ sim.grains[2].contact_parallel_displacement[ic]
end
@test 1 == sim.grains[1].n_contacts
@test 1 == sim.grains[2].n_contacts

@test_throws ErrorException Granular.findContacts!(sim, method="")

@info "Testing contact registration with multiple contacts"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [2., 2.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [4., 2.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [6., 2.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [2., 4.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [4., 4.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [6., 4.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [2., 6.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [4., 6.], 1.01, 1., verbose=false)
Granular.addGrainCylindrical!(sim, [6., 6.], 1.01, 1., verbose=false)
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [8., 8., 2.])
Granular.sortGrainsInGrid!(sim, sim.ocean)
Granular.findContacts!(sim)
@test 2 == sim.grains[1].n_contacts
@test 3 == sim.grains[2].n_contacts
@test 2 == sim.grains[3].n_contacts
@test 3 == sim.grains[4].n_contacts
@test 4 == sim.grains[5].n_contacts
@test 3 == sim.grains[6].n_contacts
@test 2 == sim.grains[7].n_contacts
@test 3 == sim.grains[8].n_contacts
@test 2 == sim.grains[9].n_contacts
Granular.interact!(sim)
Granular.interact!(sim)
Granular.interact!(sim)
Granular.interact!(sim)
@test 2 == sim.grains[1].n_contacts
@test 3 == sim.grains[2].n_contacts
@test 2 == sim.grains[3].n_contacts
@test 3 == sim.grains[4].n_contacts
@test 4 == sim.grains[5].n_contacts
@test 3 == sim.grains[6].n_contacts
@test 2 == sim.grains[7].n_contacts
@test 3 == sim.grains[8].n_contacts
@test 2 == sim.grains[9].n_contacts
for i=1:9
    sim.grains[i].contact_radius = 0.99
end
Granular.interact!(sim)
for i=1:9
    @test sim.grains[i].n_contacts == 0
end

@info "Test contact search in regular square grid (all to all)"
sim = Granular.createSimulation()
nx = 60; ny = 50
Granular.regularPacking!(sim, [nx, ny], 1., 1., padding_factor=0,
                         tiling="square")
for grain in sim.grains
    grain.contact_radius *= 1.00001
end
Granular.findContacts!(sim)
#Granular.plotGrains(sim)
for j=2:(ny-1)
    for i=2:(nx-1)
        idx = (j - 1)*nx + i
        @test sim.grains[idx].n_contacts == 4
    end
end

@info "Test contact search in regular square grid (sorting grid)"
sim = Granular.createSimulation()
nx = 60; ny = 50
Granular.regularPacking!(sim, [nx, ny], 1., 1., padding_factor=0,
                         tiling="square")
Granular.fitGridToGrains!(sim, sim.ocean, verbose=false)
for grain in sim.grains
    grain.contact_radius *= 1.00001
end
Granular.findContacts!(sim)
#Granular.plotGrains(sim)
for j=2:(ny-1)
    for i=2:(nx-1)
        idx = (j - 1)*nx + i
        @test sim.grains[idx].n_contacts == 4
    end
end

@info "Test changes to the max. number of contacts"
sim = Granular.createSimulation()
nx = 60; ny = 50
Granular.regularPacking!(sim, [nx, ny], 1., 1., padding_factor=0,
                         tiling="square")
@test 32 == sim.Nc_max
@test_throws ErrorException Granular.setMaximumNumberOfContactsPerGrain!(sim, 0)
@test_throws ErrorException Granular.setMaximumNumberOfContactsPerGrain!(sim,-1)
@test_throws ErrorException Granular.setMaximumNumberOfContactsPerGrain!(sim,32)

for Nc_max in [4, 32, 33, 100, 1]
    @info("Nc_max = $Nc_max")
    Granular.setMaximumNumberOfContactsPerGrain!(sim, Nc_max)
    for grain in sim.grains
        @test length(grain.contacts) == Nc_max
        @test length(grain.position_vector) == Nc_max
        @test length(grain.contact_rotation) == Nc_max
        @test length(grain.contact_age) == Nc_max
        @test length(grain.contact_area) == Nc_max
        @test length(grain.compressive_failure) == Nc_max
    end
end
