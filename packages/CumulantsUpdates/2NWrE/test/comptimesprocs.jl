#!/usr/bin/env julia

using Cumulants
using SymmetricTensors
using CumulantsUpdates
using JLD2
using FileIO
using ArgParse
using Distributed

function comptime(dm::DataMoments{Float64}, Xup::Matrix{Float64})
  t = time_ns()
  _ = cumulantsupdate!(dm, Xup)
  Float64(time_ns()-t)/1.0e9
end

function precomp(m::Int)
  X = randn(15, 10)
  dm = DataMoments(X[1:10,:], m, 4)
  cumulantsupdate!(dm, X[10:15,:])
end

function savect(u::Vector{Int}, p::Int, n::Int, m::Int, b::Int)
  comptimes = zeros(p, length(u))
  X = randn(maximum(u)+10, n)
  precomp(m)
  addprocs(p)
  eval(Expr(:toplevel, :(@everywhere using CumulantsUpdates)))
  dm = DataMoments(X, m, b)
  for i in 1:p
    rmprocs(procs()[2:end])
    addprocs(i)
    eval(Expr(:toplevel, :(@everywhere using CumulantsUpdates)))
    println("number of workers = ", nworkers())
    for k in 1:length(u)
      Xup = randn(u[k], n)
      comptimes[i, k] = comptime(dm, Xup)
      println("u = ", u[k])
    end
  end
  filename = replace("res/$(m)_$(u)_$(n)_$(b)_nprocs.jld2", "["=>"")
  filename = replace(filename, "]"=>"")
  filename = replace(filename, " "=>"")
  compt = Dict{String, Any}("cumulants"=> comptimes)
  push!(compt, "t" => u)
  push!(compt, "n" => n)
  push!(compt, "m" => m)
  push!(compt, "x" => "number of procs")
  push!(compt, "number of procs" => [collect(1:p)...])
  push!(compt, "functions" => [["cumulants"]])
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
        default = 48
        help = "n, numbers of marginal variables"
        arg_type = Int
      "--tup", "-u"
        help = "u, numbers of data updates"
        nargs = '*'
        default = [10000, 20000]
        arg_type = Int
      "--blocksize", "-b"
        help = "the size of blocks of the block structure"
        default = 4
        arg_type = Int
      "--nprocs", "-p"
        help = "maximal number of processes"
        default = 6
        arg_type = Int
    end
  parsed_args = parse_args(s)
  m = parsed_args["order"]
  n = parsed_args["nvar"]
  u = parsed_args["tup"]
  p = parsed_args["nprocs"]
  b = parsed_args["blocksize"]
  savect(u, p, n, m, b)
end

main(ARGS)
