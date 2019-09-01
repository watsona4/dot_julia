#!/usr/bin/env julia

# Check the contact search and geometry of a two-particle interaction

@info "Writing simple simulation to VTK file"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 1., verbose=false)
Granular.addGrainCylindrical!(sim, [18., 0.], 10., 1., verbose=false)
sim.ocean = Granular.createRegularOceanGrid([10, 20, 5], [10., 25., 2.])  
Granular.findContacts!(sim, method="all to all")
Granular.writeVTK(sim, verbose=false)

cmd_post = ""
if Sys.islinux()
    cmd = "sha256sum"
elseif Sys.isapple()
    cmd = ["shasum", "-a", "256"]
elseif Sys.iswindows()
    @info "checksum verification not yet implemented on Windows"
    exit()
    cmd = ["powershell", "-Command", "\"Get-FileHash", "-Algorithm", "SHA256"]
    cmd_post = "\""
else
    error("checksum verification of VTK file not supported on this platform")
end

grainpath = "test/test.grains.1.vtu"
grainchecksum = 
"a698c24d46d15db97bb4d77d11ef1381d6cdf6536606d5c6482b063f47a20f68  " *
grainpath * "\n"

graininteractionpath = "test/test.grain-interaction.1.vtp"
graininteractionchecksum = 
"b8e49252a0ac87c2fce05e68ffab46589853429dc9f75d89818e4a37b953b137  " *
graininteractionpath * "\n"

oceanpath = "test/test.ocean.1.vts"
oceanchecksum =
"b65f00942f1cbef7335921948c9eb73d137574eb806c33dea8b0e9b638665f3b  " *
oceanpath * "\n"

@test read(`$(cmd) $(grainpath)$(cmd_post)`, String) == grainchecksum
@test read(`$(cmd) $(graininteractionpath)$(cmd_post)`, String) == 
    graininteractionchecksum
@test read(`$(cmd) $(oceanpath)$(cmd_post)`, String) == oceanchecksum

Granular.removeSimulationFiles(sim)

@info "Testing VTK write during run!()"
Granular.setOutputFileInterval!(sim, 1e-9)
Granular.setTotalTime!(sim, 1.5)
Granular.setTimeStep!(sim)
sim.file_number = 0
Granular.run!(sim, single_step=true)
@test Granular.readSimulationStatus(sim.id) == 1
@test Granular.readSimulationStatus(sim) == 1
Granular.setOutputFileInterval!(sim, 0.1)
Granular.run!(sim)

@info "Testing status output"
Granular.status()
Granular.status(colored_output=false)
dir = "empty_directory"
isdir(dir) || mkdir(dir)
#@test_warn "no simulations found in $(pwd())/$(dir)" Granular.status(dir)
Granular.status(dir)
rm(dir)

@info "Testing generation of Paraview Python script"
Granular.writeParaviewPythonScript(sim,
                                 save_animation=true,
                                 save_images=false)
@test isfile("$(sim.id)/$(sim.id).py") && filesize("$(sim.id)/$(sim.id).py") > 0

@info "Testing Paraview rendering if `pvpython` is present"
try
    run(`pvpython $(sim.id)/$(sim.id).py`)
catch return_signal
    if !isa(return_signal, Base.IOError)
        @test isfile("$(sim.id)/$(sim.id).avi")
    end
end

Granular.writeParaviewPythonScript(sim,
                                 save_animation=false,
                                 save_images=true)
try
    run(`pvpython $(sim.id)/$(sim.id).py`)
catch return_signal
    if !isa(return_signal, Base.IOError)
        @test isfile("$(sim.id)/$(sim.id).0000.png")
        @test isfile("$(sim.id)/$(sim.id).0014.png")
        Granular.render(sim)
        @test isfile("$(sim.id)/$(sim.id).0001.png")
    end
end

@test read(`$(cmd) $(grainpath)$(cmd_post)`, String) == grainchecksum
@test read(`$(cmd) $(graininteractionpath)$(cmd_post)`, String) == 
    graininteractionchecksum
@test read(`$(cmd) $(oceanpath)$(cmd_post)`, String) == oceanchecksum

@info "Writing simple simulation to VTK file"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 1., youngs_modulus=0., verbose=false)
Granular.addGrainCylindrical!(sim, [18., 0.], 10., 1., youngs_modulus=0., verbose=false)
sim.ocean = Granular.createRegularOceanGrid([10, 20, 5], [10., 25., 2.])
sim.atmosphere = Granular.createRegularAtmosphereGrid([10, 20, 5], [10., 25., 2.])
Granular.findContacts!(sim, method="all to all")
Granular.writeVTK(sim, verbose=false)

Granular.removeSimulationFiles(sim)
