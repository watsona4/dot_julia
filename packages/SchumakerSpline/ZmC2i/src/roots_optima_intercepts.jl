"""
test_if_intercept_in_interval(a1::Real,b1::Real,c1::Real,c2::Real,interval_width::Real)
    This tests if a spline could have passed over zero in a certain interval. The a1,b1,c1 are the coefficients of the spline. The two xs are for the left and right and c2 is the right hand level.
        Note that this function will not detect zeros that are precisely on the endpoints.
"""
function test_if_intercept_in_interval(a1::Real,b1::Real,c1::Real,c2::Real,interval_width::Real)
    if (sign(c1) == 0) || abs(sign(c1) - sign(c2)) > 1.5 return true end # If we cross the barrier then there is at least one intercept in interval.
    if sign(b1) == sign(2*a1*(interval_width)+b1) return false end # If we did not cross the barrier and the spline is monotonic then we did not cross
    # Now we have the case where the gradient switches sign within an interval but the sign of the endpoints did not change.
    # The easiest way to test will be to find the vertex of the parabola. See if it is within the interval and of a different sign to the endpoints.
    # We don't actually have to test if the vertex is in the interval however - it has to be for the gradient sign to have flipped.
    vertex_x = -b1/(2*a1) # Note that this is relative to x1.
    vertex_y = a1 * (vertex_x)^2 + b1*(vertex_x) + c1
    is_vertex_of_opposite_sign_in_y = abs(sign(c1) - sign(vertex_y)) > 0.5
    return is_vertex_of_opposite_sign_in_y
end

"""
find_root(spline::Schumaker; root_value::T = 0.0)
    Finds roots - This is handy because in many applications schumaker splines are monotonic and globally concave/convex and so it is easy to find roots.
    Here root_value can be set to get all points at which the function is equal to the root value. For instance if you want to find all points at which
    the spline has a value of 1.0.
"""
function find_roots(spline::Schumaker{T}; root_value::Real = 0.0, interval::Tuple{<:Real,<:Real} = (spline.IntStarts_[1], spline.IntStarts_[length(spline.IntStarts_)])) where T<:Real
    roots = Array{T,1}(undef,0)
    first_derivatives = Array{T,1}(undef,0)
    second_derivatives = Array{T,1}(undef,0)
    first_interval_start = searchsortedlast(spline.IntStarts_, interval[1])
    last_interval_start  = searchsortedlast(spline.IntStarts_, interval[2])
    len = length(spline.IntStarts_)
    go_from = max(1,first_interval_start)
    go_until = last_interval_start < len ? last_interval_start : len-1
    constants = spline.coefficient_matrix_[:,3]
    constants_minus_root = constants .- root_value
    for i in go_from:go_until
        a1  = spline.coefficient_matrix_[i,1]
        b1  = spline.coefficient_matrix_[i,2]
        c1  = constants_minus_root[i]
        c2 = constants_minus_root[i+1]
        interval_width = spline.IntStarts_[i+1] - spline.IntStarts_[i] + 3*eps() # This 3 epsilon is here because of problems where one segment would predict it is an epsilon within
        # the next segment and the next segment (correctly) thinks it is in the previous. So neither pick up the root. So with this we potentially record twice and then we can later on remove
        # nearby roots.
        if test_if_intercept_in_interval(a1,b1,c1,c2,interval_width)
            if abs(a1) > eps() # Is it quadratic
                det = sqrt(b1^2 - 4*a1*c1)
                both_roots = [(-b1 + det) / (2*a1), (-b1 - det) / (2*a1)] # The x coordinates here are relative to spline.IntStarts_[i].
                left_root  = minimum(both_roots)
                right_root = maximum(both_roots)
                # This means that the endpoints are double counted. Thus we will have to remove them later.
                if (left_root >= 0) && (left_root <= interval_width + 5*eps())
                    append!(roots, spline.IntStarts_[i] + left_root)
                    append!(first_derivatives, 2 * a1 * left_root + b1)
                    append!(second_derivatives, 2 * a1)
                end
                if (right_root >= 0) && (right_root <= interval_width)
                    append!(roots, spline.IntStarts_[i] + right_root)
                    append!(first_derivatives, 2 * a1 * right_root + b1)
                    append!(second_derivatives, 2 * a1)
                end
            else # Is it linear? Note it cannot be constant or else it could not have jumped past zero in the interval.
                new_root = spline.IntStarts_[i] - c1/b1
                if !((length(roots) > 0) && (abs(new_root - last(roots)) < 1e-5))
                    append!(roots, spline.IntStarts_[i] - c1/b1)
                    append!(first_derivatives, b1)
                    append!(second_derivatives, 0.0)
                end
            end
        end
    end
    # Now adding on roots that occur after the end of the last interval.
    end_of_last_interval = spline.IntStarts_[length(spline.IntStarts_)]
    if interval[2] >= end_of_last_interval
        a = spline.coefficient_matrix_[len,1]
        b = spline.coefficient_matrix_[len,2]
        c = constants_minus_root[len]
        if abs(a) > eps() # Is it quadratic
            root_determinant = sqrt(b^2 - 4*a*c)
            end_roots = end_of_last_interval .+ [(-b - root_determinant)/(2*a), (-b + root_determinant)/(2*a)]
            end_roots2 = end_roots[(end_roots .>= end_of_last_interval) .& (end_roots .<= interval[2])]
            num_new_roots = length(end_roots2)
            if num_new_roots > 0
                append!(roots, end_roots2)
                append!(first_derivatives, (2 * a) .* end_roots2 .+ b)
                append!(second_derivatives, repeat([2*a], num_new_roots))
            end
        elseif abs(b) > eps() # If it is linear.
            new_root = [-c/b + end_of_last_interval]
            new_root2 = new_root[(new_root .>= end_of_last_interval) .& (new_root .<= interval[2])]
            if length(new_root2) > 0
                append!(roots, new_root2)
                append!(first_derivatives, (2 * a) .* new_root2 .+ b)
                append!(second_derivatives, 2*a)
            end
        end # We do nothing in the case that we have a constant - no chance of root.
    end
    # Sometimes if there are two roots within an interval and the endpoint of the interval is also here we get too many roots.
    # So here we get rid of stuff we don't want.
    if length(roots) == 0
        return (roots = roots, first_derivatives = first_derivatives, second_derivatives = second_derivatives)
    else
        roots_in_interval = (roots .>= interval[1]) .& (roots .<= interval[2])
        if length(roots) > 1
           gaps = roots[2:length(roots)] .- roots[1:(length(roots)-1)]
           for i in 1:length(gaps)
               if abs(gaps[i]) < 100 * eps() roots_in_interval[i+1] = false end
           end
        end
        return (roots = roots[roots_in_interval], first_derivatives = first_derivatives[roots_in_interval], second_derivatives = second_derivatives[roots_in_interval])
    end
end

"""
find_optima(spline::Schumaker)
Finds optima - This is handy because in many applications schumaker splines are monotonic and globally concave/convex and so it is easy to find optima.

"""
function find_optima(spline::Schumaker; interval::Tuple{<:Real,<:Real} = (spline.IntStarts_[1], spline.IntStarts_[length(spline.IntStarts_)]))
    deriv_spline = find_derivative_spline(spline)
    root_info = find_roots(deriv_spline; interval = interval)
    optima = root_info.roots
    optima_types =  Array{Symbol,1}(undef,length(optima))
    for i in 1:length(optima)
        if root_info.first_derivatives[i] > 1e-15
            optima_types[i] = :Minimum
        elseif root_info.first_derivatives[i] < -1e-15
            optima_types = :Maximum
        else
            optima_types = :SaddlePoint
        end
    end
    return (optima = optima, optima_types = optima_types)
end

## Finding intercepts
"""
    quadratic_formula_roots(a,b,c)
A basic application of the textbook quadratic formula.
"""
function quadratic_formula_roots(a,b,c)
    determin = sqrt(b^2 - 4*a*c)
    roots = [(-b + determin)/(2*a), (-b - determin)/(2*a)]
    return(roots)
end
"""
    get_crossover_in_interval(s1::Schumaker{T}, s2::Schumaker{R}, interval::Tuple{U,U}) where T<:Real where R<:Real where U<:Real
Finds the point at which two schumaker splines cross over each other within a single interval. This is not exported.

"""

function get_crossover_in_interval(s1::Schumaker{T}, s2::Schumaker{R}, interval::Tuple{U,U}) where T<:Real where R<:Real where U<:Real
    # Getting the coefficients for the first spline.
    i = searchsortedlast(s1.IntStarts_, interval[1])
    start1 = s1.IntStarts_[i]
    a1,b1,c1 = Tuple(s1.coefficient_matrix_[i,:])
    # Getting the coefficients for the second spline.
    j = searchsortedlast(s2.IntStarts_, interval[1])
    start2 = s2.IntStarts_[j]
    a2,b2,c2 = Tuple(s2.coefficient_matrix_[j,:])
    # Get implied coefficients for the s1 - s2 quadratic. Pretty simple algebra gets this.
    # As a helper we define G = start2 - start1. We define A,B,C as coefficients of s1-s2.
    # The final spline is in terms of (x-start1).
    G = start1 - start2
    A = a1 - a2
    B = b1 - b2 - 2*a2*G
    C = c1 - c2 - a2*(G^2) - b2*G
    # Now we need to use quadratic formula to get the roots and pick the root in the interval.
    roots = quadratic_formula_roots(A,B,C) .+ start1
    roots_in_interval = roots[(roots .>= interval[1]-10*eps()) .& (roots .<= interval[2]+10*eps())]
    return(roots_in_interval)
end


function get_intersection_points(s1::Schumaker{T}, s2::Schumaker{R}) where T<:Real where R<:Real
    # What x locations to loop over
    all_starts = sort(unique(vcat(s1.IntStarts_, s2.IntStarts_)))
    start_of_overlap = maximum([minimum(s1.IntStarts_), minimum(s2.IntStarts_)])
    overlap_starts = all_starts[all_starts .> start_of_overlap]
    # Getting a container to return results
    promo_type = promote_type(T,R)
    locations_of_crossovers = Array{promo_type,1}()
    # For the first part what function is higher.
    last_one_greater = evaluate(s1, overlap_starts[1]) > evaluate(s2, overlap_starts[1])
    for i in 2:length(overlap_starts)
        start = overlap_starts[i]
        val_1 = evaluate(s1, start)
        val_2 = evaluate(s2, start)
        # Need to take into account the ordering and record when it flips
        one_greater = val_1 > val_2
        if one_greater != last_one_greater
            interval = Tuple([overlap_starts[i-1], overlap_starts[i]])
            crossover = get_crossover_in_interval(s1, s2, interval)
            if length(crossover) != 1
                error("Only one crossover expected in interval from a continuous spline.")
            end
            push!(locations_of_crossovers, crossover[1])
        end
        last_one_greater = one_greater
    end
    return locations_of_crossovers
end
