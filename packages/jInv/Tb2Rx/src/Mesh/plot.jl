export plot

if Pkg.installed("MATLAB") == Nothing()
	
	function missingPackage()
		
		warn("Install Julia package MATLAB to enable TensorMesh3D mesh plotting.")
		return
		
	end
	
	plot(mesh::TensorMesh3D)                      = missingPackage()
	plot(mesh::TensorMesh3D, u::Array{Int64,1})   = missingPackage()
	plot(mesh::TensorMesh3D, u::Array{Int64,3})   = missingPackage()
	plot(mesh::TensorMesh3D, u::Array{Float64,1}) = missingPackage()
	plot(mesh::TensorMesh3D, u::Array{Float64,3}) = missingPackage()
	
else
	
	using MATLAB
	
	function plot(mesh::TensorMesh3D; f = 1)
		
		v = diag(getVolume(mesh))
		u = log10(v ./ minimum(v)) .+ 1.0
		
		plot(mesh, u; f = f)
		
		return
	
	end
	
	function plot(mesh::TensorMesh3D, u::Array{Int64,1}; f = 1)
		
		u = reshape(u, (mesh.n[1], mesh.n[2], mesh.n[3]))
		
		plot(mesh, u; f = f)
		
	end
	
	function plot(mesh::TensorMesh3D, u::Array{Float64,1}; f = 1)
		
		u = reshape(u, (mesh.n[1], mesh.n[2], mesh.n[3]))
		
		plot(mesh, u; f = f)
		
	end

	function plot(mesh::TensorMesh3D, u::Array{Int64,3}; f = 1)
	
		if (mesh.n[1],mesh.n[2],mesh.n[3]) != size(u)
			error("Incompatible array sizes")
		end
		
		x,y,z = getNodalAxes(mesh)
			
		# set path to Matlab function plotTensorMesh3D.m which resides in the same directory like this Julia function
		(dname,fname) = splitdir(@__FILE__())
		mxcall(:addpath, 0, dname)
	
		# plot
		mxcall(:plotTensorMesh3D, 0, f, x, y, z, u)
	
		return
	
	end

	function plot(mesh::TensorMesh3D, u::Array{Float64,3}; f = 1)
	
		if (mesh.n[1],mesh.n[2],mesh.n[3]) != size(u)
			error("Incompatible array sizes")
		end
		
		x,y,z = getNodalAxes(mesh)
			
		# set path to Matlab function plotTensorMesh3D.m which resides in the same directory like this Julia function
		(dname,fname) = splitdir(@__FILE__())
		mxcall(:addpath, 0, dname)
	
		# plot
		mxcall(:plotTensorMesh3D, 0, f, x, y, z, u)
	
		return
	
	end
	
end