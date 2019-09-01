#!/usr/bin/env julia
import Granular
using Random

sim = Granular.createSimulation(id="strait")
n = [10, 10, 2]

#sim = Granular.createSimulation(id="nares_strait_coarse_elast")
#n = [6, 6, 2]

# Initialize ocean
Lx = 50.e3
Lx_constriction = 5e3
L = [Lx, Lx*1.5, 1e3]
Ly_constriction = 20e3
sim.ocean = Granular.createRegularOceanGrid(n, L, name="poiseuille_flow")
sim.ocean.v[:, :, 1, 1] = 1e-8.*((sim.ocean.xq .- Lx/2.).^2.0 .- Lx^2.0/4.0)

# Initialize confining walls, which are grains that are fixed in space
r = minimum(L[1:2]/n[1:2])/2.
r_min = r/4.
h = 1.

## N-S segments
r_walls = r_min
for y in range((L[2] - Ly_constriction)/2.,
               stop=Ly_constriction + (L[2] - Ly_constriction)/2.0, 
               length=Int(round(Ly_constriction/(r_walls*2))))
    Granular.addGrainCylindrical!(sim, [(Lx - Lx_constriction)/2.0, y],
                                    r_walls, 
                                    h, fixed=true, verbose=false)
end
for y in range((L[2] - Ly_constriction)/2.0,
               stop=Ly_constriction + (L[2] - Ly_constriction)/2.0, 
               length=Int(round(Ly_constriction/(r_walls*2))))
    Granular.addGrainCylindrical!(sim,
                                  [Lx_constriction +
                                   (L[1] - Lx_constriction)/2.0, y], r_walls, h, 
                                   fixed=true, verbose=false)
end

dx = 2.0*r_walls*sin(atan((Lx - Lx_constriction)/(L[2] - Ly_constriction)))

## NW diagonal
x = r_walls:dx:((Lx - Lx_constriction)/2.)
y = range(L[2] - r_walls,
          stop=(L[2] - Ly_constriction)/2. + Ly_constriction + r_walls,
          length=length(x))
for i in 1:length(x)
    Granular.addGrainCylindrical!(sim, [x[i], y[i]], r_walls, h, fixed=true, 
                                  verbose=false)
end

## NE diagonal
x = (L[1] - r_walls):(-dx):((Lx - Lx_constriction)/2. + Lx_constriction)
y = range(L[2] - r_walls,
          stop=(L[2] - Ly_constriction)/2. + Ly_constriction + r_walls,
          length=length(x))
for i in 1:length(x)
    Granular.addGrainCylindrical!(sim, [x[i], y[i]], r_walls, h, fixed=true, 
                                    verbose=false)
end

## SW diagonal
x = r_walls:dx:((Lx - Lx_constriction)/2.)
y = range(r, stop=(L[2] - Ly_constriction)/2.0 - r_walls,
          length=length(x))
for i in 1:length(x)
    Granular.addGrainCylindrical!(sim, [x[i], y[i]], r_walls, h, fixed=true, 
                                    verbose=false)
end

## SE diagonal
x = (L[1] - r_walls):(-dx):((Lx - Lx_constriction)/2. + Lx_constriction)
y = range(r_walls, stop=(L[2] - Ly_constriction)/2. - r_walls, length=length(x))
for i in 1:length(x)
    Granular.addGrainCylindrical!(sim, [x[i], y[i]], r_walls, h, fixed=true, 
                                    verbose=false)
end

n_walls = length(sim.grains)
@info "added $(n_walls) fixed grains as walls"

# Initialize grains in wedge north of the constriction
dy = sqrt((2.0*r_walls)^2.0 - dx^2.0)
spacing_to_boundaries = 4.0*r
floe_padding = 0.5*r
noise_amplitude = floe_padding
Random.seed!(1)
let
iy = 1
for y in (L[2] - r - noise_amplitude):(-(2.0*r + floe_padding)):((L[2] - 
    Ly_constriction)/2.0 + Ly_constriction)
    for x in (r + noise_amplitude):(2.0*r + floe_padding):(Lx - r - 
                                                          noise_amplitude)
        if iy % 2 == 0
            x += 1.5*r
        end

        x_ = x + noise_amplitude*(0.5 - rand())
        y_ = y + noise_amplitude*(0.5 - rand())

        if y_ < -dy/dx*x_ + L[2] + spacing_to_boundaries
            continue
        end
            
        if y_ < dy/dx*x_ + (L[2] - dy/dx*Lx) + spacing_to_boundaries
            continue
        end
            
        r_rand = r_min + rand()*(r - r_min)
        Granular.addGrainCylindrical!(sim, [x_, y_], r_rand, h, verbose=false)
    end
    iy += 1
end
end
n = length(sim.grains) - n_walls
@info "added $n grains"

# Remove old simulation files
Granular.removeSimulationFiles(sim)

k_n = 1e7  # N/m
k_t = k_n
#gamma_t = 1e7  # N/(m/s)
gamma_t = 0.0
mu_d = 0.7
rotating = true
for i=1:length(sim.grains)
    sim.grains[i].contact_stiffness_normal = k_n
    sim.grains[i].contact_stiffness_tangential = k_t
    sim.grains[i].contact_viscosity_tangential = gamma_t
    sim.grains[i].contact_dynamic_friction = mu_d
    sim.grains[i].rotating = rotating
end

# Set temporal parameters
Granular.setTotalTime!(sim, 6.0*60.0*60.0)
Granular.setOutputFileInterval!(sim, 60.0)
Granular.setTimeStep!(sim)

# Run simulation for 10 time steps, then add new grains the top
while sim.time < sim.time_total
    for it=1:10
        Granular.run!(sim, status_interval=1, single_step=true)
    end
    for i=1:size(sim.ocean.xh, 1)
        if sim.ocean.grain_list[i, end] == []

            x, y = Granular.getCellCenterCoordinates(sim.ocean.xh,
                                                     sim.ocean.yh,
                                                     i, size(sim.ocean.xh, 2))

            # Enable for high mass flux
            r_rand = r_min + rand()*(r - r_min)
            Granular.addGrainCylindrical!(sim, [x-r, y-r], r_rand, h, 
                    verbose=false,
                    contact_stiffness_normal=k_n,
                    contact_stiffness_tangential=k_t,
                    contact_viscosity_tangential=gamma_t,
                    contact_dynamic_friction = mu_d,
                    rotating=rotating)
            r_rand = r_min + rand()*(r - r_min)
            Granular.addGrainCylindrical!(sim, [x+r, y-r], r_rand, h, 
                    verbose=false,
                    contact_stiffness_normal=k_n,
                    contact_stiffness_tangential=k_t,
                    contact_viscosity_tangential=gamma_t,
                    contact_dynamic_friction = mu_d,
                    rotating=rotating)
            r_rand = r_min + rand()*(r - r_min)
            Granular.addGrainCylindrical!(sim, [x+r, y+r], r_rand, h, 
                    verbose=false,
                    contact_stiffness_normal=k_n,
                    contact_stiffness_tangential=k_t,
                    contact_viscosity_tangential=gamma_t,
                    contact_dynamic_friction = mu_d,
                    rotating=rotating)
            r_rand = r_min + rand()*(r - r_min)
            Granular.addGrainCylindrical!(sim, [x-r, y+r], r_rand, h, 
                    verbose=false,
                    contact_stiffness_normal=k_n,
                    contact_stiffness_tangential=k_t,
                    contact_viscosity_tangential=gamma_t,
                    contact_dynamic_friction = mu_d,
                    rotating=rotating)

            # Enable for low mass flux
            #x += noise_amplitude*(0.5 - rand())
            #y += noise_amplitude*(0.5 - rand())
            #Granular.addGrainCylindrical!(sim, [x, y], r, h, verbose=false)
        end
    end
end
