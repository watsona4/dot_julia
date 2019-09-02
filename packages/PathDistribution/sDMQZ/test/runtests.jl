using PathDistribution


################################################################################
# Datasets from
# Roberts, B., & Kroese, D. P. (2007). Estimating the Number of st Paths in a Graph. J. Graph Algorithms Appl., 11(1), 195-214.
# http://dx.doi.org/10.7155/jgaa.00142

# Case 1
adj_mtx =[  0 1 1 1 0 1 1 1 ;
            1 0 0 0 1 1 1 0 ;
            1 0 0 1 1 1 1 1 ;
            1 0 1 0 1 1 1 1 ;
            0 1 1 1 0 1 0 0 ;
            1 1 1 1 1 0 1 1 ;
            1 1 1 1 0 1 0 1 ;
            1 0 1 1 0 1 1 0     ]
# true_num = 397

# Full Enumeration
path_enums = path_enumeration(1, size(adj_mtx,1), adj_mtx)
x_data, y_data = actual_cumulative_count(path_enums)

# Monte Carlo Sampling
samples = monte_carlo_path_sampling(1, size(adj_mtx,1), adj_mtx)
x_data_est, y_data_est = estimate_cumulative_count(samples)

println("===== Case 1 of Roberts & Kroese (2007) =====")
println("The total number of paths:")
println("- Full enumeration      : $(length(path_enums))")
println("- Monte Carlo estimation: $(y_data_est[end])")






# Other ways of using Monte Carlo Sampling
N1 = 500
N2 = 1000

samples = monte_carlo_path_sampling(1, size(adj_mtx,1), adj_mtx)
x_data_est, y_data_est = estimate_cumulative_count(samples)
println("- Monte Carlo estimation: $(y_data_est[end])")

samples = monte_carlo_path_sampling(1, size(adj_mtx,1), adj_mtx, N1, N2)
x_data_est, y_data_est = estimate_cumulative_count(samples)
println("- Monte Carlo estimation: $(y_data_est[end])")

samples = monte_carlo_path_sampling(1, size(adj_mtx,1), adj_mtx, N1, N2)
x_data_est, y_data_est = estimate_cumulative_count(samples, :uniform)
println("- Monte Carlo estimation: $(y_data_est[end])")

samples = monte_carlo_path_sampling(1, size(adj_mtx,1), adj_mtx, N1, N2)
x_data_est, y_data_est = estimate_cumulative_count(samples, :unique)
println("- Monte Carlo estimation: $(y_data_est[end])")


# When you just need the path number estimator
no_path_est = monte_carlo_path_number(1, size(adj_mtx,1), adj_mtx, N1, N2)
println("- Monte Carlo estimation: $(no_path_est)")


################################################################################
# Another example in README.md

data = [
 1   4  79.0 ;
 1   2  59.0 ;
 2   4  31.0 ;
 2   3  90.0 ;
 2   5   9.0 ;
 2   6  32.0 ;
 3   9  89.0 ;
 3   8  66.0 ;
 3   6  68.0 ;
 3   7  47.0 ;
 4   3  14.0 ;
 4   9  95.0 ;
 4   8  88.0 ;
 5   3  44.0 ;
 5   6  83.0 ;
 6   7  33.0 ;
 6   8  37.0 ;
 7  11  79.0 ;
 7  12  10.0 ;
 8   7  95.0 ;
 8  10   0.0 ;
 8  12  30.0 ;
 9  10   5.0 ;
 9  11  44.0 ;
10  13  79.0 ;
10  14  91.0 ;
11  14  53.0 ;
11  15  80.0 ;
11  13  56.0 ;
12  15  75.0 ;
12  14   1.0 ;
13  14  48.0 ;
14  15  25.0 ;
]

st = round.(Int, data[:,1]) #first column of data
en = round.(Int, data[:,2]) #second column of data
len = data[:,3] #third

# Double them for two-ways.
start_node = [st; en]
end_node = [en; st]
link_length = [len; len]

origin = 1
destination = 15

# Path enumeration test

# Full Enumeration
path_enums = path_enumeration(origin, destination, start_node, end_node, link_length)
x_data, y_data = actual_cumulative_count(path_enums)

# Monte-Carlo estimation
N1 = 5000
N2 = 10000
samples = monte_carlo_path_sampling(origin, destination, start_node, end_node, link_length)
samples = monte_carlo_path_sampling(origin, destination, start_node, end_node, link_length, N1, N2)
x_data_est, y_data_est = estimate_cumulative_count(samples)

println("===== Another Example =====")
println("The total number of paths:")
println("- Full enumeration      : $(length(path_enums))")
println("- Monte Carlo estimation: $(y_data_est[end])")



# END
