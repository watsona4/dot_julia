using ModelSanitizer
using Statistics
using Test

mutable struct LinearModel{T}
    X::Matrix{T}
    y::Vector{T}
    beta::Vector{T}
    function LinearModel{T}()::LinearModel{T} where T
        m::LinearModel{T} = new()
        return m
    end
end

function fit!(m::LinearModel{T}, X::Matrix{T}, y::Vector{T})::LinearModel{T} where T
    m.X = deepcopy(X)
    m.y = deepcopy(y)
    m.beta = beta = (m.X'm.X)\(m.X'm.y)
    return m
end

function predict(m::LinearModel{T}, X::Matrix{T})::Vector{T} where T
    y_hat::Vector{T} = X * m.beta
    return y_hat
end

function predict(m::LinearModel{T})::Vector{T} where T
    X::Matrix{T} = m.X
    y_hat::Vector{T} = predict(m, X)
    return y_hat
end

function mse(y::Vector{T}, y_hat::Vector{T})::T where T
    _mse::T = mean((y .- y_hat).^2)
    return _mse
end

function mse(m::LinearModel{T}, X::Matrix{T}, y::Vector{T})::T where T
    y_hat::Vector{T} = predict(m, X)
    _mse::T = mse(y, y_hat)
    return _mse
end

function mse(m::LinearModel{T})::T where T
    X::Matrix{T} = m.X
    y::Vector{T} = m.y
    _mse::T = mse(m, X, y)
    return _mse
end

rmse(varargs...) = sqrt(mse(varargs...))

function r2(y::Vector{T}, y_hat::Vector{T})::T where T
    y_bar::T = mean(y)
    SS_tot::T = sum((y .- y_bar).^2)
    SS_res::T = sum((y .- y_hat).^2)
    _r2::T = 1 - SS_res/SS_tot
    return _r2
end

function r2(m::LinearModel{T}, X::Matrix{T}, y::Vector{T})::T where T
    y_hat::Vector{T} = predict(m, X)
    _r2::T = r2(y, y_hat)
    return _r2
end

function r2(m::LinearModel{T})::T where T
    X::Matrix{T} = m.X
    y::Vector{T} = m.y
    _r2::T = r2(m, X, y)
    return _r2
end

X = randn(Float64, 200, 14)
y = X * randn(Float64, 14) + randn(200)
m = LinearModel{Float64}()
testing_rows = 1:2:200
training_rows = setdiff(1:200, testing_rows)
fit!(m, X[training_rows, :], y[training_rows])

@test m.X == X[training_rows, :]
@test m.y == y[training_rows]
@test all(m.X .== X[training_rows, :])
@test all(m.y .== y[training_rows])
@test !all(m.X .== 0)
@test !all(m.y .== 0)

# before sanitization, we can make predictions
predict(m, X[testing_rows, :])
predict(m, X[training_rows, :])
@show mse(m, X[training_rows, :], y[training_rows])
@show rmse(m, X[training_rows, :], y[training_rows])
@show r2(m, X[training_rows, :], y[training_rows])
@show mse(m, X[testing_rows, :], y[testing_rows])
@show rmse(m, X[testing_rows, :], y[testing_rows])
@show r2(m, X[testing_rows, :], y[testing_rows])

sanitize!(Model(m), Data(X), Data(y)) # sanitize the model with ModelSanitizer

@test m.X != X[training_rows, :]
@test m.y != y[training_rows]
@test !all(m.X .== X[training_rows, :])
@test !all(m.y .== y[training_rows])
@test all(m.X .== 0)
@test all(m.y .== 0)

# after sanitization, we are still able to make predictions
predict(m, X[testing_rows, :])
predict(m, X[training_rows, :])
@show mse(m, X[training_rows, :], y[training_rows])
@show rmse(m, X[training_rows, :], y[training_rows])
@show r2(m, X[training_rows, :], y[training_rows])
@show mse(m, X[testing_rows, :], y[testing_rows])
@show rmse(m, X[testing_rows, :], y[testing_rows])
@show r2(m, X[testing_rows, :], y[testing_rows])

# if you know exactly where the data are stored inside the model, you can
# directly delete them with ForceSanitize:
sanitize!(ForceSanitize(m.X), ForceSanitize(m.y))

# we can still make predictions even after using ForceSanitize
predict(m, X[testing_rows, :])
predict(m, X[training_rows, :])
@show mse(m, X[training_rows, :], y[training_rows])
@show rmse(m, X[training_rows, :], y[training_rows])
@show r2(m, X[training_rows, :], y[training_rows])
@show mse(m, X[testing_rows, :], y[testing_rows])
@show rmse(m, X[testing_rows, :], y[testing_rows])
@show r2(m, X[testing_rows, :], y[testing_rows])
