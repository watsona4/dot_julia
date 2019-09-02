#=
hdf5utils.jl
Utilities for reading HDF5 data files for the 2019 fastMRI challenge.
Code by Steven Whitaker
Documentation by Jeff Fessler
=#

export h5_get_keys, h5_get_attributes, h5_get_ismrmrd
export h5_get_ESC, h5_get_RSS, h5_get_kspace

using HDF5


"""
`h5_getkeys(filename::String)`
Get `names` from file.  Returns a `?`
"""
function h5_get_keys(filename::String)

	return h5open(filename, "r") do file
		names(file)
	end

end


"""
`h5_get_attributes(filename::String)`
Get `attrs` from file.  Returns a `Dict`
"""
function h5_get_attributes(filename::String)

	return h5open(filename, "r") do file
		a = attrs(file)
		attr = Dict{String,Any}()
		for s in names(a)
			attr[s] = read(a[s])
		end
		attr
	end

end

"""
`h5_get_ismrmrd(filename::String)`
Get ISMRM header data from file.  Returns a `?`
"""
function h5_get_ismrmrd(filename::String)

	return h5read(filename, "ismrmrd_header")

end


"""
`h5_get_ESC(filename::String; T::DataType = ComplexF32)`
Return `Array` of ESC (emulated single coil) data from file.

HDF5.jl reads the data differently than Python's h5py.
This is significant because the fastMRI paper
says that the datasets have certain dimensionality,
but the dimensions are permuted in Julia compared to Python,
hence the calls to `permutedims` in the following functions.
"""
function h5_get_ESC(filename::String; T::DataType = ComplexF32)

	data = T.(h5read(filename, "reconstruction_esc"))
	return permutedims(data, ndims(data):-1:1)

end


"""
`h5_get_RSS(filename::String; T::DataType = ComplexF32)`
Return `Array` of RSS (root sum of squares) data from file.
"""
function h5_get_RSS(filename::String; T::DataType = ComplexF32)

	data = T.(h5read(filename, "reconstruction_rss"))
	return permutedims(data, ndims(data):-1:1)

end


"""
`h5_get_kspace(filename::String; T::DataType = ComplexF32))`
Return `Array` of kspace data from file.
"""
function h5_get_kspace(filename::String; T::DataType = ComplexF32)

	data = h5open(filename, "r") do file
		readmmap(file["kspace"], Array{getcomplextype(file["kspace"])})
	end
	return permutedims(T.(data), ndims(data):-1:1)

end


#=
Copied (basically) from
https://github.com/MagneticParticleImaging/MPIFiles.jl/blob/79711bf7af389f9e2dd4b0370e64040e5da1e193/src/Utils.jl#L33
=#
function getcomplextype(dataset)
	T = HDF5.hdf5_to_julia_eltype(
		HDF5Datatype(HDF5.h5t_get_member_type(datatype(dataset).id, 0)))
	return Complex{T}
end
