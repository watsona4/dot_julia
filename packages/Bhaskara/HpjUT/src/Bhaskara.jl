module Bhaskara

export bsin, b2sin, bcos


bsin(θ::T) where {T<:Number} = 16(π-θ)θ / (5T(π)^2 - 4(π-θ)θ)

b2sin(θ) = sign(θ) * bsin(abs(θ))

sin(θ::T) where {T<:Number} = b2sin(mod(θ+π, T(2)*π) - π)


sind180(x) = 4(180-x)x / (40500 - (180-x)x)

sind360(x) = sign(x) * sind180(abs(x))

sind(x::Number) = sind360(mod(x+180,360)-180)


bcos(θ::T) where {T<:Number} = (T(π)^2 - 4θ^2) / (T(π)^2+θ^2)

cos(θ::T) where {T<:Number} = b2sin(mod(θ-π/T(2), T(2)*π) - π)


tan(θ::Number) = sin(θ) / cos(θ)

end # module
