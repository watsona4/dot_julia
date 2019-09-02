mutable struct PathSample
    path::Array
    g::Real # likelihood
    length::Real # path length
    N::Integer # number of samples
end


################################################################################
# The Main Functions
################################################################################

# The ultimate form of the function
function monte_carlo_path_sampling(origin::T, destination::T, adj_mtx::Array{T,2}, link_length_dict::Dict, N1=5000, N2=10000) where {T<:Integer}
    samples = length_distribution_method(origin, destination, adj_mtx, link_length_dict, N1, N2)

    # no_path_est, x_data, y_data = estimate_cumulative_count(samples, N2)
    # return no_path_est, x_data, y_data

    return samples
end

# - - - - - -

# Useful for testing the instances in
# Roberts, B., & Kroese, D. P. (2007). Estimating the Number of st Paths in a Graph. J. Graph Algorithms Appl., 11(1), 195-214.
# http://dx.doi.org/10.7155/jgaa.00142

# This function returns samples of paths.
function monte_carlo_path_sampling(origin::T, destination::T, adj_mtx::Array{T,2}, N1=5000, N2=10000) where {T<:Integer}
    link_length_dict = getLinkLengthDict(adj_mtx)
    return monte_carlo_path_sampling(origin, destination, adj_mtx, link_length_dict, N1, N2)
end

# This function returns the estimated number of paths, based on sampled paths.
function monte_carlo_path_number(origin::T, destination::T, adj_mtx::Array{T,2}, N1=5000, N2=10000) where {T<:Integer}
    link_length_dict = getLinkLengthDict(adj_mtx)
    samples = monte_carlo_path_sampling(origin, destination, adj_mtx, link_length_dict, N1, N2)
    return estimate_number(samples)
end

# - - - - - -


# Useful for experimenting many realistic road networks
function monte_carlo_path_sampling(origin::T, destination::T, start_node::Array{T,1},  end_node::Array{T,1}, link_length, N1=5000, N2=10000) where {T<:Integer}
    link_length_dict = getLinkLengthDict(start_node, end_node, link_length)
    adj_mtx = getAdjacency(start_node, end_node)

    return monte_carlo_path_sampling(origin, destination, adj_mtx, link_length_dict, N1, N2)
end

################################################################################
################################################################################

function estimate_number(samples::Array{PathSample,1})
    no_path_est = 0
    for s in samples
        no_path_est += 1 / s.g
    end
    no_path_est = no_path_est / samples[1].N
    return no_path_est
end

function estimate_cumulative_count(samples::Array{PathSample,1}, option=:uniform)
    no_path_est = 0
    path_lengths = Array{Float64,1}(undef, 0)
    likelihoods = Array{Float64,1}(undef, 0)
    for s in samples
        no_path_est += 1 / s.g
        push!(path_lengths, s.length)
        push!(likelihoods, s.g)
    end
    no_path_est = no_path_est / samples[1].N


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
        idx = findall(x-> x<=x_data[i], path_lengths)
        y_data[i] = sum(1 ./ likelihoods[idx])
    end
    y_data =  y_data / samples[1].N

    return x_data, y_data
end


################################################################################
################################################################################


# Algorithm 1 (Naive Path Generation) of Roberts and Kroese (2007)
function naive_path_generation(origin, destination, adj_mtx, N1)

    naive_samples = PathSample[]
    for k=1:N1
        adj = copy(adj_mtx)

        # 1
        x = [origin]
        g = 1
        current = origin

        #2
        adj[:,origin] .= 0

        while current != destination
            #3
            V = Int[]
            for i=1:size(adj,1) # number of nodes
                if adj[current,i] == 1
                    push!(V, i)
                end
            end
            if length(V)==0
                break
            end

            #4
            next = rand(V)
            x = [x; next]

            #5
            current = next
            adj[:,next] .= 0
            g = g / length(V)
        end

        if x[end] == destination
            this_sample = PathSample(x, g, 0.0, N1)
            push!(naive_samples, this_sample)
        end
    end

    return naive_samples
end

# Computing \hat{l}_k as in Equation (4) of Roberts and Kroese (2007)
function length_distribution_vector(naive_samples::Array{PathSample}, adj::Array{Int,2}, no_node::Int, destination::Int)
    # Length-Distribution
    # l_hat = numerator / denominator

    # adj = getAdjacency(start_node, end_node)
    # no_node = getNoNode(start_node, end_node)

    l_hat = Array{Float64}(undef, no_node-1)
    for k = 1:length(l_hat)
        numerator = 0.0
        denominator = 0.0

        for s in naive_samples
            if length(s.path)-1 == k
                numerator += 1 / s.g
            end

            if length(s.path)-1 >= k
                if adj[ s.path[k], destination ]==1
                    denominator += 1 / s.g
                end
            end
        end

        l_hat[k] = numerator / denominator
    end

    return l_hat
end


# Algorithm 2 (Length-Distribution Method) of Roberts and Kroese (2007)
function length_distribution_method(origin, destination, adj_mtx, link_length_dict, N1, N2)

    no_node = size(adj_mtx,1)

    naive_samples = naive_path_generation(origin, destination, adj_mtx, N1)
    l_hat = length_distribution_vector(naive_samples, adj_mtx, no_node, destination)

    # Algorithm 2
    # Naive Path Generation
    better_samples = PathSample[]
    for k=1:N2
        adj = copy(adj_mtx)

        #2
        x = [origin]
        g = 1
        current = origin

        #3
        adj[:,origin] .= 0

        next = []
        while current != destination
            t = length(x)

            #4
            if adj[current, destination] == 1
            #4. A(c,n)=1

                if sum(adj, dims=2)[current] == 1
                #4. destination is the only available vertex adjacent to current
                    next = destination
                else
                #4. If there are other vertices adjacent to current
                    if rand() <= l_hat[t]
                    #   choose the next vertext to be destination with probability l_hat[t]
                        g = g * l_hat[t]
                        next = destination
                    else
                        g = g * (1 - l_hat[t])
                        adj[current, destination] = 0
                    end
                end

            end

            if next == destination
                x = [x; next]
                break

            else
            #5
                V = Int[]
                for i=1:size(adj,1) # number of nodes
                    if adj[current,i] == 1
                        push!(V, i)
                    end
                end
                if length(V)==0
                    break
                end

                #6
                next = rand(V)
                x = [x; next]

                #7
                current = next
                adj[:,next] .= 0
                g = g / length(V)

            end


        end

        if x[end] == destination
            this_sample = PathSample(x, g, getPathLength(x, link_length_dict), N2)
            push!(better_samples, this_sample)
        end
    end

    return better_samples
end
