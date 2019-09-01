

function dubins_LSL(intermediate_results::DubinsIntermediateResults)

    out = Vector{Float64}(undef,3)
    tmp0 = intermediate_results.d + intermediate_results.sa - intermediate_results.sb
    p_sq = 2 + intermediate_results.d_sq - (2*intermediate_results.c_ab) +
            (2 * intermediate_results.d * (intermediate_results.sa - intermediate_results.sb))
    tmp0 = round(tmp0; digits=10)
    p_sq = round(p_sq; digits=10)

    if p_sq >= 0
        tmp1 = atan((intermediate_results.cb - intermediate_results.ca), tmp0)
        tmp1 = round(tmp1; digits=10)
        out[1] = mod2pi(tmp1 - intermediate_results.α)
        out[2] = sqrt(p_sq)
        out[3] = mod2pi(intermediate_results.β - tmp1)
        return EDUBOK, out
    end

    return EDUBNOPATH, nothing
end

function dubins_RSR(intermediate_results::DubinsIntermediateResults)

    out = Vector{Float64}(undef, 3)
    tmp0 = intermediate_results.d - intermediate_results.sa + intermediate_results.sb
    p_sq = 2 + intermediate_results.d_sq - (2 * intermediate_results.c_ab) +
            (2 * intermediate_results.d * (intermediate_results.sb - intermediate_results.sa))
    tmp0 = round(tmp0; digits=10)
    p_sq = round(p_sq; digits=10)

    if p_sq >= 0
        tmp1 = atan((intermediate_results.ca - intermediate_results.cb), tmp0)
        tmp1 = round(tmp1; digits=10)
        out[1] = mod2pi(intermediate_results.α - tmp1)
        out[2] = sqrt(p_sq)
        out[3] = mod2pi(tmp1 -intermediate_results.β)
        return EDUBOK, out
    end

    return EDUBNOPATH, nothing
end

function dubins_LSR(intermediate_results::DubinsIntermediateResults)

    out = Vector{Float64}(undef,3)
    p_sq = -2 + (intermediate_results.d_sq) + (2 * intermediate_results.c_ab) +
                    (2 * intermediate_results.d * (intermediate_results.sa + intermediate_results.sb))
    p_sq = round(p_sq; digits=10)

    if p_sq >= 0
        p = sqrt(p_sq)
        tmp0 = atan((-intermediate_results.ca - intermediate_results.cb),
                    (intermediate_results.d + intermediate_results.sa + intermediate_results.sb)) - atan(-2.0, p)
        tmp0 = round(tmp0; digits=10)
        out[1] = mod2pi(tmp0 - intermediate_results.α)
        out[2] = p
        out[3] = mod2pi(tmp0 - mod2pi(intermediate_results.β))
        return EDUBOK, out
    end

    return EDUBNOPATH, nothing
end

function dubins_RSL(intermediate_results::DubinsIntermediateResults)

    out = Vector{Float64}(undef,3)
    p_sq = -2 + intermediate_results.d_sq + (2 * intermediate_results.c_ab) -
            (2 * intermediate_results.d * (intermediate_results.sa + intermediate_results.sb))
    p_sq = round(p_sq; digits=10)

    if p_sq >= 0
        p = sqrt(p_sq)
        tmp0 = atan((intermediate_results.ca + intermediate_results.cb),
                        (intermediate_results.d - intermediate_results.sa - intermediate_results.sb)) - atan(2.0, p)
        tmp0 = round(tmp0; digits=10)
        out[1] = mod2pi(intermediate_results.α - tmp0)
        out[2] = p
        out[3] = mod2pi(intermediate_results.β - tmp0)
        return EDUBOK, out
    end

    return EDUBNOPATH, nothing
end

function dubins_RLR(intermediate_results::DubinsIntermediateResults)

    out = Vector{Float64}(undef,3)
    tmp0 = (6.0 - intermediate_results.d_sq + 2*intermediate_results.c_ab +
            2*intermediate_results.d*(intermediate_results.sa - intermediate_results.sb)) / 8.0
    phi  = atan(intermediate_results.ca - intermediate_results.cb, intermediate_results.d - intermediate_results.sa + intermediate_results.sb)
    tmp0 = round(tmp0; digits=10)
    phi = round(phi; digits=10)

    if abs(tmp0) <= 1
        p = mod2pi((2*π) - acos(tmp0))
        t = mod2pi(intermediate_results.α - phi + mod2pi(p/2.0))
        p = round(p; digits=10)
        t = round(t; digits=10)
        out[1] = t
        out[2] = p
        out[3] = mod2pi(intermediate_results.α - intermediate_results.β - t + mod2pi(p))
        return EDUBOK, out
    end

    return EDUBNOPATH, nothing
end

function dubins_LRL(intermediate_results::DubinsIntermediateResults)

    out = Vector{Float64}(undef,3)
    tmp0 = (6.0 - intermediate_results.d_sq + 2*intermediate_results.c_ab +
            2*intermediate_results.d*(intermediate_results.sb - intermediate_results.sa)) / 8.0
    phi = atan(intermediate_results.ca - intermediate_results.cb, intermediate_results.d + intermediate_results.sa - intermediate_results.sb)
    tmp0 = round(tmp0; digits=10)
    phi = round(phi; digits=10)

    if abs(tmp0) <= 1
        p = mod2pi(2*π - acos(tmp0))
        t = mod2pi(-intermediate_results.α - phi + p/2.0)
        p = round(p; digits=10)
        t = round(t; digits=10)
        out[1] = t
        out[2] = p
        out[3] = mod2pi(mod2pi(intermediate_results.β) - intermediate_results.α - t + mod2pi(p))
        return EDUBOK, out
    end

    return EDUBNOPATH, nothing
end
