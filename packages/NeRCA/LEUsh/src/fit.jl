struct SingleDUParams
    d::Float64
    t::Float64
    z::Float64
    dz::Float64
    ϕ::Float64
    t₀::Float64
end

struct ROyFit
    sdp::SingleDUParams
    sdp_initial::SingleDUParams
    Q::Float64
    selected_hits::Vector{CalibratedHit}
    model::Model
end

"""
    function slew(tot)

Return the time slewing for a ToT.
"""
function slew(tot)
    p₀ = 7.70824
    p₁ = 0.00879447
    p₂ = -0.0621101
    p₃ = -1.90226

    p₀ * ℯ^(p₁*√tot + p₂*tot) + p₃
end


"""
    function svdfit(hits::Vector{CalibratedHit})

Uses SVD to do a fast and dirty track prefit. Provide hits with a multiplicity
of at least 2.
"""
function svdfit(hits::Vector{CalibratedHit})
    t₀ = hits[div(length(hits), 2)].t
    pos, dir = svdfit(matrix([h.pos for h in hits]))
    if (last(hits).pos - first(hits).pos) ⋅ dir  < 0.0
        dir *= -1
    end
    return Track(dir, pos, t₀)
end


"""
    function prefit(hits::Vector{CalibratedHit})

Performs the prefit algorithm which was used in DUMAND II.
"""
function prefit(hits::Vector{CalibratedHit})
    N = length(hits)
    D = 0.0
    dir = [0.0, 0.0, 0.0]
    pos = [0.0, 0.0, 0.0]
    pes = [max(1, (h.tot - 26.3) / 4.5) for h in hits]
    # pes = [h.tot for h in hits]
    # pes = [h.multiplicity.count for h in hits]
    @inbounds for i ∈ 1:N
        @inbounds for k ∈ 1:N
            if i == k
                continue
            end
            t_i = hits[i].t
            t_k = hits[k].t
            q_ik = pes[i] * pes[k]
            t_ik = t_i * t_k
            pos += q_ik * (hits[i].pos*(t_k^2 - t_ik) + hits[k].pos*(t_i^2 - t_ik))
            dir += q_ik * (hits[i].pos - hits[k].pos) * (t_i - t_k)
            D += q_ik * (t_i - t_k)^2
        end
    end
    # dir = normalize(dir/D)
    return NeRCA.Track(dir/D, pos/D, 0)
end


"""
    function make_cherenkov_calculator(track::Track; v=2.99792458e8, n=1.35)

Returns a function which calculates the arrival time of a Cherenkov photon
at a given position.
"""
function make_cherenkov_calculator(track::Track; v=2.99792458e8)
    c_medium = c_0/N_SEAWATER
    β = v/c_0
    θ = acos(min(1/(β*N_SEAWATER), 1))
    θ′ = π - θ
    track_dir = normalize(track.dir)
    t₀ = track.time

    pos::Position -> begin

        # minimal distance between hit and track
        track_distance = pld3(track.pos, pos, track_dir)
        # the path the Cherenkov photon has to travel
        cherenkov_path_length = track_distance / sin(θ)
        distance_vector = pos - track.pos
        # distance between particle position and hit
        distance = norm(distance_vector)

        t_cherenkov = cherenkov_path_length / c_medium*1e9

        η = angle_between(track_dir, distance_vector)
        χ = θ - η
        particle_travel_path_length = distance / sin(θ′) * sin(χ)
        t = t₀ + particle_travel_path_length / v*1e9 + t_cherenkov
        return t
    end
end


"""
    function make_cherenkov_calculator(track::Track, event_info::Union{MCEventInfo,DAQEventInfo}; v=2.99792458e8)

Returns a function which calculates the arrival time of a Cherenkov photon
at a given position.
"""
function make_cherenkov_calculator(track::Track, event_info::Union{MCEventInfo,DAQEventInfo}; v=2.99792458e8)
    jte_time = make_mc_time_converter(event_info)(track.time)
    make_cherenkov_calculator(Track(track.dir, track.pos, jte_time), v=v)
end


"""
    function make_cherenkov_calculator(d_closest, t_closest, z_closest, dir_z, t₀)

Returns a function which calculates the arrival time of a Cherenkov photon
at a given position.
"""
function make_cherenkov_calculator(d_closest, t_closest, z_closest, dir_z, t₀)
    c_ns = c_0 / 1e9
    n = N_SEAWATER
    d_γ(z) = n/√(n^2 - 1) * √(d_closest^2 + (z-z_closest)^2 * (1 - dir_z^2))
    t(z) = (t₀) + 1/c_ns * ((z - z_closest)*dir_z + (n^2 - 1)/n * d_γ(z))
    d_γ, t
end

"""
    function make_cherenkov_calculator(sdp::SingleDUParams)

Returns a function which calculates the arrival time of a Cherenkov photon
at a given position.
"""
function make_cherenkov_calculator(sdp::SingleDUParams)
    c_ns = c_0 / 1e9
    n = N_SEAWATER
    d_γ(z) = n/√(n^2 - 1) * √(sdp.d^2 + (z-sdp.z)^2 * (1 - sdp.dz^2))
    t(z) = (sdp.t₀) + 1/c_ns * ((z - sdp.z)*sdp.dz + (n^2 - 1)/n * d_γ(z))
    d_γ, t
end



"""
    function single_du_params(track::NeRCA.Track)

Calculates five parameters to describe a track for a single DU case.
"""
function single_du_params(track::NeRCA.Track)
    c_ns = c_0 / 1e9
    pos = track.pos
    dir = Direction(normalize(track.dir))
    t₀ = track.time
    proj = pos ⋅ dir
    z_closest = (pos.z - dir.z*proj) / (1 - dir.z^2)
    t_closest = t₀ + (z_closest * dir.z - proj)/c_ns
    p_t_closest = pos + c_ns * (t_closest - t₀) * dir
    d_closest = √(p_t_closest[1]^2 + p_t_closest[2]^2)

    d_closest, t_closest, z_closest, dir.z, t₀
end


"""
    function single_du_params(t::NeRCA.MCTrack)

Calculates five parameters to describe a MC track for a single DU case.
"""
function single_du_params(t::NeRCA.MCTrack, time)
    single_du_params(NeRCA.Track([t.dir_x, t.dir_y, t.dir_z], [t.pos_x, t.pos_y, t.pos_z], time))
end


function cherenkov_plausible(Δt, Δz, time_extra=10)
    Δt < Δz * NeRCA.N_SEAWATER / NeRCA.c_0*1e9 + time_extra
end


function expand_hits!(hits::T, hit_pool::Dict{Int, T}; max_floor_distance=2) where T<:Vector{NeRCA.CalibratedHit}
    n = length(hits)
    expanded = false
    for i in 1:n
        hit = hits[i]
        time = hit.t
        floor = hit.floor
        z = hit.pos.z

        for Δfloor ∈ -max_floor_distance:max_floor_distance
            _hits = get(hit_pool, floor + Δfloor, T())
            for _hit ∈ _hits
                Δz = abs(z - _hit.pos.z)
                Δt = abs(time - _hit.t)
                if cherenkov_plausible(Δt, Δz)
                    push!(hits, _hit)
                    expanded = true
                end
            end
        end
    end
end


function create_hit_pool(hits::T) where T<:Vector{NeRCA.CalibratedHit}
    hit_pool = Dict{Int, T}()
    for hit in hits
        if !haskey(hit_pool, hit.floor)
            hit_pool[hit.floor] = T()
            sizehint!(hit_pool[hit.floor], length(hits))
        end
        push!(hit_pool[hit.floor], hit)
    end
    hit_pool
end


function select_hits(hits::T, hit_pool::Dict{Int, T}) where T<:Vector{NeRCA.CalibratedHit}

    thits = filter(h -> h.triggered, hits)
    shits = unique(h -> h.dom_id, thits)

    expand_hits!(shits, hit_pool)
    expand_hits!(shits, hit_pool)

    shits = unique(h -> h.dom_id, shits)

    return shits
end


struct SingleDUMinimiser <: Function
    z_positions::Vector{Float64}
    times::Vector{Float64}
    pmt_directions::Vector{Direction}
    multiplicities::Vector{Int}
end

function SingleDUMinimiser(hits::Vector{CalibratedHit}, triggered_hits::Vector{CalibratedHit})
    n = length(hits)
    n_triggered = length(triggered_hits)
    z_positions = Vector{Float64}()
    times = Vector{Float64}()
    multiplicities = Vector{Int32}()
    pmt_directions = Vector{Direction}()
    sizehint!(z_positions, n)
    sizehint!(times, n)
    sizehint!(multiplicities, n)
    sizehint!(pmt_directions, n_triggered)
    for i ∈ 1:n
        hit = hits[i]
        push!(z_positions, hit.pos.z)
        push!(times, hit.t)
        push!(multiplicities, hit.multiplicity.count)
    end
    for i ∈ 1:n_triggered
        push!(pmt_directions, triggered_hits[i].dir)
    end
    SingleDUMinimiser(z_positions, times, pmt_directions, multiplicities)
end


function (s::SingleDUMinimiser)(d_closest, t_closest, z_closest, dir_z, ϕ, t₀)
    n = length(s.times)

    d_γ, ccalc = make_cherenkov_calculator(d_closest, t_closest, z_closest, dir_z, t₀)
    expected_times = ccalc.(s.z_positions)

    max_multiplicity = maximum(s.multiplicities)
    Q = 0.0
    for i ∈ 1:n
        t = s.times[i]
        z = s.z_positions[i]
        m = s.multiplicities[i]
        t_exp = ccalc(z)
        Δt = abs(t - t_exp)
        Q += Δt^2 * m / max_multiplicity
    end

    Δts = abs.(s.times - expected_times) 
    # Δϕs = filter(!isnan, azimuth.(s.pmt_directions)) .- ϕ

    # return sum(Δts .^2) + sum(Δϕs.^2)/length(Δϕs)
    # return sum(Δts .^2)
    return Q
end

struct MultiDUMinimiser <: Function
    hits::Vector{CalibratedHit}
end
    
function (m::MultiDUMinimiser)(x, y, z, θ, ϕ, t₀)
    pos = Position(x, y, z)
    # dir = Direction(cos(θ)*cos(ϕ), cos(θ)*sin(ϕ), sin(θ))
    dir = Direction(ϕ, θ)
    track = Track(dir, pos, t₀)

    # ccalc = make_cherenkov_calculator(track, v=v*1e9)
    ccalc = make_cherenkov_calculator(track)

    Q = 0.0
    for hit in m.hits
        t_exp = ccalc(hit.pos)
        Δt = abs(hit.t - t_exp)
        # println("expected: $(t_exp), got: $(hit.t), delta: $(Δt)")
        Q += (Δt - 2)^2
    end
    Q
end

function multi_du_fit(prefit, hits; print_level=0)
    ϕ_start = NeRCA.azimuth(prefit.dir)
    θ_start = NeRCA.zenith(prefit.dir)
    t₀_start = prefit.time
    pos = prefit.pos

    m = NeRCA.MultiDUMinimiser(hits)

    model = Model(
        with_optimizer(Ipopt.Optimizer,
                       print_level=print_level,
                       max_iter=200,
                       tol=1e-3)
       )
    register(model, :qfunc, 6, m, autodiff=true)

    Δpos = 50

    @variable(model, pos.x - Δpos <= x <= pos.x + Δpos, start=pos.x)
    @variable(model, pos.y - Δpos <= y <= pos.y + Δpos, start=pos.y)
    @variable(model, pos.z - Δpos <= z <= pos.z + Δpos, start=pos.z)
    @variable(model, -1.0 <= θ <= 1.0, start=θ_start)
    @variable(model, -3*2π <= ϕ <= 3*2π, start=ϕ_start)
    @variable(model, t₀, start=t₀_start)

    @NLobjective(model, Min, qfunc(x, y, z, θ, ϕ, t₀))

    optimize!(model);

    return Track(Direction(value(ϕ), value(θ)), Position(value(x), value(y), value(z)), value(t₀))
end


function single_du_fit(du_hits::Vector{NeRCA.CalibratedHit}; print_level=0)
    sort!(du_hits, by = h -> h.t)
    sort!(du_hits, by=h->h.dom_id)
    count_multiplicities!(du_hits)

    hit_pool = create_hit_pool(du_hits)
    shits = select_hits(du_hits, hit_pool)

    qfunc = SingleDUMinimiser(shits, filter(h->h.triggered, du_hits))

    model = Model(with_optimizer(Ipopt.Optimizer, print_level=print_level, tol=1e-3))

    register(model, :qfunc, 6, qfunc, autodiff=true)

    brightest_floor = NeRCA.most_frequent(h -> h.floor, du_hits)

    hits_on_brightest_floor = filter(h -> h.floor == brightest_floor, du_hits)
    thits_on_brightest_floor = filter(h -> h.triggered, hits_on_brightest_floor)

    if length(thits_on_brightest_floor) == 0
        z_closest_start = hits_on_brightest_floor[1].pos.z
        hit_time = mean([h.t for h in hits_on_brightest_floor])
    else
        closest_hit = thits_on_brightest_floor[1]
        z_closest_start = closest_hit.pos.z
        hit_time = closest_hit.t
    end

    d_closest_start = 10.0
    t_closest_start = hit_time
    dir_z_start = -0.9
    ϕ_start = π
    t₀_start = hit_time

    max_z = maximum([h.pos.z for h in shits]) - 2*13
    min_z = minimum([h.pos.z for h in shits]) + 2*13
    if min_z > max_z
        min_z = abs(max_z - min_z) / 2
    end

    @variable(model, 1 <= d_closest <= 100, start=d_closest_start)
    @variable(model, hit_time - 1000 <= t_closest <= hit_time + 1000, start=t_closest_start)
    @variable(model, min_z <= z_closest <= max_z, start=z_closest_start)
    @variable(model, -1 <= dir_z <= 1, start=dir_z_start)
    @variable(model, 0 <= ϕ <= 2π, start=ϕ_start)
    @variable(model, t₀, start=t₀_start)

    @NLobjective(model, Min, qfunc(d_closest, t_closest, z_closest, dir_z, ϕ, t₀))

    optimize!(model);

    values = value(d_closest), value(t_closest), value(z_closest), value(dir_z), value(ϕ), value(t₀)
    sdp = SingleDUParams(values...)
    sdp_initial = SingleDUParams(d_closest_start, t_closest_start, z_closest_start, dir_z_start, ϕ_start, t₀_start)

    return ROyFit(sdp, sdp_initial, qfunc(values...)/length(shits), shits, model)
end
