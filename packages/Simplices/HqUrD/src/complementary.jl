function complementary(v::AbstractArray{Float64}, n::Int64)
  ns = collect(1:n)
  setdiff(1:n, v)
end

function complementary(v::Int64, n::Int64)
  ns = collect(1:n)
  setdiff(1:n, v)
end



function complementary(v::AbstractArray{Int64}, n::Int64)
  ns = collect(1:n)
  setdiff(1:n, v)
end
