#!/usr/bin/env julia

using Cumulants
using SymmetricTensors
using CumulantsUpdates
using JLD2
using FileIO
using ArgParse
using Distributed
import CumulantsUpdates: cnorms

function cumnorms(c::Vector{SymmetricTensor{Float64}})
  map(norm, c[1:2])..., cnorms(c)...
end

function comptime(dm::DataMoments{Float64}, Xup::Matrix{Float64})
  t = time_ns()
  c = cumulantsupdate!(dm, Xup)
  cumnorms(c)
  Float64(time_ns()-t)/1.0e9
end

function precomp(m::Int)
  X = randn(15, 10)
  dm = DataMoments(X[1:10,:], m, 4)
  cumulantsupdate!(dm, X[10:15,:])
end

function savect(u::Vector{Int}, nvec::Vector{Int}, m::Int, p::Int, b::Int)
  comptimes = zeros(length(nvec), length(u))
  precomp(m)
  i = 1
  for n in nvec
    X = randn(maximum(u)+10, n)
    println("n = ", n)
    dm = DataMoments(X, m, b)
    for k in 1:length(u)
      Xup = randn(u[k], n)
      a = comptime(dm, Xup)
      comptimes[i, k] = u[k]/a
      println("u = ", u[k], "f =", div(u[k],a), "Hz")
    end
    i += 1
  end
  filename = replace("res/$(m)_$(u)_$(nvec)_$(p)_$(b)_maxf.jld2", "["=>"")
  filename = replace(filename, "]"=>"")
  filename = replace(filename, " "=>"")
  compt = Dict{String, Any}("cumulants"=> comptimes)
  push!(compt, "t" => u)
  push!(compt, "n" => nvec)
  push!(compt, "m" => m)
  push!(compt, "x" => "n")
  save(filename, compt)
end


function main(args)
  s = ArgParseSettings("description")
  @add_arg_table s begin
      "--order", "-d"
        help = "d, the order of cumulant, ndims of cumulant's tensor"
        default = 4
        arg_type = Int
      "--nvar", "-n"
        help = "n number of marginal variables"
        nargs = '*'
        default = [20, 24, 28]
        help = "n, numbers of marginal variables"
        arg_type = Int
      "--tup", "-u"
        help = "u, numbers of data updates"
        nargs = '*'
        default = [10000, 20000]
        arg_type = Int
      "--nprocs", "-p"
        help = "number of processes"
        default = 3
        arg_type = Int
      "--blocksize", "-b"
         help = "the size of blocks of the block structure"
         default = 4
         arg_type = Int
    end
  parsed_args = parse_args(s)
  m = parsed_args["order"]
  n = parsed_args["nvar"]
  u = parsed_args["tup"]
  p = parsed_args["nprocs"]
  b = parsed_args["blocksize"]
  if p > 1
    addprocs(p)
    eval(Expr(:toplevel, :(@everywhere using CumulantsUpdates)))
  end
  println("number of workers = ", nworkers())
  savect(u, n, m, p, b)
end

main(ARGS)
