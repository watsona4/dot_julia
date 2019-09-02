export Positions, GridPositions, RegularGridPositions, ChebyshevGridPositions,
       MeanderingGridPositions, UniformRandomPositions, ArbitraryPositions,
       SphericalTDesign, BreakpointGridPositions
export SpatialDomain, AxisAlignedBox, Ball
export loadTDesign, getPermutation
export fieldOfView, fieldOfViewCenter, shape
export idxToPos, posToIdx, posToLinIdx, spacing, isSubgrid, deriveSubgrid

abstract type Positions end
abstract type GridPositions<:Positions end

function Positions(file::HDF5File)
  typ = read(file, "/positionsType")
  if typ == "RegularGridPositions"
    positions = RegularGridPositions(file)
  elseif typ == "ChebyshevGridPositions"
    positions = ChebyshevGridPositions(file)
  elseif typ == "SphericalTDesign"
    positions = SphericalTDesign(file)
  elseif typ == "UniformRandomPositions"
    positions = UniformRandomPositions(file)
  elseif typ == "ArbitraryPositions"
    positions = ArbitraryPositions(file)
  else
    throw(ErrorException("No grid found to load from $file"))
  end

  if exists(file, "/positionsMeandering") && typ in ["CartesianGrid","ChebyshevGrid"] && read(file, "/positionsMeandering") == Int8(1)
    positions = MeanderingGridPositions(positions)
  end

  return positions
end

# Cartesian grid
mutable struct RegularGridPositions{T} <: GridPositions where {T<:Unitful.Length}
  shape::Vector{Int}
  fov::Vector{T}
  center::Vector{T}
  sign::Vector{Int}
end

function range(grid::RegularGridPositions, dim::Int)
  if grid.shape[dim] > 1
    sp = spacing(grid)
    return range(grid.center[dim] - grid.fov[dim]/2 + sp[dim]/2,
                 step=sp[dim], length=grid.shape[dim])
  else
    return 1:1
  end
end

RegularGridPositions(shape, fov, center) = RegularGridPositions(shape, fov, center, ones(Int,length(shape)))

function RegularGridPositions(file::HDF5File)
  shape = read(file, "/positionsShape")
  fov = read(file, "/positionsFov")*Unitful.m
  center = read(file, "/positionsCenter")*Unitful.m
  return RegularGridPositions(shape,fov,center)
end

# Find a joint grid
function RegularGridPositions(positions::Vector{T}) where T<:RegularGridPositions
  posMin = positions[1].center .- 0.5*positions[1].fov
  posMax = positions[1].center .+ 0.5*positions[1].fov
  minSpacing = spacing(positions[1])
  for position in positions
    sp = spacing(position)
    for d=1:length(posMin)
      posMin[d] = min(posMin[d], position.center[d] - 0.5*position.fov[d])
      posMax[d] = max(posMax[d], position.center[d] + 0.5*position.fov[d])
      minSpacing[d] = min(minSpacing[d],sp[d])
    end
  end
  center = (posMin .+ posMax)/2
  fov = posMax .- posMin
  shape = round.(Int64,fov./minSpacing)
  fov = shape .* minSpacing
  return RegularGridPositions(shape, fov, center)
end

function isSubgrid(grid::RegularGridPositions, subgrid::RegularGridPositions)
  if any(fieldOfView(grid) .- fieldOfView(subgrid) .< 0) ||
     any(spacing(grid) .!= spacing(subgrid))
    return false
  else
    centerPosIdx = posToIdxFloat(grid,subgrid[ones(Int,length(subgrid.shape))])
    return all(isapprox.(centerPosIdx, round.(Int,centerPosIdx) ,rtol=1e-5))
  end
end

function deriveSubgrid(grid::RegularGridPositions, subgrid::RegularGridPositions)
  minI = ones(Int,length(subgrid.shape))
  maxI = copy(subgrid.shape)
  for d=1:length(minI)
    if subgrid.sign[d] == -1
      minI[d] = subgrid.shape[d]-minI[d]+1
      maxI[d] = subgrid.shape[d]-maxI[d]+1
    end
  end
  minPos = subgrid[ minI ]
  maxPos = subgrid[ maxI ]

  minIdx = posToIdx(grid,minPos)
  maxIdx = posToIdx(grid,maxPos)
  #shp = maxIdx-minIdx+ones(Int,length(subgrid.shape))
  shp = shape(subgrid)
  #center = (grid[minIdx].+grid[maxIdx])/2
  # TODO round properly
  center = (grid[minIdx].+grid[minIdx.+shp.-1])/2
  fov = shp.*spacing(grid)
  return RegularGridPositions(shp,fov,center,subgrid.sign)
end

function write(file::HDF5File, positions::RegularGridPositions)
  write(file,"/positionsType", "RegularGridPositions")
  write(file, "/positionsShape", positions.shape)
  write(file, "/positionsFov", Float64.(ustrip.(uconvert.(Unitful.m, positions.fov))) )
  write(file, "/positionsCenter", Float64.(ustrip.(uconvert.(Unitful.m, positions.center))) )
end

function getindex(grid::RegularGridPositions, i::Integer)
  if i>length(grid) || i<1
     throw(BoundsError(grid,i))
  end

  #idx = collect(ind2sub(tuple(shape(grid)...), i))
  if length(grid.shape) == 1 #Very ugly but improves compile time
    idx = [i]
  elseif length(grid.shape) == 2
    idx = collect(Tuple((CartesianIndices(tuple(grid.shape[1],grid.shape[2])))[i]))
  else
    idx = collect(Tuple((CartesianIndices(tuple(grid.shape[1],grid.shape[2],grid.shape[3])))[i]))
  end

  for d=1:length(idx)
    if grid.sign[d] == -1
      idx[d] = grid.shape[d]-idx[d]+1
    end
  end
  return ((-shape(grid).+(2 .*idx.-1))./shape(grid)).*fieldOfView(grid)./2 + fieldOfViewCenter(grid)
end

function getindex(grid::RegularGridPositions, idx::Vector{T}) where T<:Number
  for d=1:length(idx)
    if grid.sign[d] == -1
      idx[d] = grid.shape[d]-idx[d]+1
    end
  end
  return 0.5.*fieldOfView(grid) .* (-1 .+ (2 .* idx .- 1) ./ shape(grid)) .+ fieldOfViewCenter(grid)
end

function posToIdxFloat(grid::RegularGridPositions,pos::Vector)
  idx = 0.5 .* (shape(grid) .* ((pos .- fieldOfViewCenter(grid)) ./
              ( 0.5 .* fieldOfView(grid) ) .+ 1) .+ 1)
  return idx
end

function posToIdx(grid::RegularGridPositions,pos::Vector)
  idx = round.(Int64, posToIdxFloat(grid,pos))
  for d=1:length(idx)
    if grid.sign[d] == -1
      idx[d] = grid.shape[d]-idx[d]+1
    end
  end
  return idx
end

function posToLinIdx(grid::RegularGridPositions,pos::Vector)
  return (LinearIndices(tuple(shape(grid)...)))[posToIdx(grid,pos)...]
end

# Chebyshev Grid
mutable struct ChebyshevGridPositions{S,T} <: GridPositions where {S,T<:Unitful.Length}
  shape::Vector{Int}
  fov::Vector{S}
  center::Vector{T}
end

function write(file::HDF5File, positions::ChebyshevGridPositions)
  write(file,"/positionsType", "ChebyshevGridPositions")
  write(file, "/positionsShape", positions.shape)
  write(file, "/positionsFov", Float64.(ustrip.(uconvert.(Unitful.m, positions.fov))) )
  write(file, "/positionsCenter", Float64.(ustrip.(uconvert.(Unitful.m, positions.center))) )
end

function ChebyshevGridPositions(file::HDF5File)
  shape = read(file, "/positionsShape")
  fov = read(file, "/positionsFov")*Unitful.m
  center = read(file, "/positionsCenter")*Unitful.m
  return ChebyshevGridPositions(shape,fov,center)
end

function getindex(grid::ChebyshevGridPositions, i::Integer)
  if i>length(grid) || i<1
    throw(BoundsError(grid,i))
  else
    idx = collect(Tuple(CartesianIndices(tuple(shape(grid)...))[i]))
    return -cos.((idx .- 0.5) .* pi ./ shape(grid)) .* fieldOfView(grid) ./ 2 .+ fieldOfViewCenter(grid)
  end
end

# Meander regular grid positions
mutable struct MeanderingGridPositions{T} <: GridPositions where {T<:GridPositions}
  grid::T
end

function MeanderingGridPositions(file::HDF5File)
  typ = read(file, "/positionsType")
  if typ == "RegularGridPositions"
    grid = RegularGridPositions(file)
    return MeanderingGridPositions(grid)
  elseif typ == "ChebyshevGridPositions"
    grid = ChebyshevGridPositions(file)
    return MeanderingGridPositions(grid)
  end
end

function write(file::HDF5File, positions::MeanderingGridPositions)
  write(file,"/positionsMeandering", Int8(1))
  write(file, positions.grid)
end

function indexPermutation(grid::MeanderingGridPositions, i::Integer)
  dims = tuple(shape(grid)...)
  idx = collect(Tuple(CartesianIndices(dims)[i]))
    for d=2:3
      if isodd(sum(idx[d:3])-length(idx[d:3]))
      idx[d-1] = shape(grid)[d-1] + 1 - idx[d-1]
    end
  end
  linidx = (LinearIndices(dims))[idx...]
end

function getindex(grid::MeanderingGridPositions, i::Integer)
  iperm = indexPermutation(grid,i)
  return grid.grid[iperm]
end

function getPermutation(grid::MeanderingGridPositions)
  N = length(grid)
  perm = Array{Int}(undef,N)

  for i in eachindex(perm)
    perm[i] = indexPermutation(grid,i)
  end
  return vec(perm)
end

mutable struct BreakpointGridPositions{T,S} <: GridPositions where {T<:GridPositions}
  grid::T
  breakpointIndices::Vector{Int64}
  breakpointPosition::Vector{S}
end

function BreakpointGridPositions(file::HDF5File)
  typ = read(file, "/positionsType")
  breakpointIndices = read(file, "/positionsBreakpoint")
  breakpointPosition = read(file, "/indicesBreakpoint")

  if typ == "MeanderingGridPositions"
    grid = MeanderingGridPositions(file)
    return BreakpointGridPositions(grid,breakpointIndices, breakpointPosition)
  elseif typ == "RegularGridPositions"
    grid = RegularGridPositions(file)
    return BreakpointGridPositions(grid,breakpointIndices, breakpointPosition)
  elseif typ == "ChebyshevGridPositions"
    grid = ChebyshevGridPositions(file)
    return BreakpointGridPositions(grid,breakpointIndices, breakpointPosition)
  end
end

function write(file::HDF5File, positions::BreakpointGridPositions)
  write(file,"/positionsBreakpoint",Float64.(ustrip.(uconvert.(Unitful.m, positions.breakpointPosition))))
  write(file,"/indicesBreakpoint", positions.breakpointIndices)
  write(file, positions.grid)
end


function getmask(grid::BreakpointGridPositions)
  bgind=grid.breakpointIndices
  mask = zeros(Bool, length(grid.grid)+length(bgind))
  mask[bgind] .= true
  return mask
end

function getindex(grid::BreakpointGridPositions, i::Integer)

  bgind=grid.breakpointIndices

  if i>(length(grid.grid)+length(bgind)) || i<1
    return throw(BoundsError(grid,i))
  elseif any(i .== bgind)
    return grid.breakpointPosition
  else
    pastBgind = sum(i .> bgind)
    return grid.grid[i-pastBgind]
  end
end

# Uniform random distributed positions
abstract type SpatialDomain end

struct AxisAlignedBox <: SpatialDomain
  fov::Vector{S} where {S<:Unitful.Length}
  center::Vector{T} where {T<:Unitful.Length}
end

function write(file::HDF5File, domain::AxisAlignedBox)
  write(file, "/positionsDomain", "AxisAlignedBox")
  write(file, "/positionsDomainFieldOfView", Float64.(ustrip.(uconvert.(Unitful.m, domain.fov))) )
  write(file, "/positionsDomainCenter", Float64.(ustrip.(uconvert.(Unitful.m, domain.center))) )
end

function AxisAlignedBox(file::HDF5File)
  fov = read(file, "/positionsDomainFieldOfView")*Unitful.m
  center = read(file, "/positionsDomainCenter")*Unitful.m
  return AxisAlignedBox(fov,center)
end

struct Ball <: SpatialDomain
  radius::S where {S<:Unitful.Length}
  center::Vector{T} where {T<:Unitful.Length}
end

function write(file::HDF5File, domain::Ball)
  write(file, "/positionsDomain", "Ball")
  write(file, "/positionsDomainRadius", Float64.(ustrip.(uconvert.(Unitful.m, domain.radius))) )
  write(file, "/positionsDomainCenter", Float64.(ustrip.(uconvert.(Unitful.m, domain.center))) )
end

function Ball(file::HDF5File)
  radius = read(file, "/positionsDomainRadius")*Unitful.m
  center = read(file, "/positionsDomainCenter")*Unitful.m
  return Ball(radius,center)
end


mutable struct UniformRandomPositions{T} <: Positions where {T<:SpatialDomain}
  N::UInt
  seed::UInt32
  domain::T
end

radius(rpos::UniformRandomPositions{Ball}) = rpos.domain.radius
seed(rpos::UniformRandomPositions) = rpos.seed

function getindex(rpos::UniformRandomPositions{AxisAlignedBox}, i::Integer)
  if i>length(rpos) || i<1
    throw(BoundsError(rpos,i))
  else
    # make sure Positions are randomly generated from given seed
    mersenneTwister = MersenneTwister(seed(rpos))
    rP = rand(mersenneTwister, 3, i)[:,i]
    return (rP.-0.5).*fieldOfView(rpos)+fieldOfViewCenter(rpos)
  end
end

function getindex(rpos::UniformRandomPositions{Ball}, i::Integer)
  if i>length(rpos) || i<1
    throw(BoundsError(rpos,i))
  else
    # make sure Positions are randomly generated from given seed
    mersenneTwister = MersenneTwister(seed(rpos))
    D = rand(mersenneTwister, i)[i]
    P = randn(mersenneTwister, 3, i)[:,i]
    return radius(rpos)*D^(1/3)*normalize(P)+fieldOfViewCenter(rpos)
  end
end

function write(file::HDF5File, positions::UniformRandomPositions{T}) where {T<:SpatialDomain}
  write(file, "/positionsType", "UniformRandomPositions")
  write(file, "/positionsN", positions.N)
  write(file, "/positionsSeed", positions.seed)
  write(file, positions.domain)
end

function UniformRandomPositions(file::HDF5File)
  N = read(file, "/positionsN")
  seed = read(file, "/positionsSeed")
  dom = read(file,"/positionsDomain")
  if dom=="Ball"
    domain = Ball(file)
    return UniformRandomPositions(N,seed,domain)
  elseif dom=="AxisAlignedBox"
    domain = AxisAlignedBox(file)
    return UniformRandomPositions(N,seed,domain)
  else
    throw(ErrorException("No method to read domain $domain"))
  end
end

# TODO fix conversion methods
#=
function convert(::Type{UniformRandomPositions}, N::Integer,seed::UInt32,fov::Vector{S},center::Vector{T}) where {S,T<:Unitful.Length}
  if N<1
    throw(DomainError())
  else
    uN = convert(UInt,N)
    return UniformRandomPositions(uN,seed,fov,center)
  end
end

function convert(::Type{UniformRandomPositions}, N::Integer,fov::Vector,center::Vector)
  return UniformRandomPositions(N,rand(UInt32),fov,center)
end
=#


# General functions for handling grids
fieldOfView(grid::GridPositions) = grid.fov
fieldOfView(grid::UniformRandomPositions{AxisAlignedBox}) = grid.domain.fov
fieldOfView(mgrid::MeanderingGridPositions) = fieldOfView(mgrid.grid)
fieldOfView(bgrid::BreakpointGridPositions) = fieldOfView(bgrid.grid)
shape(grid::GridPositions) = grid.shape
shape(mgrid::MeanderingGridPositions) = shape(mgrid.grid)
shape(bgrid::BreakpointGridPositions) = shape(bgrid.grid)
fieldOfViewCenter(grid::GridPositions) = grid.center
fieldOfViewCenter(grid::UniformRandomPositions) = grid.domain.center
fieldOfViewCenter(mgrid::MeanderingGridPositions) = fieldOfViewCenter(mgrid.grid)
fieldOfViewCenter(bgrid::BreakpointGridPositions) = fieldOfViewCenter(bgrid.grid)

spacing(grid::GridPositions) = grid.fov ./ grid.shape

mutable struct SphericalTDesign{S,V} <: Positions where {S,V<:Unitful.Length}
  T::Unsigned
  radius::S
  positions::Matrix
  center::Vector{V}
end

function SphericalTDesign(file::HDF5File)
  T = read(file, "/positionsTDesignT")
  N = read(file, "/positionsTDesignN")
  radius = read(file, "/positionsTDesignRadius")*Unitful.m
  center = read(file, "/positionsCenter")*Unitful.m
  return loadTDesign(Int64(T),N,radius,center)
end

function write(file::HDF5File, positions::SphericalTDesign)
  write(file,"/positionsType", "SphericalTDesign")
  write(file, "/positionsTDesignT", positions.T)
  write(file, "/positionsTDesignN", size(positions.positions,2))
  write(file, "/positionsTDesignRadius", Float64.(ustrip.(uconvert.(Unitful.m, positions.radius))) )
  write(file, "/positionsCenter", Float64.(ustrip.(uconvert.(Unitful.m, positions.center))) )
end

getindex(tdes::SphericalTDesign, i::Integer) = tdes.radius.*tdes.positions[:,i] + tdes.center

"""
    loadTDesign(t::Int64, N::Int64, radius::S=10Unitful.mm, center::Vector{V}=[0.0,0.0,0.0]Unitful.mm, filename::String=joinpath(@__DIR__, "TDesigns.hd5")) where {S,V<:Unitful.Length}
*Description:* Returns the t-design array for chosen degree t and number of points N\\
\\
*Input:* 
- `t` - degree 
- `N` - number of points
- `radius` - radius of the sphere (default: 10mm)
- `center` - center of the sphere (default: [0.0,0.0,0.0]mm)
- `filename` - name of the file containing the t-designs (default loads TDesign.hd5)

*Output:*
- t-design of type SphericalTDesign in Cartesian coordinates containing t, radius, center and positions (which are located on the unit sphere unless `getindex(tdes,i)` is used)
"""
function loadTDesign(t::Int64, N::Int64, radius::S=10Unitful.mm, center::Vector{V}=[0.0,0.0,0.0]Unitful.mm, filename::String=joinpath(@__DIR__, "TDesigns.hd5")) where {S,V<:Unitful.Length}
  h5file = h5open(filename, "r")
  address = "/$t-Design/$N"

  if exists(h5file, address)
    positions = copy(transpose(read(h5file, address)))
    return SphericalTDesign(UInt(t),radius,positions, center)
  else
    if exists(h5file, "/$t-Design/")
      Ns = Int[]
      for N in keys(read(h5file, string("/$t-Design")))
	push!(Ns,parse(Int,N))
      end
      sort!(Ns)
      @info "No spherical $t-Design with $N points availible!\nThere are spherical $t-Designs with following N:" Ns
      throw(DomainError(1))
    else
      ts = Int[]
      for d in keys(read(h5file))
	m = match(r"(\d{1,})-(Design)",d)
	if m != nothing
	  push!(ts,parse(Int,m[1]))
        end
      end
      sort!(ts)
      @info "No spherical $t-Design availible!\n Choose another t."
      throw(DomainError(1))
    end
  end
end

# Unstructured collection of positions
mutable struct ArbitraryPositions{T} <: Positions where {T<:Unitful.Length}
  positions::Matrix{T}
end

getindex(apos::ArbitraryPositions, i::Integer) = apos.positions[:,i]

function ArbitraryPositions(grid::GridPositions)
  T = eltype(grid.fov)
  positions = zeros(T,3,length(grid))
  for i=1:length(grid)
    positions[:,i] = grid[i]
  end
  return ArbitraryPositions(positions)
end

function write(file::HDF5File, apos::ArbitraryPositions,)
  write(file,"/positionsType", "ArbitraryPositions")
  write(file, "/positionsPositions", Float64.(ustrip.(uconvert.(Unitful.m, apos.positions))) )
end

function ArbitraryPositions(file::HDF5File)
  pos = read(file, "/positionsPositions")*Unitful.m
  return ArbitraryPositions(pos)
end


# fuction related to looping
length(tdes::SphericalTDesign) = size(tdes.positions,2)
length(apos::ArbitraryPositions) = size(apos.positions,2)
length(grid::GridPositions) = prod(grid.shape)
length(rpos::UniformRandomPositions) = rpos.N
length(mgrid::MeanderingGridPositions) = length(mgrid.grid)
length(bgrid::BreakpointGridPositions) = length(bgrid.grid)+length(bgrid.breakpointIndices)

start_(grid::Positions) = 1
next_(grid::Positions,state) = (grid[state],state+1)
done_(grid::Positions,state) = state > length(grid)
iterate(grid::Positions, s=start_(grid)) = done_(grid, s) ? nothing : next_(grid, s)


include("Interpolation.jl")
