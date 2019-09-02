# loading and storing custom parameters

export ColoringParams, loadParams, saveParams

function saveParams(filename::AbstractString, path, params::Dict)
  h5open(filename, "w") do file
    saveParams(file, path, params)
  end
end

mutable struct ColoringParams
  cmin
  cmax
  cmap
end

function saveParams(file, path, params::Dict)
  for (key,value) in params
    ppath = joinpath(path,string(key))
    if typeof(value) <: Bool
      write(file, ppath, UInt8(value))
      dset = file[ppath]
      attrs(dset)["isbool"] = "true"
    elseif typeof(value) <: AbstractRange
      write(file, ppath, [first(value),step(value),last(value)])
      dset = file[ppath]
      attrs(dset)["isrange"] = "true"
    elseif value == nothing
      write(file, ppath, "")
      dset = file[ppath]
      attrs(dset)["isnothing"] = "true"
    elseif typeof(value) <: ColoringParams
      tmp = zeros(3)
      tmp[1] = value.cmin
      tmp[2] = value.cmax
      tmp[3] = value.cmap

      write(file, ppath, tmp)
      dset = file[ppath]
      attrs(dset)["iscoloring"] = "true"
    elseif typeof(value) <: Array{ColoringParams,1}
      tmp = zeros(3,length(value))
      for i=1:length(value)
        tmp[1,i] = value[i].cmin
        tmp[2,i] = value[i].cmax
        tmp[3,i] = value[i].cmap
      end
      write(file, ppath, tmp)
      dset = file[ppath]
      attrs(dset)["iscoloringarray"] = "true"
    elseif typeof(value) <: Array{Any}
      write(file, ppath, [v for v in value])
    elseif typeof(value) <: MPIFile
      @debug "Do nothing"
    else
      write(file, ppath, value)
    end
  end
end

function loadParams(filename::AbstractString, path)
  params = h5open(filename, "r") do file
   loadParams(file, path)
 end
  return params
end

function loadParams(file, path)
  params = Dict{Symbol,Any}()

  g = file[path]
  for obj in g
    key = last(splitdir(HDF5.name(obj)))
    data = read(obj)
    attr = attrs(obj)
    if exists(attr, "isbool")
      params[Symbol(key)] = Bool(data)
    elseif exists(attr, "isrange")
      if data[2] == 1
        params[Symbol(key)] = data[1]:data[3]
      else
        params[Symbol(key)] = data[1]:data[2]:data[3]
      end
    elseif exists(attr, "isnothing")
       params[Symbol(key)] = nothing
    elseif exists(attr, "iscoloring")
       params[Symbol(key)] = ColoringParams(data[1], data[2],round(Int64,data[3]))
    elseif exists(attr, "iscoloringarray")
       coloring = ColoringParams[]
       for i=1:size(data,2)
         push!(coloring, ColoringParams(data[1,i], data[2,i],round(Int64,data[3,i])))
       end
       params[Symbol(key)] = coloring
    else
      params[Symbol(key)] = data
    end
  end

  return params
end
