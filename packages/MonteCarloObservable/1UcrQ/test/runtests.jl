using MonteCarloObservable
using Test, Statistics
import HDF5

@testset "All Tests" begin
    
    include("observable.jl")
    include("lightobservable.jl")

end