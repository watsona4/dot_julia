#!/usr/bin/env julia

using PyCall
@pyimport matplotlib as mpl
mpl.rc("text", usetex=true)
mpl.use("Agg")
@pyimport matplotlib.ticker as mti
using PyPlot
using JLD2
using FileIO
using ArgParse

o = 1
function singleplot(filename::String)
  d = load(filename*".jld2")
  x = d["x"]
  t = d["t"]
  n = d["n"]
  m = d["m"]
  println(m)
  mpl.rc("font", family="serif", size = 7)
  fig, ax = subplots(figsize = (2.5, 2.))
  col = ["red", "blue", "green", "gray", "brown", "orange"]
  marker = [":s", ":o", ":v", ":<", ":>", ":d"]
  for i in 1:size(d["cumulants"], 2)
    if occursin("nblocks", filename)  | occursin("maxf", filename)
      tt = t[i]
      ax[:plot](d[x], d["cumulants"][:,i], marker[i], label= "\$ t_{up} \$ = $tt", color = col[i], markersize=2.5, linewidth = 1)
    elseif occursin("nprocs", filename)
      tt = t[i]
      y = d["cumulants"][:,i].\d["cumulants"][1,i]
      ax[:plot](d[x][1:6], y[1:6], marker[i], label= "\$ t_{up} \$ = $tt", color = col[i], markersize=2.5, linewidth = 1)
    else
      tt =  n[i]
      comptimes = d["cumulants"][:,i]./d["cumulants updat"][:,i]
      ax[:plot](d[x], comptimes, marker[i], label= "n = $tt", color = col[i], markersize=2.5, linewidth = 1)
      #i == size(d["cumulants"], 2)? ax[:plot](d[x], d["tm"], ":<", label= "theoretical", color = "black", markersize=2.5, linewidth = 1):()
    end
  end
  subplots_adjust(bottom = 0.16, top=0.92, left = 0.12, right = 0.92)
  fx = matplotlib[:ticker][:ScalarFormatter]()
  fx[:set_powerlimits]((-1, 4))
  ax[:xaxis][:set_major_formatter](fx)
  if occursin("nblocks", filename)
    subplots_adjust(left = 0.15)
    PyPlot.ylabel("computational time [s]", labelpad = 0.6)
    PyPlot.xlabel(x, labelpad = 0.6)
    ax[:xaxis][:set_major_locator](mti.MaxNLocator(integer=true))
    ax[:legend](fontsize = 5, loc = 9, ncol = 1)
  elseif occursin("nprocs", filename)
    subplots_adjust(left = 0.15)
    PyPlot.ylabel("computational speedup", labelpad = 0)
    PyPlot.xlabel(x, labelpad = 0.6)
    ax[:xaxis][:set_major_locator](mti.MaxNLocator(integer=true))
    ax[:legend](fontsize = 5, loc = 2, ncol = 1)
  elseif occursin("maxf", filename)
    subplots_adjust(left = 0.18)
    PyPlot.ylabel("frequency [Hz]", labelpad = 0.)
    PyPlot.xlabel(x, labelpad = 0.6)
    ax[:legend](fontsize = 5, loc = 1, ncol = 1)
  else
    PyPlot.ylabel("computational speedup", labelpad = -0.5)
    PyPlot.xlabel("\$ t_{up} \$", labelpad = 0.6)
    subplots_adjust(bottom = 0.16, top=0.92, left = 0.14, right = 0.92)
    if m == 6
      ax[:yaxis][:set_major_locator](mti.MaxNLocator(integer=true))
    end
    ax[:legend](fontsize = 6, loc = 1, ncol = 1)
  end
  f = matplotlib[:ticker][:ScalarFormatter]()
  f[:set_powerlimits]((-3, 2))
  ax[:yaxis][:set_major_formatter](f)
  fig[:savefig]("cumulants"*filename*".pdf")
end


function main(args)
  s = ArgParseSettings("description")
  @add_arg_table s begin
    "file"
    help = "the file name"
    arg_type = String
  end
  parsed_args = parse_args(s)
  filename = parsed_args["file"]
  singleplot(replace(filename, ".jld2"=>""))
end

main(ARGS)
