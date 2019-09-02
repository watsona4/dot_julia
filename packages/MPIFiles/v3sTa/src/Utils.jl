export makeAxisArray


# Support for handling complex datatypes in HDF5 files
function writeComplexArray(file, dataset, A::AbstractArray{Complex{T},D}) where {T,D}
  d_type_compound = HDF5.h5t_create(HDF5.H5T_COMPOUND,2*sizeof(T))
  HDF5.h5t_insert(d_type_compound, "r", 0 , HDF5.hdf5_type_id(T))
  HDF5.h5t_insert(d_type_compound, "i", sizeof(T) , HDF5.hdf5_type_id(T))

  shape = collect(reverse(size(A)))
  space = HDF5.h5s_create_simple(D, shape, shape)

  dset_compound = HDF5.h5d_create(file, dataset, d_type_compound, space,
                                  HDF5.H5P_DEFAULT,HDF5.H5P_DEFAULT,HDF5.H5P_DEFAULT)
  HDF5.h5s_close(space)

  HDF5.h5d_write(dset_compound, d_type_compound, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, A)

  HDF5.h5d_close(dset_compound)
  HDF5.h5t_close(d_type_compound)
end

function isComplexArray(file, dataset)
  if eltype(file[dataset]) <: Complex
    return true
  end

  # If complex number support in HDF5 is disabled (or version < 0.12.2)
  if eltype(file[dataset]) <: HDF5.HDF5Compound{2}
    if HDF5.h5t_get_member_name(datatype(file[dataset]).id,0) == "r" &&
      HDF5.h5t_get_member_name(datatype(file[dataset]).id,1) == "i"
      return true
    end
  end
  return false
end

function getComplexType(file, dataset)
  T = HDF5.hdf5_to_julia_eltype(
            HDF5Datatype(
              HDF5.h5t_get_member_type( datatype(file[dataset]).id, 0 )
          )
        )
    return Complex{T}
end

function readComplexArray(file::HDF5File, dataset)
  T = getComplexType(file, dataset)
  A = copy(readmmap(file[dataset],Array{getComplexType(file,dataset)}))
  return A
end

function readComplexArray(filename::String, dataset)
  h5open(filename, "r") do file
    return readComplexArray(file, dataset)
  end
end


function str2uuid(str::String)
  if occursin("-", str)
    str_ = str
  else
    str_ = string(str[1:8],"-",str[9:12],"-",str[13:16],"-",str[17:20],"-",str[21:end])
  end
  try
    u = UUID(str_)
    return u
  catch
    @warn "could not convert to UUID." str_ str
    u = uuid4()
    return u
  end
end
str2uuid(str::Nothing) = str

function makeAxisArray(array::Array{T,5}, pixelspacing, offset, dt) where T
  N = size(array)
  im = AxisArray(array, Axis{:color}(1:N[1]),
		 Axis{:x}(range(offset[1],step=pixelspacing[1],length=N[2])),
		 Axis{:y}(range(offset[2],step=pixelspacing[2],length=N[3])),
		 Axis{:z}(range(offset[3],step=pixelspacing[3],length=N[4])),
		 Axis{:time}(range(0*unit(dt),step=dt,length=N[5])))
  return im
end
