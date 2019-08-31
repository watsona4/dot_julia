#if !@isdefined  Distributions
#  using Distributions 
#end

struct MultiUniform <: Distribution
  a::Float64
  b::Float64
  num_param::Integer

  MultiUniform(a::Real, b::Real) = new(a, b, 1)
  MultiUniform(a::Real, b::Real, num_param::Integer) = new(a, b, num_param)
  MultiUniform(num_param::Integer) = new(0.0, 1.0, num_param)
  MultiUniform() = new(0.0, 1.0, 1)
end

mean(d::MultiUniform) = middle(d.a, d.b)
median(d::MultiUniform) = mean(d)

pdf(d::MultiUniform, x::Any) = 1.0 / (d.b - d.a)

function rand(d::MultiUniform)
  result_arr = Vector{Float64}(d.num_param)
  for i in 1:d.num_param
    result_arr[i] = d.a + (d.b - d.a) * rand()
  end
  return result_arr
end
