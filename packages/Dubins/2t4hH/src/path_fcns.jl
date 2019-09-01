
export
    dubins_shortest_path, dubins_path,
    dubins_path_length, dubins_segment_length,
    dubins_segment_length_normalized,
    dubins_path_type, dubins_path_sample,
    dubins_path_sample_many, dubins_path_endpoint,
    dubins_extract_subpath

"""
Generate a path from an initial configuration to a target configuration with a specified maximum turning radius

A configuration is given by [x, y, θ], where θ is in radians,

* q0        - a configuration specified by a 3-element vector [x, y, θ]
* q1        - a configuration specified by a 3-element vector [x, y, θ]
* ρ         - turning radius of the vehicle
* return    - tuple (error code, dubins path). If error code != 0, then `nothing` is returned as the second argument
"""
function dubins_shortest_path(q0::Vector{Float64}, q1::Vector{Float64}, ρ::Float64)

    # input checking
    @assert length(q0) ==  3
    @assert length(q1) == 3
    (ρ <= 0) && (return EDUBBADRHO, nothing)

    path = DubinsPath()

    params = zeros(3)

    best_cost = Inf
    best_word = -1
    intermediate_results = DubinsIntermediateResults(q0, q1, ρ)

    path.qi[1] = q0[1]
    path.qi[2] = q0[2]
    path.qi[3] = q0[3]
    path.ρ = ρ

    for i in 0:5
        path_type = DubinsPathType(i)
        errcode, params = dubins_word(intermediate_results, path_type)
        if errcode == EDUBOK
            cost = sum(params)
            if cost < best_cost
                best_word = i
                best_cost = cost
                path.params[1] = params[1]
                path.params[2] = params[2]
                path.params[3] = params[3]
                path.path_type = path_type
            end
        end
    end

    (best_word == -1) && (return EDUBNOPATH, nothing)
    return EDUBOK, path
end

"""
Generate a path with a specified word from an initial configuratioon to a target configuration, with a specified turning radius

* q0        - a configuration specified by a 3-element vector x, y, theta
* q1        - a configuration specified by a 3-element vector x, y, theta
* ρ         - turning radius of the vehicle
* path_type - the specified path type to use
* return    - tuple (error code, dubins path). If error code != 0, then `nothing` is returned as the second argument
"""
function dubins_path(q0::Vector{Float64}, q1::Vector{Float64}, ρ::Float64, path_type::DubinsPathType)

    # input checking
    @assert length(q0) ==  3
    @assert length(q1) == 3
    (ρ <= 0) && (return EDUBBADRHO, nothing)

    path = DubinsPath()

    intermediate_results = DubinsIntermediateResults(q0, q1, ρ)

    params = zeros(3)
    errcode, params = dubins_word(intermediate_results, path_type)
    if errcode == EDUBOK
        path.params[1] = params[1]
        path.params[2] = params[2]
        path.params[3] = params[3]
        path.qi[1] = q0[1]
        path.qi[2] = q0[2]
        path.qi[3] = q0[3]
        path.ρ = ρ
        path.path_type = path_type
    end

    (errcode != EDUBOK) && (return errcode, nothing)
    return errcode, path
end


"""
Calculate the length of an initialized path

* path      - path to find the length of
* return    - path length
"""
dubins_path_length(path::DubinsPath) = sum(path.params)*path.ρ


"""
Calculate the length of a specific segment of  an initialized path

* path      - path to find the length of
* i         - the segment for which the length is required (1-3)
* return    - segment length
"""
dubins_segment_length(path::DubinsPath, i::Int) = (i<1 || i>3) ? (return Inf) : (return path.params[i]*path.ρ)

"""
Calculate the normalized length of a specific segment of  an initialized path

* path      - path to find the length of
* i         - the segment for which the length is required (1-3)
* return    - normalized segment length
"""
dubins_segment_length_normalized(path::DubinsPath, i::Int) = (i<1 || i>3) ? (return Inf) : (return path.params[i])

"""
Extract the integer that represents which path type was used

* path      - an initialized path
* return    - one of LSL-0, LSR-1, RSL-2, RSR-3, RLR-4, LRL-5
"""
dubins_path_type(path::DubinsPath) = path.path_type

"""
Operators that transform an arbitrary point qi, [x, y, θ], into an image point given a parameter t and segment type

The three operators correspond to L_SEG, R_SEG, and S_SEG

 * L_SEG(x, y, θ, t) = [x, y, θ] + [ sin(θ + t) - sin(θ), -cos(θ + t) + cos(θ),  t]
 * R_SEG(x, y, θ, t) = [x, y, θ] + [-sin(θ - t) + sin(θ),  cos(θ - t) - cos(θ), -t]
 * S_SEG(x, y, θ, t) = [x, y, θ] + [ cos(θ) * t,           sin(θ) * t,           0]

 * return    -  the image point as a 3-element vector
"""
function dubins_segment(t::Float64, qi::Vector{Float64}, segment_type::SegmentType)

    qt = zeros(3)
    st = sin(qi[3])
    ct = cos(qi[3])

    if segment_type == L_SEG
        qt[1] = +sin(qi[3]+t) - st
        qt[2] = -cos(qi[3]+t) + ct
        qt[3] = t
    elseif segment_type == R_SEG
        qt[1] = -sin(qi[3]-t) + st
        qt[2] = +cos(qi[3]-t) - ct
        qt[3] = -t
    elseif segment_type == S_SEG
        qt[1] = ct * t
        qt[2] = st * t
        qt[3] = 0.0
    end
    qt[1] = qt[1] + qi[1]
    qt[2] = qt[2] + qi[2]
    qt[3] = qt[3] + qi[3]

    return qt
end

"""
Calculate the configuration along the path, using the parameter t

 * path      - an initialized path
 * t         - length measure where 0 <= t < dubins_path_length(path)
 * return    - tuple containing non-zero error code if 't' is not in the correct range and the configuration result [x, y, θ]
"""
function dubins_path_sample(path::DubinsPath, t::Float64)

    # tprime is the normalized variant of the parameter t
    tprime = t/path.ρ
    qi = zeros(3)
    q = zeros(3)
    segment_types = DIRDATA[Int(path.path_type)]

    (t < 0 || t > dubins_path_length(path)) && (return EDUBPARAM, nothing)

    # initial configuration
    qi = [0.0, 0.0, path.qi[3]]

    # generate target configuration
    p1 = path.params[1]
    p2 = path.params[2]
    q1 = dubins_segment(p1, qi, segment_types[1])
    q2 = dubins_segment(p2, q1, segment_types[2])
    if tprime < p1
        q = dubins_segment(tprime, qi, segment_types[1])
    elseif tprime < (p1+p2)
        q = dubins_segment(tprime-p1, q1, segment_types[2])
    else
        q = dubins_segment(tprime-p1-p2, q2, segment_types[3])
    end

    # scale the target configuration, translate back to the original starting point
    q[1] = q[1] * path.ρ + path.qi[1]
    q[2] = q[2] * path.ρ + path.qi[2]
    q[3] = mod2pi(q[3]);

    return EDUBOK, q
end


"""
Walk along the path at a fixed sampling interval, calling the callback function at each interval

The sampling process continues until the whole path is sampled, or the callback returns a non-zero value

 * path         - the path to sample
 * step_size    - the distance along the path for subsequent samples

 * return       - tuple (error code, configuration vector). If error code != 0, then `nothing` is returned as the second argument
 """
function dubins_path_sample_many(path::DubinsPath, step_size::Float64)

    q = zeros(3)
    configurations = []
    x = 0.0
    length = dubins_path_length(path)

    (step_size < 0 || step_size > length) && (return EDUBPARAM, nothing)


    while x < length
        errcode, q = dubins_path_sample(path, x)
        push!(configurations, q)
        (errcode != 0) && (return errcode, nothing)
        x += step_size
    end

    return EDUBOK, configurations
end

"""
Convenience function to identify the endpoint of a path

 * path          - an initialized path
 * return        - tuple containing (zero on successful completion and the end configuration [x,y,Θ])
"""
dubins_path_endpoint(path::DubinsPath) = dubins_path_sample(path, dubins_path_length(path) - TOL)

"""
Convenience function to extract a sub-path

 * path          - an initialized path
 * t             - a length measure, where 0 < t < dubins_path_length(path)
 * return        - zero on successful completion and the subpath
"""
function dubins_extract_subpath(path::DubinsPath, t::Float64)

    # calculate the true parameter
    tprime = t / path.ρ;

    ((t < 0) || (t > dubins_path_length(path))) && (return EDUBPARAM, nothing)

    newpath = DubinsPath()

    # copy most of the data
    newpath.qi[1] = path.qi[1]
    newpath.qi[2] = path.qi[2]
    newpath.qi[3] = path.qi[3]
    newpath.ρ = path.ρ
    newpath.path_type = path.path_type

    # fix the parameters
    newpath.params[1] = min(path.params[1], tprime)
    newpath.params[2] = min(path.params[2], tprime - newpath.params[1])
    newpath.params[3] = min(path.params[3], tprime - newpath.params[1] - newpath.params[2])

    return EDUBOK, newpath
end


"""
The function to call the corresponding Dubins path based on the path_type

* return        - tuple (error code, path length as a vector for corresponding path type)
"""
function dubins_word(intermediate_results::DubinsIntermediateResults, path_type::DubinsPathType)

    result::Int = 0
    out = Vector{Float64}(undef,3)
    if path_type == LSL
        result, out = dubins_LSL(intermediate_results)
    elseif path_type == RSL
        result, out = dubins_RSL(intermediate_results)
    elseif path_type == LSR
        result, out = dubins_LSR(intermediate_results)
    elseif path_type == RSR
        result, out = dubins_RSR(intermediate_results)
    elseif path_type == LRL
        result, out = dubins_LRL(intermediate_results)
    elseif path_type == RLR
        result, out = dubins_RLR(intermediate_results)
    else
        result = EDUBNOPATH
    end

    (result == EDUBNOPATH) && (return result, nothing)
    return result, out
end

"""
Reset tolerance value
"""
function set_tolerance(ϵ::Float64)
    TOL = ϵ
    return
end
