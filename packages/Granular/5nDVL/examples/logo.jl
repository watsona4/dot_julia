#!/usr/bin/env julia

import Granular
using Random

let

verbose = true

text = "Granular.jl"

#forcing = "gyres"
forcing = "down"
#forcing = "convergent"

# Font created with `figlet` and the font 'pebbles'.
#logo_string = read(`figlet -f pebbles "$text"`, String)

# If figlet is not installed on your system, use the string below:
logo_string = 
""" .oOOOo.                               o                       o 
.O     o                              O                     O O  
o                                     o                       o  
O                                     O                       O  
O   .oOOo `OoOo. .oOoO' 'OoOo. O   o  o  .oOoO' `OoOo.     'o o  
o.      O  o     O   o   o   O o   O  O  O   o   o          O O  
 O.    oO  O     o   O   O   o O   o  o  o   O   O     oO   o o  
  `OooO'   o     `OoO'o  o   O `OoO'o Oo `OoO'o  o     Oo   O Oo 
                                                            o    
                                                          oO'    """

dx = 1.
dy = dx

logo_string_split = split(logo_string, '\n')

ny = length(logo_string_split)
maxwidth = 0
for i=1:ny
    if maxwidth < length(logo_string_split[i])
        maxwidth = length(logo_string_split[i])
    end
end
nx = maxwidth + 1

Lx = nx*dx
Ly = (ny + 1)*dy

x = 0.
y = 0.
r = 0.
c = ' '
h = .5
youngs_modulus = 2e6

sim = Granular.createSimulation(id="logo")

print(logo_string)
@info "nx = $nx, ny = $ny"

for iy=1:length(logo_string_split)
    for ix=1:length(logo_string_split[iy])

        c = logo_string_split[iy][ix]

        if c == ' '
            continue
        elseif c == 'O'
            x = ix*dx - .5*dx
            y = Ly - (iy*dy - .5*dy)
            r = .5*dx
        elseif c == 'o'
            x = ix*dx - .5*dx
            y = Ly - (iy*dy - .33*dy)
            r = .33*dx
        elseif c == 'o'
            x = ix*dx - .5*dx
            y = Ly - (iy*dy - .25*dy)
            r = .25*dx
        elseif c == '\''
            x = ix*dx - .75*dx
            y = Ly - (iy*dy - .75*dy)
            r = .25*dx
        elseif c == '`'
            x = ix*dx - .25*dx
            y = Ly - (iy*dy - .75*dy)
            r = .25*dx
        end

        if r > 0.
            Granular.addGrainCylindrical!(sim, [x + dx, y - dy], r, h,
                                            tensile_strength=200e3,
                                            youngs_modulus=youngs_modulus,
                                            verbose=verbose)
        end
        r = -1.
    end
end

# set ocean forcing
sim.ocean = Granular.createRegularOceanGrid([nx, ny, 1], [Lx, Ly, 1.],
name="logo_ocean")

if forcing == "gyres"
    epsilon = 0.25  # amplitude of periodic oscillations
    t = 0.
    a = epsilon*sin(2.0*pi*t)
    b = 1.0 - 2.0*epsilon*sin(2.0*pi*t)
    for i=1:size(sim.ocean.u, 1)
        for j=1:size(sim.ocean.u, 2)

            x = sim.ocean.xq[i, j]/(Lx*.5)  # x in [0;2]
            y = sim.ocean.yq[i, j]/Ly       # y in [0;1]

            f = a*x^2.0 + b*x
            df_dx = 2.0*a*x + b

            sim.ocean.u[i, j, 1, 1] = -pi/10.0*sin(pi*f)*cos(pi*y) * 2e1
            sim.ocean.v[i, j, 1, 1] = pi/10.0*cos(pi*f)*sin(pi*y)*df_dx * 2e1
        end
    end

elseif forcing == "down"
    Random.seed!(1)
    sim.ocean.u[:, :, 1, 1] = (rand(nx+1, ny+1) .- 0.5) .* 0.1
    sim.ocean.v[:, :, 1, 1] .= -5.0

elseif forcing == "convergent"
    Random.seed!(1)
    sim.ocean.u[:, :, 1, 1] = (rand(nx+1, ny+1) .- 0.5) .* 0.1
    for j=1:size(sim.ocean.u, 2)
        sim.ocean.v[:, j, 1, 1] = -(j/ny - 0.5)*10.0
    end

else
    error("Forcing not understood")
end

# Initialize confining walls, which are ice floes that are fixed in space
r = dx/4.

## N-S wall segments
for y in range(r, stop=Ly-r, length=Int(round((Ly - 2.0*r)/(r*2))))
    Granular.addGrainCylindrical!(sim, [r, y], r, h, fixed=true,
                                  youngs_modulus=youngs_modulus,
                                  verbose=false)
    Granular.addGrainCylindrical!(sim, [Lx-r, y], r, h, fixed=true,
                                  youngs_modulus=youngs_modulus,
                                  verbose=false)
end

## E-W wall segments
for x in range(3.0*r, stop=Lx-3.0*r, length=Int(round((Lx - 6.0*r)/(r*2))))
    Granular.addGrainCylindrical!(sim, [x, r], r, h, fixed=true,
                                  youngs_modulus=youngs_modulus,
                                  verbose=false)
    Granular.addGrainCylindrical!(sim, [x, Ly-r], r, h, fixed=true,
                                  youngs_modulus=youngs_modulus,
                                  verbose=false)
end


# Finalize setup and start simulation
Granular.setTimeStep!(sim, verbose=verbose)

Granular.setTotalTime!(sim, 5.)
Granular.setOutputFileInterval!(sim, .1)

Granular.removeSimulationFiles(sim)
Granular.run!(sim, verbose=verbose)

# Granular.render(sim, images=true, animation=false, reverse=true)

# run(`convert -delay 100 logo/logo.0000.png -delay 10 logo/logo.'*'.png -trim
#     +repage -delay 10 -transparent-color white -quiet -layers OptimizePlus
#     -loop 0 logo.gif`)
end
