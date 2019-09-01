
function add!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, y::Float64, n::Int64=length(x))
   for i in 1:n
       @inbounds res[i] = x[i] + y
   end
   nothing
end

add!(res::AbstractArray{Float64}, x::Float64, y::AbstractArray{Float64}, n::Int64=length(y)) = add!(res, y, x, n)

add!(x::AbstractArray{Float64}, y::Float64, n::Int64=length(x))=add!(x, x, y, n)
add!(x::Float64, y::AbstractArray{Float64}, n::Int64=length(y))=add!(y, y, x, n)

plusone!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, n::Int64=length(x)) = add!(res, x, 1.0, n)
plusone!(x::AbstractArray{Float64}, n=length(x)) = plusone!(x, x, n)


function divide!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, y::AbstractArray{Float64}, n::Int64=length(x))
    for i in 1:n
        @inbounds res[i] = x[i] / y[i]
    end
    nothing
end

divide!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, y::Float64, n::Int64=length(x)) = multiply!(res, x, 1/y, n)
function divide!(res::AbstractArray{Float64}, x::Float64, y::AbstractArray{Float64}, n::Int64=length(y))
    for i in 1:n
        @inbounds res[i] = x / y[i]
    end
    nothing
end
divide!(x::AbstractArray{Float64}, y::AbstractArray{Float64}, n::Int64=length(x)) = divide!(x, x, y, n)
# divide!(x::Float64, y::AbstractArray{Float64}, n::Int64=length(y)) = divide!(y, x, y, n)
divide!(x::AbstractArray{Float64}, y::Float64, n::Int64=length(x)) = divide!(x, x, y, n)



rcp!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, n::Int64=length(x)) = divide!(res, 1.0, x, n)
rcp!(x::AbstractArray{Float64}, n::Int64=length(x))=rcp!(x, x, n)



function multiply!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, y::Float64, n::Int64=length(x))
    for i in 1:n
        @inbounds res[i] = x[i] * y
    end
    nothing
end

function multiply!(res::AbstractArray{Float64}, x::Float64, y::AbstractArray{Float64}, n::Int64=length(y))
    for i in 1:n
        @inbounds res[i] = x * y[i]
    end
    nothing
end

# multiply!(x::Float64, y::AbstractArray{Float64}, n::Int64=length(y)) = multiply!(y, x, y, n)
multiply!(x::AbstractArray{Float64}, y::Float64, n::Int64=length(x)) = multiply!(x, x, y, n)

function sqr!(res::AbstractArray{Float64}, x::AbstractArray{Float64}, n::Int64=length(x))
   for i in 1:n
       @inbounds res[i] = x[i]*x[i]
   end
   nothing
end
sqr!(x::AbstractArray{Float64}, n::Int64=length(x)) = sqr!(x, x, n)


function H1(y, mu, sigmas)
    (y .- mu)./sigmas./sigmas
end
function H2(y, mu, sigmas)
    z = (y .- mu) ./ sigmas
    (z .^2 .-1) ./ sigmas^2 ./ 2
end

function H3(y, mu, sigmas)
    z = (y .- mu)./sigmas
    (z .^3 .- 3 .* z) ./ sigmas^3 ./6
end

function H4(y, mu, sigmas)
    z = (y .- mu)./sigmas
    (z .^ 4 .-6 .* z .^ 2 .+ 3) ./ sigmas^4 ./ 24
end
