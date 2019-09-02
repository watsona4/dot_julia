import MLJ
import MLJBase
import MLJModels
import MultivariateStats
import ModelSanitizer
import Test

const RidgeRegressor = MLJModels.MultivariateStats_.RidgeRegressor

mutable struct WrappedRidge <: MLJBase.DeterministicNetwork
    ridge_model
end

WrappedRidge(; ridge_model=RidgeRegressor) = WrappedRidge(ridge_model)

function MLJ.fit(model::WrappedRidge, X, y)
    Xs = MLJ.source(X)
    ys = MLJ.source(y)

    stand_model = MLJ.Standardizer()
    stand = MLJ.machine(stand_model, Xs)
    W = MLJ.transform(stand, Xs)

    box_model = MLJ.UnivariateBoxCoxTransformer()
    box = MLJ.machine(box_model, ys)
    z = MLJ.transform(box, ys)

    ridge_model = model.ridge_model
    ridge = MLJ.machine(ridge_model, W, z)
    zhat = MLJ.predict(ridge, W)

    yhat = MLJ.inverse_transform(box, zhat)
    MLJ.fit!(yhat, verbosity=0)

    return yhat
end

boston_task = MLJBase.load_boston()

wrapped_model = WrappedRidge(ridge_model=RidgeRegressor(lambda=0.1))

mach = MLJ.machine(wrapped_model, boston_task)

MLJ.fit!(mach; rows = :)

Test.@test mach.fitresult.nodes[1].data == boston_task.X
Test.@test all(convert(Matrix, mach.fitresult.nodes[1].data) .== convert(Matrix, boston_task.X))
for column in names(boston_task.X)
    Test.@test mach.fitresult.nodes[1].data[column] == boston_task.X[column]
    Test.@test all(mach.fitresult.nodes[1].data[column] .== boston_task.X[column])
end
Test.@test mach.fitresult.nodes[3].data == boston_task.y

ModelSanitizer.sanitize!(ModelSanitizer.Model(mach), ModelSanitizer.Data(boston_task.X), ModelSanitizer.Data(boston_task.y))

Test.@test all(convert(Matrix, mach.fitresult.nodes[1].data) .== 0)
for column in names(boston_task.X)
    Test.@test mach.fitresult.nodes[1].data[column] == zero(boston_task.X[column])
    Test.@test all(mach.fitresult.nodes[1].data[column] .== 0)
end
Test.@test mach.fitresult.nodes[3].data == zero(mach.fitresult.nodes[3].data)
Test.@test all(mach.fitresult.nodes[3].data .== 0)
