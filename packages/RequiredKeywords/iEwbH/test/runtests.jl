using RequiredKeywords
using Base.Test

# Assignment form
@required_keywords f(a; x, y::Int, z::Int=2) = a * x * y * z

# Standard form
@required_keywords function g(a; x, y::Int, z::Int=2)
    a * x * y * z
end
