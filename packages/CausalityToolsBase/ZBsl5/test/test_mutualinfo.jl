using DelayEmbeddings, CausalityToolsBase

D = Dataset(rand(1000, 4))

# Compute the mutual information between the first and second 
# columns of D and the third and fourth columns of D.
@test mutualinfo(D, [1, 2], [3, 4], BoxKernel()) isa Float64

# Compute the mutual information between the first and fourth
# column of D using a Gaussian kernel 
@test mutualinfo(D, [1], [4], BoxKernel()) isa Float64