using NeRCA
using Optim

track = NeRCA.Track([0, 0, 0.2], [0, 200, 300])
ccalc = NeRCA.make_cherenkov_calculator(track)
hit_positions = [Position(0, 0, 0),
                 Position(20, 50, 100),
                 Position(100, -40, 400),
                 Position(23, 56, 50)]
hit_positions = [Position(0, 0, z) for z in 1:20:800]
times = ccalc.(hit_positions)

function make_quality_function(positions, times)
    function quality_function(params)
        x, y, z, dx, dy, dz = params
        track = NeRCA.Track([dx, dy, dz], [x, y, z])
        ccalc = NeRCA.make_cherenkov_calculator(track)
        expected_times = ccalc.(positions)
        return sum((times - expected_times).^2)
    end
    return quality_function
end

qfunc = make_quality_function(hit_positions, times)
qfunc([100,200,300,0,1,0])

function make_single_du_quality_function(positions, times)
    function quality_function(params)
        z, d, θ = params
        track = NeRCA.Track([0, sin(θ), cos(θ)], [0, d, z])
        ccalc = NeRCA.make_cherenkov_calculator(track)
        expected_times = ccalc.(positions)
        return sum((times - expected_times).^2)
    end
    return quality_function
end

qfunc = make_single_du_quality_function(hit_positions, times)
qfunc([300, 200, 0.2])
