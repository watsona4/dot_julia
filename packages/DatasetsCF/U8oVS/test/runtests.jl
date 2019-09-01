using Persa
using DatasetsCF
using Test

# write your own tests here
ds = DatasetsCF.MovieLens()
@test Persa.users(ds) == 943
@test Persa.items(ds) == 1682
@test Persa.size(ds.preference) == 5
@test Persa.minimum(ds.preference) == 1
@test Persa.maximum(ds.preference) == 5

ds = DatasetsCF.MovieLens1M()
@test Persa.users(ds) == 6040
@test Persa.items(ds) == 3706
@test Persa.size(ds.preference) == 5
@test Persa.minimum(ds.preference) == 1
@test Persa.maximum(ds.preference) == 5
