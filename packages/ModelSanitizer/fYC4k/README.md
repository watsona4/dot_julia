# ModelSanitizer

<p>
<a
href="https://app.bors.tech/repositories/19368">
<img
src="https://bors.tech/images/badge_small.svg"
alt="Bors enabled">
</a>
<a
href="https://travis-ci.com/bcbi/ModelSanitizer.jl/branches">
<img
src="https://travis-ci.com/bcbi/ModelSanitizer.jl.svg?branch=master">
</a>
<a
href="https://codecov.io/gh/bcbi/ModelSanitizer.jl">
<img
src="https://codecov.io/gh/bcbi/ModelSanitizer.jl/branch/master/graph/badge.svg">
</a>
</p>

## Usage

ModelSanitizer exports the `sanitize!` function and the `Model`, `Data`, and
`ForceSanitize` structs.

If your model is stored in `m` and your data are stored in `x1`,
`x2`, `x3`, etc. then you can sanitize your model with:
```julia
sanitize!(Model(m), Data(x1), Data(x2), Data(x3), ...)
```

This will recursively search inside the model `m` for anything that resembles
your data and will delete the data that it finds.

If you happen to know exactly where inside a model the data are stored, you
can explicitly tell ModelSanitizer to delete those data. If your model is
stored in `m`, and you know that the fields `m.x1`, `m.x2`, `m.x3`, etc. contain
data that needs to be removed, you can force ModelSanitizer to delete those
data with:
```julia
sanitize!(ForceSanitize(m.x1), ForceSanitize(m.x2), ForceSanitize(m.x3), ...)
```

## Example

```julia
julia> using ModelSanitizer

julia> using Statistics

julia> using Test

julia> mutable struct LinearModel{T}
           X::Matrix{T}
           y::Vector{T}
           beta::Vector{T}
           function LinearModel{T}()::LinearModel{T} where T
               m::LinearModel{T} = new()
               return m
           end
       end

julia> function fit!(m::LinearModel{T}, X::Matrix{T}, y::Vector{T})::LinearModel{T} where T
           m.X = deepcopy(X)
           m.y = deepcopy(y)
           m.beta = beta = (m.X'm.X)\(m.X'm.y)
           return m
       end
fit! (generic function with 1 method)

julia> function predict(m::LinearModel{T}, X::Matrix{T})::Vector{T} where T
           y_hat::Vector{T} = X * m.beta
           return y_hat
       end
predict (generic function with 1 method)

julia> function predict(m::LinearModel{T})::Vector{T} where T
           X::Matrix{T} = m.X
           y_hat::Vector{T} = predict(m, X)
           return y_hat
       end
predict (generic function with 2 methods)

julia> function mse(y::Vector{T}, y_hat::Vector{T})::T where T
           _mse::T = mean((y .- y_hat).^2)
           return _mse
       end
mse (generic function with 1 method)

julia> function mse(m::LinearModel{T}, X::Matrix{T}, y::Vector{T})::T where T
           y_hat::Vector{T} = predict(m, X)
           _mse::T = mse(y, y_hat)
           return _mse
       end
mse (generic function with 2 methods)

julia> function mse(m::LinearModel{T})::T where T
           X::Matrix{T} = m.X
           y::Vector{T} = m.y
           _mse::T = mse(m, X, y)
           return _mse
       end
mse (generic function with 3 methods)

julia> rmse(varargs...) = sqrt(mse(varargs...))
rmse (generic function with 1 method)

julia> function r2(y::Vector{T}, y_hat::Vector{T})::T where T
           y_bar::T = mean(y)
           SS_tot::T = sum((y .- y_bar).^2)
           SS_res::T = sum((y .- y_hat).^2)
           _r2::T = 1 - SS_res/SS_tot
           return _r2
       end
r2 (generic function with 1 method)

julia> function r2(m::LinearModel{T}, X::Matrix{T}, y::Vector{T})::T where T
           y_hat::Vector{T} = predict(m, X)
           _r2::T = r2(y, y_hat)
           return _r2
       end
r2 (generic function with 2 methods)

julia> function r2(m::LinearModel{T})::T where T
           X::Matrix{T} = m.X
           y::Vector{T} = m.y
           _r2::T = r2(m, X, y)
           return _r2
       end
r2 (generic function with 3 methods)

julia> X = randn(Float64, 5_000, 14)
5000×14 Array{Float64,2}:
  0.0956436    0.481324   -0.796437  …  -2.26483     1.57243    -1.65105
 -0.306527    -0.880146   -0.764714     -0.182449   -0.0767462  -0.939232
 -0.223116    -0.408068    0.728855      0.220045    0.785533    0.49013
 -0.336363     1.46187    -1.17633      -0.955872    0.699277    0.587961
  0.628275     0.208697   -0.522714      0.116233    0.47314     0.435968
 -0.12303     -0.964061    0.919518  …  -0.0230613  -1.12379    -0.439892
  1.06664      0.96542    -0.250164     -0.776266    1.70851    -1.08608
  0.957151     0.850486    1.31718       0.497219    1.01069    -0.558217
 -0.206168    -0.608305   -0.864631      0.969031    0.209796    1.28718
 -0.658039     1.20687     1.33288       1.54847     0.546286   -1.00404
 -0.598782    -0.193289    0.673134  …  -1.59742     0.410881   -1.61342
  0.31442      0.0199012   0.50533       1.0889     -0.0713841  -1.29933
  0.236585    -1.09804     0.945631     -0.729247   -1.10004    -0.339332
  0.122913     0.619345   -2.90947       1.09613    -0.662693   -1.03469
  1.52615      0.942471    0.262139      0.223064    0.665103    1.4081
 -0.474543     1.9466     -0.408505  …   1.01626    -0.297397   -0.0953909
  0.73664     -0.0796424  -1.84864       1.15935     0.0164378   1.32191
  0.24588      0.271068   -0.238212      0.596475    1.52617    -0.747777
  ⋮                                  ⋱
 -1.07141      0.194049   -0.350011     -0.666195    0.481406   -0.451329
 -0.00993413   0.33006    -0.985443     -0.0395822   2.36983    -0.793007
  0.610014    -0.509744   -1.06447   …   1.19769     1.129       0.397217
  0.785654    -0.361031    0.314127      0.192215    0.789262    0.725731
  0.258588    -2.06379     0.511611      0.0963516  -1.01919    -0.540021
  0.48671     -0.918205    0.264124      0.989929    2.45245    -1.39545
 -1.27085     -0.0617834   2.59491       0.291602    1.28642     0.236496
  1.4044      -1.24472    -0.205029  …   1.99366    -1.58951     0.963728
 -1.07691      0.44178    -0.602841      0.584759   -0.887116    1.36514
  1.13586      0.954756    0.44016      -2.21191    -1.14086    -0.585916
 -0.763031    -1.13348    -1.46696      -1.4121     -0.977694   -0.618883
  0.875367    -1.30925     0.183117      0.224709    0.0752964  -0.92173
  0.659502     0.71971    -1.05538   …  -0.912277   -0.736332    1.01404
 -0.809941     2.02362     1.29668       0.113623   -0.858281    0.0863472
 -1.6409       0.310551   -0.235102     -1.11232    -0.170224    0.404804
 -0.367908    -1.9062      0.245953     -0.751821   -0.794633    0.00894607
  0.380897     2.30871    -0.669909      0.282513   -0.114725   -0.253537

julia> y = X * randn(Float64, 14) + randn(5_000)
5000-element Array{Float64,1}:
 -4.418867382994752
  1.0721553534178543
  2.210545604666476
 -2.5053994409702094
  2.24399399066432
  0.5993702994926247
  2.2040361967638322
 -2.4902628750358193
  4.184644001244288
  1.7688752332135804
 -4.831550352023476
 -1.068149084362266
 -0.746260929030723
  0.032933800577055417
  2.878202216460962
  2.773804353610833
  1.0288912118472482
  3.7799578982964963
  ⋮
  3.1797791441997822
  5.830717537973503
 -0.8191545280972992
  4.649281267724443
  0.9470989605451162
  5.733118456044454
  3.057352206232011
  4.791267454465988
 -4.604222639675081
 -5.755448165821573
 -0.9804279159155482
  2.2904285226467276
  2.809999802793834
  0.7773010780323945
 -2.5205742651574
  3.8866539005621092
 -4.085889556008112

julia> m = LinearModel{Float64}()
LinearModel{Float64}(#undef, #undef, #undef)

julia> testing_rows = 1:2:5_000
1:2:4999

julia> training_rows = setdiff(1:5_000, testing_rows)
2500-element Array{Int64,1}:
    2
    4
    6
    8
   10
   12
   14
   16
   18
   20
   22
   24
   26
   28
   30
   32
   34
   36
    ⋮
 4968
 4970
 4972
 4974
 4976
 4978
 4980
 4982
 4984
 4986
 4988
 4990
 4992
 4994
 4996
 4998
 5000

julia> fit!(m, X[training_rows, :], y[training_rows])
LinearModel{Float64}([-0.306527 -0.880146 … -0.0767462 -0.939232; -0.336363 1.46187 … 0.699277 0.587961; … ; -1.6409 0.310551 … -0.170224 0.404804; 0.380897 2.30871 … -0.114725 -0.253537], [1.07216, -2.5054, 0.59937, -2.49026, 1.76888, -1.06815, 0.0329338, 2.7738, 3.77996, -4.06727  …  2.81088, 3.17978, -0.819155, 0.947099, 3.05735, -4.60422, -0.980428, 2.81, -2.52057, -4.08589], [-0.532213, -1.16489, -0.414974, -0.562536, -0.440432, 0.732505, -1.06754, 0.399485, -0.67281, -1.44599, 0.835625, 0.426459, 1.20088, 0.754435])

julia> @test m.X == X[training_rows, :]
Test Passed

julia> @test m.y == y[training_rows]
Test Passed

julia> @test all(m.X .== X[training_rows, :])
Test Passed

julia> @test all(m.y .== y[training_rows])
Test Passed

julia> @test !all(m.X .== 0)
Test Passed

julia> @test !all(m.y .== 0)
Test Passed

julia> # before sanitization, we can make predictions
       predict(m, X[testing_rows, :])
2500-element Array{Float64,1}:
 -4.513253714187381
  2.5689035333536605
  0.9939782906365846
  1.2513894159362184
  3.2007086601687353
 -5.387968774216589
 -0.1767892797746935
  3.4408813711668165
  0.4625821018811823
  1.649129884116436
 -0.8620887900500149
  0.6504970487658756
  4.287913533796443
 -2.5014166099065136
  1.1666979326633855
  0.2723098985354143
  3.2783930370766634
  2.250636815003683
  ⋮
  1.1999638265752477
  3.8377489399901084
  4.2805489451765935
 -0.5849048693472063
 -0.6574890049656816
  0.2606368302418087
 -4.197310605534758
 -3.5805273324146336
 -0.5244747588662737
  5.274904154193373
  2.7742388165636953
  5.883741172337488
  2.118699747786167
 -4.209943069147431
  2.262361580682631
 -0.5044151513387216
  4.443422779093501

julia> predict(m, X[training_rows, :])
2500-element Array{Float64,1}:
  2.943212508610099
 -0.8226863248850258
  1.031068845178503
 -3.3178919274576053
  0.587046578244962
 -0.032251634503744686
  1.9123819046207888
  3.555603804394087
  2.1728937544760307
 -1.9319447549669504
 -0.7592148524301295
 -7.250437603426189
  4.982277986708986
 -1.8660967909674548
  0.29423182806971415
  0.593840341165224
 -0.26314562641917977
  1.4340414682799685
  ⋮
  1.6038174714835796
  1.3091787016871341
  4.936123830680592
  1.9812183495287048
 -0.848632475032059
  3.1553721781769157
 -5.412240178264108
  1.406559298117795
  3.6433312336276646
  0.3408165307792135
  0.2882242203753349
  1.8120206189755343
 -3.299798877655878
 -0.8793971451160698
  2.3158119962568886
 -2.4598360012327265
 -4.810128269819875

julia> @show mse(m, X[training_rows, :], y[training_rows])
mse(m, X[training_rows, :], y[training_rows]) = 0.9856973993855034
0.9856973993855034

julia> @show rmse(m, X[training_rows, :], y[training_rows])
rmse(m, X[training_rows, :], y[training_rows]) = 0.9928229446308658
0.9928229446308658

julia> @show r2(m, X[training_rows, :], y[training_rows])
r2(m, X[training_rows, :], y[training_rows]) = 0.9044357103305194
0.9044357103305194

julia> @show mse(m, X[testing_rows, :], y[testing_rows])
mse(m, X[testing_rows, :], y[testing_rows]) = 0.9480778102674918
0.9480778102674918

julia> @show rmse(m, X[testing_rows, :], y[testing_rows])
rmse(m, X[testing_rows, :], y[testing_rows]) = 0.9736928726592856
0.9736928726592856

julia> @show r2(m, X[testing_rows, :], y[testing_rows])
r2(m, X[testing_rows, :], y[testing_rows]) = 0.9088387716983182
0.9088387716983182

julia> sanitize!(Model(m), Data(X), Data(y)) # sanitize the model with ModelSanitizer
Model{LinearModel{Float64}}(LinearModel{Float64}([0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; … ; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0  …  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], [-0.532213, -1.16489, -0.414974, -0.562536, -0.440432, 0.732505, -1.06754, 0.399485, -0.67281, -1.44599, 0.835625, 0.426459, 1.20088, 0.754435]))

julia> @test m.X != X[training_rows, :]
Test Passed

julia> @test m.y != y[training_rows]
Test Passed

julia> @test !all(m.X .== X[training_rows, :])
Test Passed

julia> @test !all(m.y .== y[training_rows])
Test Passed

julia> @test all(m.X .== 0)
Test Passed

julia> @test all(m.y .== 0)
Test Passed

julia> # after sanitization, we are still able to make predictions
       predict(m, X[testing_rows, :])
2500-element Array{Float64,1}:
 -4.513253714187381
  2.5689035333536605
  0.9939782906365846
  1.2513894159362184
  3.2007086601687353
 -5.387968774216589
 -0.1767892797746935
  3.4408813711668165
  0.4625821018811823
  1.649129884116436
 -0.8620887900500149
  0.6504970487658756
  4.287913533796443
 -2.5014166099065136
  1.1666979326633855
  0.2723098985354143
  3.2783930370766634
  2.250636815003683
  ⋮
  1.1999638265752477
  3.8377489399901084
  4.2805489451765935
 -0.5849048693472063
 -0.6574890049656816
  0.2606368302418087
 -4.197310605534758
 -3.5805273324146336
 -0.5244747588662737
  5.274904154193373
  2.7742388165636953
  5.883741172337488
  2.118699747786167
 -4.209943069147431
  2.262361580682631
 -0.5044151513387216
  4.443422779093501

julia> predict(m, X[training_rows, :])
2500-element Array{Float64,1}:
  2.943212508610099
 -0.8226863248850258
  1.031068845178503
 -3.3178919274576053
  0.587046578244962
 -0.032251634503744686
  1.9123819046207888
  3.555603804394087
  2.1728937544760307
 -1.9319447549669504
 -0.7592148524301295
 -7.250437603426189
  4.982277986708986
 -1.8660967909674548
  0.29423182806971415
  0.593840341165224
 -0.26314562641917977
  1.4340414682799685
  ⋮
  1.6038174714835796
  1.3091787016871341
  4.936123830680592
  1.9812183495287048
 -0.848632475032059
  3.1553721781769157
 -5.412240178264108
  1.406559298117795
  3.6433312336276646
  0.3408165307792135
  0.2882242203753349
  1.8120206189755343
 -3.299798877655878
 -0.8793971451160698
  2.3158119962568886
 -2.4598360012327265
 -4.810128269819875

julia> @show mse(m, X[training_rows, :], y[training_rows])
mse(m, X[training_rows, :], y[training_rows]) = 0.9856973993855034
0.9856973993855034

julia> @show rmse(m, X[training_rows, :], y[training_rows])
rmse(m, X[training_rows, :], y[training_rows]) = 0.9928229446308658
0.9928229446308658

julia> @show r2(m, X[training_rows, :], y[training_rows])
r2(m, X[training_rows, :], y[training_rows]) = 0.9044357103305194
0.9044357103305194

julia> @show mse(m, X[testing_rows, :], y[testing_rows])
mse(m, X[testing_rows, :], y[testing_rows]) = 0.9480778102674918
0.9480778102674918

julia> @show rmse(m, X[testing_rows, :], y[testing_rows])
rmse(m, X[testing_rows, :], y[testing_rows]) = 0.9736928726592856
0.9736928726592856

julia> @show r2(m, X[testing_rows, :], y[testing_rows])
r2(m, X[testing_rows, :], y[testing_rows]) = 0.9088387716983182
0.9088387716983182

julia> # if you know exactly where the data are stored inside the model, you can
       # directly delete them with ForceSanitize:
       sanitize!(ForceSanitize(m.X), ForceSanitize(m.y))
(ForceSanitize{Array{Float64,2}}([0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; … ; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]), ForceSanitize{Array{Float64,1}}([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0  …  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]))

julia> # we can still make predictions even after using ForceSanitize
       predict(m, X[testing_rows, :])
2500-element Array{Float64,1}:
 -4.513253714187381
  2.5689035333536605
  0.9939782906365846
  1.2513894159362184
  3.2007086601687353
 -5.387968774216589
 -0.1767892797746935
  3.4408813711668165
  0.4625821018811823
  1.649129884116436
 -0.8620887900500149
  0.6504970487658756
  4.287913533796443
 -2.5014166099065136
  1.1666979326633855
  0.2723098985354143
  3.2783930370766634
  2.250636815003683
  ⋮
  1.1999638265752477
  3.8377489399901084
  4.2805489451765935
 -0.5849048693472063
 -0.6574890049656816
  0.2606368302418087
 -4.197310605534758
 -3.5805273324146336
 -0.5244747588662737
  5.274904154193373
  2.7742388165636953
  5.883741172337488
  2.118699747786167
 -4.209943069147431
  2.262361580682631
 -0.5044151513387216
  4.443422779093501

julia> predict(m, X[training_rows, :])
2500-element Array{Float64,1}:
  2.943212508610099
 -0.8226863248850258
  1.031068845178503
 -3.3178919274576053
  0.587046578244962
 -0.032251634503744686
  1.9123819046207888
  3.555603804394087
  2.1728937544760307
 -1.9319447549669504
 -0.7592148524301295
 -7.250437603426189
  4.982277986708986
 -1.8660967909674548
  0.29423182806971415
  0.593840341165224
 -0.26314562641917977
  1.4340414682799685
  ⋮
  1.6038174714835796
  1.3091787016871341
  4.936123830680592
  1.9812183495287048
 -0.848632475032059
  3.1553721781769157
 -5.412240178264108
  1.406559298117795
  3.6433312336276646
  0.3408165307792135
  0.2882242203753349
  1.8120206189755343
 -3.299798877655878
 -0.8793971451160698
  2.3158119962568886
 -2.4598360012327265
 -4.810128269819875

julia> @show mse(m, X[training_rows, :], y[training_rows])
mse(m, X[training_rows, :], y[training_rows]) = 0.9856973993855034
0.9856973993855034

julia> @show rmse(m, X[training_rows, :], y[training_rows])
rmse(m, X[training_rows, :], y[training_rows]) = 0.9928229446308658
0.9928229446308658

julia> @show r2(m, X[training_rows, :], y[training_rows])
r2(m, X[training_rows, :], y[training_rows]) = 0.9044357103305194
0.9044357103305194

julia> @show mse(m, X[testing_rows, :], y[testing_rows])
mse(m, X[testing_rows, :], y[testing_rows]) = 0.9480778102674918
0.9480778102674918

julia> @show rmse(m, X[testing_rows, :], y[testing_rows])
rmse(m, X[testing_rows, :], y[testing_rows]) = 0.9736928726592856
0.9736928726592856

julia> @show r2(m, X[testing_rows, :], y[testing_rows])
r2(m, X[testing_rows, :], y[testing_rows]) = 0.9088387716983182
0.9088387716983182
```
