# This script includes functions that are used to enumerate paths explictly, not using sampling.

mutable struct PathEnum
    path::Array
    length::Real
end

###################################################

function path_enumeration(origin, destination, adj_mtx)
    link_length_dict = getLinkLengthDict(adj_mtx)
    path_enums = Array{PathEnum,1}(undef, 0)
    return path_enumeration(origin, destination, adj_mtx, link_length_dict)
end

function path_enumeration(origin, destination, start_node::Array, end_node::Array, link_length::Array)
    adj_mtx = getAdjacency(start_node, end_node)
    link_length_dict = getLinkLengthDict(start_node, end_node, link_length)
    return path_enumeration(origin, destination, adj_mtx, link_length_dict)
end





function path_enumeration(origin, destination, adj_mtx, link_length_dict::Dict)
    path_enums = Array{PathEnum,1}(undef, 0)
    current_list = [origin]
    find_neighbor!(origin, destination, adj_mtx, current_list, path_enums, link_length_dict)
    return path_enums
end

###################################################


function find_neighbor!(current, destination, adj_mtx, current_list, path_enums, link_length_dict)

    for i=1:size(adj_mtx, 1)
        visited = length(findall(x-> x==i, current_list)) > 0

        if ! visited && adj_mtx[current, i] == 1
            # Create a new object for the new list
            new_list = [current_list; i]

            if i == destination
                # Obtained a new path
                # println(fid, new_list)
                push!(path_enums, PathEnum(new_list, getPathLength(new_list, link_length_dict)) )
            else
                # Branch another neighbor search
                find_neighbor!(i, destination, adj_mtx, new_list, path_enums, link_length_dict)
            end
        end

    end

end


function actual_cumulative_count(path_enums::Array{PathEnum,1}, option=:unique)
    path_lengths = Array{Float64,1}(undef, 0)
    for enum in path_enums
        push!(path_lengths, enum.length)
    end

    N_data = 100
    # option == :uniform
    x_data = collect(range(minimum(path_lengths), stop=maximum(path_lengths), length=N_data))
    if option == :unique
        x_data = sort(unique(path_lengths))
    elseif option == :first_quarter
        x_q1 = range(minimum(path_lengths), stop=0.25*maximum(path_lengths), length=N_data/2)
        x_q234 = range(0.25*maximum(path_lengths), stop=maximum(path_lengths), length=N_data/2)
        x_data = append!(collect(x_q1), collect(x_q234))
    end

    y_data = similar(x_data)

    for i=1:length(x_data)
        y_data[i] = count(x-> x<=x_data[i], path_lengths)
    end

    return x_data, y_data
end
