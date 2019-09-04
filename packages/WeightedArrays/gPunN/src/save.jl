
export save, load

# import JLD2
using DelimitedFiles

"""
    save(Π, "file.csv") = writecsv("file.csv", Π)
    save(Π, "file.json")
    save(Π, "file.jld") = JLD.save(file, "Π", Π)
Save `Π::Weighted` to disk, in one of several formats:

* CSV: weights are rightmost column, as in `[Π.array' Π.weights]`.
  Options aren't saved, and `load()` will try to guess them from the numbers.
  Mathematica: `arr = Import["file.csv"][[;; , 1 ;; -2]]; wei = Import["file.csv"][[;; , -1]]`

* JSON: saves a dictionary, but `dict["array"]` is a nested Vector{Vector{Any}} for now,
  which `load()` converts to Float64. Includes `dict["opt"] == String(Π.opt)`.
  Mathematica: `arr = Import["file.json"][[1, 2]]; wei = Import["file.json"][[3, 2]]`
  ... and then maybe `Style @@@ Thread[{arr, PointSize /@ (0.3*Sqrt[wei]), Opacity[0.5]}] // ListPlot` ?

* JLD: built-in HDF5 format binary saving, fast & neat but perhaps fragile.
  Removed for now!


    Π = load("file.csv") = readcsv("file.csv", Π)
    Π = load("file.json")
    Π = load("file.jld") = JLD.load(file, "Π")
Reverse the above.
"""
function save(x::Weighted, file::String; verbose=true)
    if endswith(file, ".csv")
        writecsv(file, x)
    elseif endswith(file, ".json")
        writejson(file, x)
    # elseif endswith(file, ".jld")
    #     JLD.save(file, "Π", x)
    else
        error("load doesn't understand file extension of $file")
    end
end

save(file::String, x::Weighted; kw...) = save(x, file; kw...)

@doc @doc(save)
function load(file::String)
    if endswith(file, ".csv")
        readcsv(file, Weighted)
    elseif endswith(file, ".json")
        readjson(file)
    # elseif endswith(file, ".jld")
    #     JLD.load(file, "Π")
    else
        error("save doesn't understand file extension of $file")
    end
end


# writecsv(io, x::Weighted; kw...) = writedlm(io, [x.array' x.weights], ','; kw...)
writecsv(io, x::Weighted; kw...) = writedlm(io, [x.array' |> copy x.weights], ','; kw...) ## copy for Flux bug with Adjoint

function readcsv(io, T::Type{Weighted}; kw...)

    mat = readdlm(io, ','; kw...)
    array = mat[:, 1:end-1]' |> copy
    weights = mat[:,end]

    norm = sum(weights)≈1
    if minimum(array)>=0 && maximum(array)<=1
        clamp,lo,hi = true,0,1
    else
        clamp,lo,hi = false,-Inf,Inf
    end
    if endswith(string(io), ".csv")
        aname = string(io)[1:end-4] |> Symbol
    else
        aname = string(io) |> Symbol
    end

    Weighted(array, weights, WeightOpt(norm=norm, clamp=clamp,lo=lo,hi=hi, aname=aname))
end

# Base.writecsv(io, x::Weighted; kw...) = writecsv(io, (x.array, x.weights, [x.opt.norm, x.opt.clamp, x.opt.lo, x.opt.lo, x.opt.names]); kw...)

import JSON

function writejson(io, x::Weighted)
    d = Dict("array" => x.array, "weights" => x.weights, "opt" => string(x.opt))
    write(io, JSON.json(d))
end

function readjson(io)
    d = JSON.parse(read(io, String))

    array = reduce(hcat, d["array"]) |> Matrix{Float64}
    weights = d["weights"] |> Vector{Float64}
    opt = eval(Meta.parse(d["opt"]))

    Weighted(array, weights, opt)
end
