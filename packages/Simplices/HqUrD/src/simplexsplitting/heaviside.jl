heaviside(x::AbstractFloat) = ifelse(x <= 0, zero(x), ifelse(x > 0, one(x), oftype(x,0)))
heaviside(x::Int64) = ifelse(x <= 0, zero(x), ifelse(x > 0, one(x), oftype(x,0)))
heaviside(x::Float64) = ifelse(x <= 0, zero(x), ifelse(x > 0, one(x), oftype(x,0)))


heaviside0(x::AbstractFloat) = ifelse(x < 0, zero(x), ifelse(x >= 0, one(x), oftype(x, 0)))
heaviside0(x::Int64) = ifelse(x < 0, zero(x), ifelse(x >= 0, one(x), oftype(x, 0)))
heaviside0(x::Float64) = ifelse(x < 0, zero(x), ifelse(x >= 0, one(x), oftype(x, 0)))

function heaviside0(v::AbstractArray{Float64})
    m, n = size(v)
    h = zeros(m, n)

    for i in 1:length(v)
      h[i] = heaviside0(v[i])
    end
    return(h)
end


function heaviside0(v::AbstractArray{Int64})
    m, n = size(v)
    h = zeros(m, n)

    for i in 1:length(v)
      h[i] = heaviside0(v[i])
    end
    return(h)
end

function heaviside0(v::Vector{Float64})
    h = zeros(length(v), 1)

    for i in 1:length(v)
      h[i] = heaviside0(v[i])
    end
    return(h)
end

function heaviside0(v::Vector{Int64})
    h = zeros(length(v), 1)

    for i in 1:length(v)
      h[i] = heaviside0(v[i])
    end
    return(h)
end

function heaviside(v::Vector{Float64})
    h = zeros(length(v), 1)

    for i in 1:length(v)
      h[i] = heaviside(v[i])
    end
    return(h)
end

function heaviside(v::AbstractArray{Float64})
    m, n = size(v)
    h = zeros(m, n)

    for i in 1:length(v)
      h[i] = heaviside(v[i])
    end
    return(h)
end

function heaviside(v::AbstractArray{Int64})
    m, n = size(v)
    h = zeros(m, n)

    for i in 1:length(v)
      h[i] = heaviside(v[i])
    end
    return(h)
end

function heaviside(v::Matrix{Int64})
    m, n = size(v)
    h = zeros(m, n)

    for i in 1:length(v)
      h[i] = heaviside(v[i])
    end
    return(h)
end


function heaviside(v::Matrix{Float64})
    m, n = size(v)
    h = zeros(m, n)

    for i in 1:length(v)
      h[i] = heaviside(v[i])
    end
    return(h)
end
