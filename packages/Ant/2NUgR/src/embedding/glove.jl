#!/usr/bin/env julia
# del2z <delta.z@aliyun.com>

module GloVe

using Flux
using Flux: glorot_normal, ADAM, OneHotMatrix, OneHotVector, onehot, onehotbatch, onecold, logitbinarycrossentropy, throttle
using JSON
using DataStructures
using StatsBase

const config = JSON.parsefile(joinpath(@__DIR__, "word2vec.json"))

include("prepro.jl")

function dataset end
function model end
function loss end

end
