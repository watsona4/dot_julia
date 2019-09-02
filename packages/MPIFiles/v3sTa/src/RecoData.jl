# MDF reconstruction data is loaded/stored using ImageMeta objects from
# the ImageMetadata.jl package.

export converttometer, imcenter, loadRecoData, saveRecoData

converttometer(x) = ustrip.(uconvert.(u"m",x))
imcenter(img::AxisArray) = map(x->(0.5*(last(x)+first(x))), ImageAxes.filter_space_axes(AxisArrays.axes(img), axisvalues(img)))
imcenter(img::ImageMeta) = imcenter(data(img))

function saveRecoData(filename, image::ImageMeta)
  C = colordim(image) == 0 ? 1 : size(image,colordim(image))
  L = timedim(image) == 0 ? 1 : size(image,timedim(image))

  if colordim(image) == 0
    grid = size(image)[1:3]
  else
    grid = size(image)[2:4]
  end
  N = div(length(data(image)), L*C)
  c = reshape(convert(Array,image), C, N, L )

  params = properties(image)
  params["recoData"] = c
  params["recoFov"] = collect(grid) .* collect(converttometer(pixelspacing(image)))
  params["recoFovCenter"] = collect(converttometer(imcenter(image)))[1:3]
  params["recoSize"] = collect(grid)
  params["recoOrder"] = "xyz"
  if haskey(params,"recoParams")
    params["recoParameters"] = params["recoParams"]
  end

  h5open(filename, "w") do file
    saveasMDF(file, params)
  end
end

function loadRecoData(filename::AbstractString)
  f = MPIFile(filename)
  return loadRecoData(f)
end

function loadRecoData(f::MDFFile)
  header = loadMetadata(f)
  header["datatype"] = "MPI"

  recoParams = recoParameters(f)
  if recoParams != nothing
    header["recoParams"] = recoParams
  end
  im = loadRecoData_(f)
  imMeta = ImageMeta(im, header)

  return imMeta
end

function loadRecoData_(f::MDFFile)
  # preparation for spatial axes
  rsize::Vector{Int64} = recoSize(f)
  pixspacing = (recoFov(f) ./ rsize)*1000u"mm"
  off::Vector{Float64} = vec(recoFovCenter(f))
  offset = [0.0,0.0,0.0]*u"mm"
  if off != nothing
    offset[:] = (off .- 0.5.*recoFov(f))*u"m" .+ 0.5.*pixspacing
  end

  # preparation for time axis
  periodTime = Float64(acqNumAverages(f)*acqFramePeriod(f))*u"s"
  if exists(f.file, "/reconstruction/parameters/nAverages")
    periodTime *= read(f.file, "/reconstruction/parameters/nAverages")
  else
    @warn "No reconstruction averaging number found. tempoaral spacings in axis `:time` might be wrong."
  end

  # load data
  c_::Array{Float32,3} = recoData(f)
  c::Array{Float32,5} = reshape(c_, size(c_,1), rsize[1], rsize[2], rsize[3], size(c_,3))

  return makeAxisArray(c, pixspacing, offset, periodTime)
end


function loadRecoData(f::BrukerFile)
  # preparation for spatial axes
  rsize::Vector{Int64} = recoSize(f)
  pixspacing = (recoFov(f) ./ rsize)*1000u"mm"
  off::Vector{Float64} = vec(recoFovCenter(f))
  offset = [0.0,0.0,0.0]*u"mm"
  if off != nothing
    offset[:] = (off .- 0.5.*recoFov(f))*u"m" .+ 0.5.*pixspacing
  end

  periodTime = 1.0*u"s"

  # load data
  c_::Array{Float32,3} = recoData(f)
  c::Array{Float32,5} = reshape(c_, size(c_,1), rsize[1], rsize[2], rsize[3], size(c_,3))

  return ImageMeta( makeAxisArray(c, pixspacing, offset, periodTime) )
end
