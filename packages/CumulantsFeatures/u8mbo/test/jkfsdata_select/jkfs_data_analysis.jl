#!/usr/bin/env julia

using JLD2
using FileIO
using ArgParse
using PyCall
using SymmetricTensors
@pyimport matplotlib as mpl
@pyimport matplotlib.colors as mc
mpl.rc("text", usetex=true)
mpl.use("Agg")
using PyPlot


#ν = 30
#data = load("tstudent_$ν-t_size-50_malfsize-5-t_100000.jld")


function union_size(list1::Vector, list2::Vector)
  return length(list1 ∩ list2)
end

#malf_size = data["malf_size"]
#var_number = data["variables_no"]
#t = data["sample_number"]
#repeating = data["test_number"]

function features_selection_results(data::Dict, d::Int = 0)
  malf_size = data["malf_size"]
  check_size = malf_size

  labels = ["malf"]
  algorithms = ["MEV", "JKN", "JSBS", "JKFS"]
  #algorithms = ["MEV", "JKFS"]
  data_parts_label = sort([ "bands_$(alg)_$l" for l=labels for alg=algorithms])
  plot_data = Dict()
  for label = data_parts_label
    plot_data[label] = zeros(Int, malf_size+1)
  end

  for m=1:length(data["data"]), label = data_parts_label
    list1 = data["data"]["$m"][label][end-check_size+1-d:end]
    list2 = data["data"]["$m"]["malf"]
    no_common = union_size(list1, list2)
    plot_data[label][no_common+1] += 1
  end
plot_data, data_parts_label
end


#keys_sorted = sort(collect(keys(plot_data)))
#hcat([plot_data[k] for k=keys_sorted]...)

function theoretical(sizedata::Int, malfsize::Int, found::Int)
  binomial(malfsize, found)*binomial(sizedata-malfsize, malfsize-found)/binomial(sizedata,malfsize)
end

function los(n, ksize, p, r = 500_000)
  ret = []
  for s in 1:r
    b = []
    x = collect(1:n)
    for a in 1:p
      y = rand(x)
      push!(b, y)
      filter!(i -> i != y, x)
    end
    push!(ret, (count(b .<= ksize)))
  end
  [count(ret .== i) for i in 0:ksize]./r, collect(0:ksize)
end


function plotdata(plot_data, data_parts_label, ν, malf_size, var_number, repeating, δ::Int = 0)
  mpl.rc("font", family="serif", size = 7)
  fig, ax = subplots(figsize = (2.5, 2.))
  cols = ["red", "green", "blue", "brown", "grey"]
  p = ["--d", "--o", "--^", "--<", "--v"]
  cla()
  i = 0
  for data_label = data_parts_label
    i += 1
    data_y = plot_data[data_label]
    data_x = collect(0:(length(data_y)-1))
    println(data_y)
    d = replace(data_label, "bands_"=>"")
    plot(data_x, data_y/repeating, p[i], label=replace(d, "_malf"=>""), color = cols[i], linewidth = 0.8, markersize = 3.)
  end
  data_x = 0:malf_size
  #data_y = map(i-> theoretical(var_number, malf_size, i), data_x)
  data_y = los(var_number, malf_size, malf_size+δ)[1]
  plot(data_x, data_y, "--x", label="rand choice", color = "black", linewidth = 1., markersize = 3.)
  if ((ν == 10) * (δ == 0))
    ax[:legend](fontsize = 4.5, loc = 2, ncol = 2)
  end
  subplots_adjust(left = 0.15, bottom = 0.16)
  show()
  xlabel("no. selected features", labelpad = 0.)
  ylabel("selection probability", labelpad = 0.)
  savefig("$(ν)_$(δ)jkfs.pdf")
end

function main(args)
  s = ArgParseSettings("description")
  @add_arg_table s begin
    "file"
    help = "the file name"
    arg_type = String
    "--delta", "-d"
    help = "no. additiona features"
    default = 0
    arg_type = Int
  end
  parsed_args = parse_args(s)
  data = load(parsed_args["file"])
  d = parsed_args["delta"]
  plot_data, data_parts_label = features_selection_results(data, d)
  plotdata(plot_data, data_parts_label, data["ν"], data["malf_size"], data["variables_no"], data["test_number"], d)
end

main(ARGS)
