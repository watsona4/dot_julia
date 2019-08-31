#!/usr/bin/env julia
# del2z <delta.z@aliyun.com>

using Flux

using Flux.Tracker

W = param(2) # 2.0 (tracked)
b = param(3) # 3.0 (tracked)

f(x) = W * x + b

grads = Tracker.gradient(() -> f(4), params(W, b))

grads[W] # 4.0
grads[b] # 1.0
