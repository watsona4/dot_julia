
# set to true to support intel fortran compiler

try 
	println("************************Trying to build ParSpMatVec ******************************")
	useIntelFortran = false

	# construct absolute path
	depsdir  = splitdir(Base.source_path())[1]
	builddir = joinpath(depsdir,"builds")
	srcdir   = joinpath(depsdir,"src")

	println("=== Building ParSpMatVec ===")
	println("depsdir  = $depsdir")
	println("builddir = $builddir")
	println("srcdir   = $srcdir")
	println("useIntel = $useIntelFortran")



	if !isdir(builddir)
		println("creating build directory")
		mkdir(builddir)
		if !isdir(builddir)
			error("Could not create build directory")
		end
	end

	@static if Sys.isunix()
	
		src1 = joinpath(srcdir,"A_mul_B.f90")
		src2 = joinpath(srcdir,"Ac_mul_B.f90")
		outfile = joinpath(builddir,"ParSpMatVec.so")
		
		if useIntelFortran
			run(`ifort -O3 -xHost -fPIC -fpp -openmp -integer-size 64 -diag-disable=7841 -shared  $src1 $src2 -o $outfile`)
		else
			println("fortran version")
			# run(`gfortran --version`)
			run(`gfortran -v -O3 -fPIC -cpp -fopenmp -fdefault-integer-8 -shared $src1 $src2 -o $outfile`)
			println("Done compiling.")
		end
	end

	@static if Sys.iswindows() 
		src1 = joinpath(srcdir,"A_mul_B.f90")
		src2 = joinpath(srcdir,"Ac_mul_B.f90")
		outfile = joinpath(builddir,"ParSpMatVec.dll")
		run(`gfortran --version`)
		run(`gfortran -v -O3 -cpp -fopenmp -fdefault-integer-8 -shared -DBUILD_DLL  $src1 $src2 -o $outfile`)
	end
catch
	@warn "Warning: Unable to build ParSpMatVec"
end



