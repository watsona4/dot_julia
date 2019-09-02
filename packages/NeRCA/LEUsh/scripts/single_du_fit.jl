using NeRCA
using Plots
using LinearAlgebra
using Optim
using JuMP
using GLPK
using Ipopt

const n = 1.35
const c = 2.99792458e8 / 1e9

struct SingleDUTrack
    distance
    t_closest
    z_closest
    dir_z
    t₀
end

function single_du_params(track::NeRCA.Track)
    pos = track.pos
    dir = Direction(normalize(track.dir))
    t₀ = track.time
    proj = pos ⋅ dir
    z_closest = (pos.z - dir.z*proj) / (1 - dir.z^2)
    t_closest = t₀ + (z_closest * dir.z - proj)/c
    p_t_closest = pos + c * (t_closest - t₀) * dir
    d_closest = √(p_t_closest[1]^2 + p_t_closest[2]^2)

    #SingleDUTrack(d_closest, t_closest, z_closest, dir.z, t₀)
    d_closest, t_closest, z_closest, dir.z, t₀
end


function make_cherenkov_calc(d_closest, t_closest, z_closest, dir_z, t₀)
    d_γ(z) = n/√(n^2 - 1) * √(d_closest^2 + (z-z_closest)^2 * (1 - dir_z^2))
    z -> begin
        (t_closest - t₀) + 1/c * ((z - z_closest)*dir_z + (n^2 - 1)/n * d_γ(z))
    end
end

dom_z_positions = range(120, length=18, stop=800)

track = NeRCA.Track([0, 1, 0.5], [0, 500, 500], 0)
sdp = single_du_params(track)
ccalc = make_cherenkov_calc(sdp...)
times = ccalc.(dom_z_positions) * 1e9
plot(times, dom_z_positions, seriestype = :scatter)


function make_quality_function(positions, times)
    function quality_function(d_closest, t_closest, z_closest, dir_z, t₀)
        ccalc = make_cherenkov_calc(d_closest, t_closest, z_closest, dir_z, t₀)
        expected_times = ccalc.(positions)
        return sum((times - expected_times).^2)
    end
    return quality_function
end


qfunc = make_quality_function(dom_z_positions, ccalc.(dom_z_positions))


model = Model(with_optimizer(Ipopt.Optimizer))

register(model, :qfunc, 5, qfunc, autodiff=true)

@variable(model, -1000 <= d_closest <= 1000)
@variable(model, -10000 <= t_closest <= 10000)
@variable(model, -1000 <= z_closest <= 1000)
@variable(model, -1 <= dir_z <= 1)
@variable(model, -1000 <= t₀ <= 1000)


@NLobjective(model, Min, qfunc(d_closest, t_closest, z_closest, dir_z, t₀))

optimize!(model)
termination_status(model)
value(d_closest)
value(t_closest)
value(z_closest)
value(dir_z)
value(t₀)


ccalc = make_cherenkov_calc(value(d_closest), value(t_closest), value(z_closest), value(dir_z), value(t₀))
times = ccalc.(dom_z_positions)
plot!(times, dom_z_positions, seriestype = :scatter)
