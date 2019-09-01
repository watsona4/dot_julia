# Internal functions

```@docs
EmpiricalModeDecomposition.sift!(input::Vector{Float64}, s::EMDSetting)
```

```@docs
EmpiricalModeDecomposition.find_extrema!(x::Vector{Float64}, max_x::Vector{Float64}, max_y::Vector{Float64}, min_x::Vector{Float64}, min_y::Vector{Float64})
```

```@docs
EmpiricalModeDecomposition.linear_extrapolate(x_0::Float64, y_0::Float64, x_1::Float64, y_1::Float64, x::Int64)
```

```@docs
EmpiricalModeDecomposition.evaluate_spline(x::Vector{Float64}, y::Vector{Float64}, n::Int64)
```

