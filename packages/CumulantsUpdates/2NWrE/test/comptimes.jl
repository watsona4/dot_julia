#!/usr/bin/env julia

using FileIO
using JLD2
using ArgParse
using CumulantsUpdates
using SymmetricTensors
using Combinatorics
using Distributed
import CumulantsUpdates: cumulants, moment

"""
  cumspeedups(m::Int, n::Vector{Int}, t::Int, tup::Vector{Int}, b::Int)

Returns Vector, a computional speedup of m'th cumulant update of n[i] variate data
"""
function cumspeedups(m::Int, n::Vector{Int}, t::Int, u::Vector{Int}, b::Int, bc::Int = 2)
  compt = zeros(length(u), length(n))
  updt = copy(compt)
  precomp(m)
  for i in 1:length(n)
    println("cumulants calc n = ", n[i])
    X = randn(t, n[i])
    t1 = Float64(time_ns())
    cumulants(X, m, bc)
    compt[:,i] .= Float64(time_ns())-t1
    dm = DataMoments(X, m, b)
    for j in 1:length(u)
      println("update u = ", u[j])
      Xup = rand(u[j], n[i])
      t1 = Float64(time_ns())
      _ = cumulantsupdate!(dm, Xup)
      updt[j,i] = Float64(time_ns()) - t1
    end
  end
  compt, updt
end

"""
  precomp(m::Int)

precompiles updates functions
"""
function precomp(m::Int)
  X = randn(15, 10)
  cumulants(X[1:10,:], m, 2)
  dm = DataMoments(X[1:10,:], m, 4)
  cumulantsupdate!(dm, X[10:15,:])
end

"""
  savecomptime(m::Int, n::Vector{Int}, t::Int, tup::Vector{Int}, b::Int, p::Int)

Saves comptime parameters into a .jld2 file
"""
function savecomptime(m::Int, n::Vector{Int}, t::Int, tup::Vector{Int}, b::Int, p::Int)
  filename = replace("res/$(m)_$(t)_$(n)_$(tup)_$(p).jld2", "["=>"")
  filename = replace(filename, "]"=>"")
  filename = replace(filename, " "=>"")
  compt = Dict{String, Any}()
  cumtime = cumspeedups(m, n, t, tup, b)
  push!(compt, "cumulants" => cumtime[1])
  push!(compt, "cumulants updat" => cumtime[2])
  push!(compt, "tm" => t./(2*tup.+bellnum(m)))
  push!(compt, "t" => t)
  push!(compt, "n" => n)
  push!(compt, "m" => m)
  push!(compt, "tup" => tup)
  push!(compt, "x" => "tup")
  push!(compt, "functions" => [["cumulants", "cumulants updat"]])
  save(filename, compt)
end

"""
  main(args)

Returns plots of the speedup of updates. Takes optional arguments from bash
"""
function main(args)
  s = ArgParseSettings("description")
  @add_arg_table s begin
      "--order", "-d"
        help = "d, the order of cumulant, ndims of cumulant's tensor"
        default = 4
        arg_type = Int
        "--blocksize", "-b"
        help = "the size of blocks of the block structure"
        default = 4
        arg_type = Int
      "--nvar", "-n"
        nargs = '*'
        default = [60]
        help = "n, numbers of marginal variables"
        arg_type = Int
      "--dats", "-t"
        help = "t, numbers of data records"
        default = 500000
        arg_type = Int
      "--updates", "-u"
        help = "u, size of the update"
        nargs = '*'
        default = [12000, 18000, 24000, 30000, 36000]
        arg_type = Int
      "--nprocs", "-p"
        help = "number of processes"
        default = 6
        arg_type = Int
    end
  parsed_args = parse_args(s)
  m = parsed_args["order"]
  n = parsed_args["nvar"]
  t = parsed_args["dats"]
  tup = parsed_args["updates"]
  b = parsed_args["blocksize"]
  p = parsed_args["nprocs"]
  if p > 1
    addprocs(p)
    eval(Expr(:toplevel, :(@everywhere using CumulantsUpdates)))
  end
  println("number of workers = ", nworkers())
  savecomptime(m, n, t, tup, b, p)
end

main(ARGS)
