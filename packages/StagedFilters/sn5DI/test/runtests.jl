using StagedFilters
using Test

using PyCall, BenchmarkTools;
data = convert.(Float64,collect(range(1,1000,length=1000))); 
smoothed = zeros(eltype(data),length(data)); # <--- wholesome, type stable code.
savgol = pyimport("scipy.signal")."savgol_filter";
x = PyObject(data);
benchjl64 = @btime smooth!(SavitzkyGolayFilter{2,2}, data, smoothed);
benchpy64 = @btime $savgol($x,5,2,mode="wrap");

data = convert.(Float32,collect(range(1,1000,length=1000))); 
smoothed = zeros(eltype(data),length(data)); # <--- wholesome, type stable$
savgol = pyimport("scipy.signal")."savgol_filter";
x = PyObject(data);
benchjl32 = @btime smooth!(SavitzkyGolayFilter{2,2}, data, smoothed);
benchpy32 = @btime $savgol($x,5,2,mode="wrap");
@testset "Correctness" begin
    @test benchpy64 ≈ benchjl64
    @test benchpy32 ≈ benchjl32
end
