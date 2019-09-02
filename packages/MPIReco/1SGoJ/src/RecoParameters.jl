export saveRecoParams, loadRecoParams, defaultRecoParams, defaultOnlineRecoParams

function defaultRecoParams()
  params = Dict{Symbol,Any}()
  params[:lambd] = 1e-2
  params[:iterations] = 4
  params[:SNRThresh] = 2.0
  params[:minFreq] = 80e3
  params[:maxFreq] = 1.25e6
  params[:sortBySNR] = false
  params[:nAverages] = 1
  params[:repetitionTime] = 0.0
  params[:denoiseWeight] = 0
  params[:loadas32bit] = true
  params[:loadasreal] = false
  params[:sparseTrafo] = nothing
  params[:redFactor] = 0.0
  params[:solver] = "kaczmarz"
  params[:emptyMeasPath] = nothing
  params[:frames] = 1
  params[:spectralCleaning] = true
  params[:recChannels] = [1,2,3]
  params[:reconstructor] = get(ENV,"USER","default")
  params[:firstFrameBG] = 1
  params[:lastFrameBG] = 1

  return params
end

function defaultRecoParamsOld()
  params = Dict{Symbol,Any}()
  params[:lambd] = "1e-2"
  params[:iterations] = "4"
  params[:SNRThresh] = "2"
  params[:minFreq] = "80e3"
  params[:maxFreq] = "1.25e6"
  params[:sortBySNR] = "false"
  params[:nAverages] = "1"
  params[:repetitionTime] = "0.0"
  params[:denoiseWeight] = "0"
  params[:loadas32bit] = "true"
  params[:loadasreal] = "false"
  params[:maxload] = "100"
  params[:sparseTrafo] = "nothing"
  params[:redFactor] = "0.0"
  params[:solver] = "kaczmarz"
  params[:bEmpty] = "nothing"

  return params
end

function defaultOnlineRecoParams()
  params = defaultRecoParams()
  params[:iterations] = 1
  params[:SNRThresh] = 5

  return params
end

function saveRecoParams(filename::AbstractString, params)
  ini = Inifile()
  for (key,value) in params
    set(ini, string(key), string(value) )
  end
  open(filename,"w") do fd
    write(fd, ini)
  end
end

to_bool(s::AbstractString) = (lowercase(s) == "true") ? true : false
to_bool(b::Bool) = b

function loadRecoParams(filename::AbstractString)
  ini = Inifile()

  if isfile(filename)
    read(ini, filename)
  end

  params = defaultRecoParamsOld()

  for key in [:lambd, :SNRThresh, :minFreq, :maxFreq, :repetitionTime, :denoiseWeight, :redFactor]
    params[key] = parse(Float64,get(ini,"","$key", params[key]))
  end

  for key in [:iterations, :nAverages, :maxload]
    params[key] = parse(Int,get(ini,"","$key", params[key]))
  end

  for key in [:sortBySNR, :loadas32bit, :loadasreal]
    params[key] = to_bool(get(ini,"","$key", params[key]))
  end

  sparseTrafo = get(ini,"","sparseTrafo", params[:sparseTrafo])
  params[:sparseTrafo] = (sparseTrafo == "nothing") ? nothing : sparseTrafo
  params[:solver] = get(ini,"","solver", params[:solver])

  params[:bEmpty] = get(ini,"bEmpty")
  if params[:bEmpty] == :notfound
    params[:bEmpty] = nothing
  end

  params[:SFPath] = get(ini,"SFPath")
  if params[:SFPath] == :notfound
    params[:SFPath] = nothing
  else
    params[:SFPath] = String[strip(path) for path in split(params[:SFPath],",")]
  end

  params[:SFPathFreq] = get(ini,"SFPathFreq")
  if params[:SFPathFreq] == :notfound
    params[:SFPathFreq] = nothing
  else
    params[:SFPathFreq] = String[strip(path) for path in split(params[:SFPathFreq],",")]
  end

  recChanStr = get(ini,"recChannels")
  if recChanStr != :notfound
    params[:recChannels] = [parse(Int,chan) for chan in split(recChanStr,",")]
  end

  return params
end
