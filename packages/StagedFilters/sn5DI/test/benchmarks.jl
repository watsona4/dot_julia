using StagedFilters
using Test

using PyCall, BenchmarkTools;
data = convert.(Float64,collect(range(1,1000,length=1000)));
smoothed = zeros(eltype(data),length(data)); # <--- wholesome, type stable code.
savgol = pyimport("scipy.signal")."savgol_filter";
x = PyObject(data);

@info "Julia f32x1000"
@btime smooth!(SavitzkyGolayFilter{2,2}, data, smoothed);
@info "SciPy f32x1000"
@btime $savgol($x,5,2,mode="wrap");

data = convert.(Float32,collect(range(1,1000,length=1000)));
smoothed = zeros(eltype(data),length(data)); # <--- wholesome, type stable$
savgol = pyimport("scipy.signal")."savgol_filter";
x = PyObject(data);

@info "Julia f64x1000"
@btime smooth!(SavitzkyGolayFilter{2,2}, data, smoothed);
@info "SciPy f64x1000"
@btime $savgol($x,5,2,mode="wrap");
nothing;
