export process_lifecycles

function collect_lifecycles(data::HONData, only_closed::Bool=false)
    simplices = data.simplices
    nverts = data.nverts
    times = data.times
    
    A, At, B = basic_matrices(simplices, nverts)
    simplex_order = simplex_degree_order(At)
    triangle_order = proj_graph_degree_order(B)

    all_events = Int64[]
    all_times = Int64[]
    num_events = Int64[]
    I, J, K = Int64[], Int64[], Int64[]

    for i = 1:size(B, 2)
        for (j, k) in combinations(neighbors(B, triangle_order, i), 2)
            if B[j, k] > 0
                # We have a triangle -- get the trail
                trail_events = Int64[]
                trail_times = Int64[]
                trail_simplices = Int64[]
                
                # SKIP if triangle is open and we only want to look at
                # closed triangles
                if only_closed && !triangle_closed(A, At, simplex_order, i, j, k)
                    continue
                end
                
                # Sort least common to most common
                a, b, c = i, j, k
                minval = min(simplex_order[i], simplex_order[j], simplex_order[k])
                if     minval == simplex_order[j]; a, b, c = j, i, k
                elseif minval == simplex_order[k]; a, b, c = k, i, j
                end

                # Get all simplices with a as an author
                for simplex_id in nz_row_inds(At, a)
                    # Check if b and c are in the simplex
                    has_b = A[b, simplex_id] > 0
                    has_c = A[c, simplex_id] > 0
                    if      has_b &&  has_c
                        push!(trail_events, 4)
                        push!(trail_times, times[simplex_id])
                        push!(trail_simplices, simplex_id)
                    elseif !has_b &&  has_c
                        push!(trail_events, 2)
                        push!(trail_times, times[simplex_id])
                        push!(trail_simplices, simplex_id)                            
                    elseif  has_b && !has_c
                        push!(trail_events, 1)
                        push!(trail_times, times[simplex_id])
                        push!(trail_simplices, simplex_id)                            
                    end
                end
                    
                # Get all (b, c) simplices without a
                for simplex_id in nz_row_inds(At, b)
                    if A[c, simplex_id] > 0 && A[a, simplex_id] == 0
                        push!(trail_events, 3)
                        push!(trail_times, times[simplex_id])
                        push!(trail_simplices, simplex_id)                            
                    end
                end

                sp = sortperm(trail_times)
                trail_events = trail_events[sp]
                trail_times = trail_times[sp]
                trail_simplices = trail_simplices[sp]
                
                closure_ind = findnext(x -> x == 4, trail_events, 1)
                if closure_ind != nothing
                    trail_events = trail_events[1:closure_ind]
                    trail_times = trail_times[1:closure_ind]
                    trail_simplices = trail_simplices[1:closure_ind]
                end

                append!(all_events, trail_events)
                append!(all_times, trail_times)
                push!(num_events, length(trail_times))
                push!(I, a)
                push!(J, b)
                push!(K, c)
            end
        end
    end

    return (I, J, K, num_events, all_events, all_times)
end

function process_trail(events::Vector{Int64})
    ij, jk, ik = 0, 0, 0
    states = Int64[]
    push!(states, 1)

    for event in events
        curr_state = states[end]
        if     event == 1; ij += 1
        elseif event == 2; ik += 1
        elseif event == 3; jk += 1
        end

        # Process transition
        if event == 4
            push!(states, 11)  # filled triangle
            break
        end

        vals = [ij, ik, jk]
        sort!(vals)
        if     vals[2] == 0  # single edge
            if     vals[3] == 1; push!(states, 2)  # (0, 0, 1)
            else                 push!(states, 3)  # (0, 0, 2+)
            end
        elseif vals[1] == 0 && vals[2] > 0  # open wedge
            if     vals[2] == 1 && vals[3] == 1; push!(states, 4)  # (0, 1, 1)
            elseif vals[2] == 1 && vals[3] > 1;  push!(states, 5)  # (0, 1, 2+)
            elseif vals[2] > 1  && vals[3] > 1;  push!(states, 7)  # (0, 2+, 2+)
            else   error("Unknown transition")
            end
        elseif vals[1] > 0  # open triangle
            if     vals[1] == vals[2] == vals[3] == 1; push!(states, 6)  # (1, 1, 1)
            elseif vals[2] == 1 && vals[3] > 1;        push!(states, 8)  # (1, 1, 2+)
            elseif vals[1] == 1 && vals[2] > 1;        push!(states, 9)  # (1, 2+, 2+)
            elseif vals[1] > 1;                        push!(states, 10) # (2+, 2+, 2+)
            else error("Unknwon transition")
            end
        else
            error("Unknwon transition")
        end
    end
    return states
end

function earliest_activity(At::SpIntMat, times::Vector{Int64})
    earliest = zeros(Int64, size(At, 2))
    for j in 1:size(At, 2), time in times[nz_row_inds(At, j)]
        if earliest[j] == 0 || time < earliest[j]
            earliest[j] = time
        end
    end
    return earliest
end

"""
process_lifecycles
------------------

Process all lifecycles in a given dataset.

process_lifecycles(data::HONData)

Input parameters:
- data::HONData: The dataset

Returns a tuple (closed_transitions, open_transitions)
- closed_transitions::Array{Int64,2}: matrix whose (i, j) entry is the number of transitions from configuration j to configuration i, out of all triples of nodes that eventually simplicially close
- open_transitions::Array{Int64,2}: matrix whose (i, j) entry is the number of transitions from configuration j to configuration i, out of all triples of nodes that do not simplicially close
"""
function process_lifecycles(data::HONData)
    (triangles1, triangles2, triangles3, num_events, all_events, all_times) =
        collect_lifecycles(data, false)

    # Get earliest simplex of each node
    A, At, B = basic_matrices(data)
    earliest_times = earliest_activity(At, data.times)
    open_transitions = zeros(Int64, 11, 11)
    open_times = zeros(Int64, 11, 11)
    closed_transitions = zeros(Int64, 11, 11)
    closed_times = zeros(Int64, 11, 11)    

    curr_ind = 1
    for (i, num) in enumerate(num_events)
        curr_events = all_events[curr_ind:(curr_ind + num - 1)]
        curr_times  = all_times[curr_ind:(curr_ind + num - 1)]
        curr_ind += num

        states = process_trail(curr_events)

        a = triangles1[i]
        b = triangles2[i]
        c = triangles3[i]
        # start time at the latest of the earliest simplex times
        emaxtime = maximum(earliest_times[[a, b, c]])
        if minimum(emaxtime) == 0
            error("0 Time (is value missing?)")
        end
        time = emaxtime
        
        for i = 2:length(states)
            s1 = states[i]
            s2 = states[i - 1]
            if states[end] == 11; closed_transitions[s1, s2] += 1
            else                  open_transitions[s1, s2]   += 1
            end
            if s2 != s1
                diff = curr_times[i - 1] - time
                if (s2 == 2 || s2 == 3) && s1 == 11  # single edge --> closed
                    diff = curr_times[i - 1] - max(emaxtime, time)
                end
                if (s1 == 2 && s2 == 1)  # empty --> single edge
                    diff = curr_times[i - 1] - emaxtime
                    if diff < 0
                        # Take the time since first co-authorship of 2 authors on the edge
                        next_start = median([earliest_times[a], earliest_times[b], earliest_times[c]])
                        diff = curr_times[i - 1] - next_start
                    end
                end
                if states[end] == 11; closed_times[s1, s2] += diff
                else                  open_times[s1, s2]   += diff
                end
                # Update time
                time = curr_times[i - 1]
            end
        end
    end
    return (closed_transitions, open_transitions)
end
