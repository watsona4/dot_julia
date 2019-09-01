#**************************************************************************************
# Input_Batch.jl
# =============== part of the GeoEfficiency.jl package.
#
# all the input from the csv files or for batch work to the package is handled by some function here.
#
#**************************************************************************************

#------------------ consts - globals - imports ----------------------------

using Compat, Compat.MathConstants, Compat.DelimitedFiles
using Compat: @info, @warn, @error, @__MODULE__

isconst(@__MODULE__, :dataFolder ) 	||	const dataFolder = string(@__MODULE__)
isconst(@__MODULE__, :dataDir )		||	const dataDir    = joinpath(homedir(), dataFolder) 	
mkpath(dataDir)

const Detectors  = "Detectors.csv";
const srcHeights = "srcHeights.csv";
const srcRhos    = "srcRhos.csv";
const srcRadii   = "srcRadii.csv";
const srcLengths = "srcLengths.csv";


@enum SrcType srcUnknown=-1 srcPoint=0 srcLine=1 srcDisk=2 srcVolume=3 srcNotPoint =4
global srcType = srcUnknown

#------------------ typeofSrc --------------------------------------

"""
    typeofSrc()::SrcType

return the current value of the global `GeoEfficiency.srcType`.

"""
typeofSrc()::SrcType = srcType  # srcType != SrcType, but

"""
    typeofSrc(x::Int)::SrcType

set and return the value of the global `GeoEfficiency.srcType` corresponding to `x`.

  *  srcUnknown = -1 also any negative integer treated as so, 
  *  srcPoint   = 0, 
  *  srcLine    = 1, 
  *  srcDisk    = 2, 
  *  srcVolume  = 3, 
  *  srcNotPoint = 4 also any greater than 4 integer treated as so.

"""
function typeofSrc(x::Int)::SrcType
	global srcType = if x < 0
					SrcType(-1)
				elseif x > 4
					SrcType(4)
				else
					SrcType(x)
				end
end #function


#------------------------ setSrcToPoint ---------------------------

"""
    setSrcToPoint()::Bool

return whether the source type is a point or not.
"""
setSrcToPoint()::Bool = srcType === srcPoint

"""

    setSrcToPoint(yes::Bool)::Bool

return whether the source type is a point or not after setting `srcType` to `srcPoint` if 
`yes` = `true` else if `yes` = `false` setting it to `srcNotPoint` if it was not already 
set to other non-point type (`srcDisk`, `srcLine`, `srcVolume`).

!!! note
    *  The user can use this function to change the source type any time.
    *  The source type is set the fist time asked for source.

**see also:** [`typeofSrc(::Int)`](@ref).

"""
function setSrcToPoint(yes::Bool)::Bool
	global srcType = if yes 
						srcPoint
					elseif srcType in [srcUnknown, srcPoint] 
						srcNotPoint
					else
						srcType 
					end
	return srcType === srcPoint
end

"""
	setSrcToPoint(prompt::AbstractString)::Bool

return whether the source type is a point or not. only prompt the user to set the source 
type if it were not already set before. 

**see also:** [`typeofSrc(::Int)`](@ref), [`setSrcToPoint(::Bool)`](@ref).

"""
setSrcToPoint(prompt::AbstractString)::Bool = srcType != srcUnknown ?	setSrcToPoint() :
											setSrcToPoint(input(prompt) |> lowercase != "n" )


#---------------------------- detector_info_from_csvFile ------------------------------

"""# UnExported

	 detector_info_from_csvFile(detectors::AbstractString = Detectors, 
                                      datadir::AbstractString = dataDir)
return a vector{Detector} based on information in the file of name `detectors` found in the 
directory `datadir`.

!!! note
    *  if no path is given the second argument `datadir` is default to `$(dataDir)` as set by 
       the constant `dataDir`. 
    *  if no file name is specified the name of the predefined file `$Detectors` as set by 
       the constant `Detectors`. 
    *  the no argument method is the most useful; other methods are mainly for `test propose`.

"""
function detector_info_from_csvFile(detectors::AbstractString = Detectors, 
                                      datadir::AbstractString = dataDir)
    detector_info_array::Matrix{Float64} = Matrix{Float64}(undef, 0, 0)
    @info("opening '$(detectors)'......")
    try
        detector_info_array = readdlm(joinpath(datadir, detectors), ',', header=true)[1];
        return getDetectors(detector_info_array)
		
    catch err
        if isa(err, SystemError) 
		    @error("detector_info_from_csvFile: Some thing went wrong, may be the file '$(joinpath( datadir, detectors))' can't be found")
		end
        rethrow()

    end #try

end #function


#---------------------------- read_from_csvFile --------------------------------

"""# UnExported

	read_from_csvFile(csv_data::AbstractString, 
                       datadir::AbstractString = dataDir)::Vector{Float64}

return Vector{Float64} based on data in csv file named `csv_data`. directory `datadir` point to   
where the file is located default to ``$(dataDir)`` as set by the constant `dataDir`.

"""
function read_from_csvFile(csv_data::AbstractString, datadir::AbstractString = dataDir)::Vector{Float64}
	@info("Opening `$(csv_data)`......")
	try
		indata = readdlm(joinpath(datadir, csv_data), ',',  header=true)[1][:,1]
		return float(indata ) |> sort;

	catch err
	    if isa(err, SystemError) 
		    @error("Some thing went wrong, may be `$(csv_data)` can't be found in `$(datadir)`")
		
		else
		    @error("Some thing went wrong, may be `$(csv_data)` in `$(datadir)` format is bad or empty")
		
		end		
		return Float64[0.0]

	end #try
end #function


#--------------------------- read_batch_info ------------------------------------

"""# UnExported

	read_batch_info()

read `detectors` and `sources` parameters from the predefined csv files.

Return a tuple
	   (detectors_array,
		srcHeights_array,
		srcRhos_array,
		srcRadii_array,
		srcLengths_array,
		GeoEfficiency_isPoint)

"""
read_batch_info() = read_batch_info(dataDir,
                                  Detectors, 
								 srcHeights,
								    srcRhos,
								   srcRadii,
								 srcLengths)


"""# UnExported

	read_batch_info(datadir::AbstractString,
                  detectors::AbstractString, 
                 srcHeights::AbstractString,
                    srcRhos::AbstractString,
                   srcRadii::AbstractString,
                 srcLengths::AbstractString)

read `detectors` and `sources` parameters from the location given in the argument list.

Return a tuple

	   (detectors_array,
		srcHeights_array,
		srcRhos_array,
		srcRadii_array,
		srcLengths_array,
		isPoint)

"""								 
function read_batch_info(datadir::AbstractString,
                       detectors::AbstractString, 
					  srcHeights::AbstractString,
					     srcRhos::AbstractString,
					    srcRadii::AbstractString,
					  srcLengths::AbstractString)

	@info("Starting the Batch Mode ....")
	isPoint = setSrcToPoint("\n Is it a point source {Y|n} ?")

	@info("Reading data from `CSV files` at $datadir .....")
	detectors_array::Vector{Detector} = try  
											detector_info_from_csvFile(detectors, datadir) 
										catch err
											getDetectors()
										 end
	srcHeights_array::Vector{Float64} = read_from_csvFile(srcHeights, datadir)
	srcRhos_array   ::Vector{Float64} = [0.0]
	srcRadii_array  ::Vector{Float64} = [0.0]
	srcLengths_array::Vector{Float64} = [0.0]

	function batchfailure(err::AbstractString)
		@warn(err, ", transfer to direct data input via the `console`......")
		sleep(3); src = source()
		srcHeights_array, srcRhos_array, srcRadii_array  , srcLengths_array   = 
		[src[1].Height] , [src[1].Rho] , [src[2]]        , [src[3]]
		return nothing
	end #function

	if srcHeights_array == [0.0]
		batchfailure("`$(srcHeights)` is not found in `$(datadir)`)")

	elseif isPoint
		srcRhos_array =	read_from_csvFile(srcRhos, datadir)

	else
		srcRadii_array = read_from_csvFile(srcRadii, datadir)
		if srcRadii_array == [0.0]
			batchfailure("`$(srcRadii)` is not found in `$(datadir)`)")

		else
			srcLengths_array = read_from_csvFile(srcLengths, datadir)

		end #if
	end #if
	#println("\n Results log\n=============")
	return (
		detectors_array,
		srcHeights_array,
		srcRhos_array,
		srcRadii_array,
		srcLengths_array,
		isPoint,
		)
end #function


#------------------------- getDetectors -------------------------------------

"""

    getDetectors(detectors_array::Vector{<:Detector} = Detector[])::Vector{Detector}

return the `detectors_array` as Vector{Detector} extended by the entered detectors and sorted according to the 
detector volume. 
prompt the user to input detector parameters from the `console`.

!!! note
    If no array received in the input an empty array will be created to receive the converted detectors.

"""
function getDetectors(detectors_array::Vector{<:Detector} = Detector[])::Vector{Detector}
	Vector{Detector}(detectors_array); @info("Please, input the detector information via the console")
	while(true)
		try
			push!(detectors_array, Detector());

		catch err	
			println(err); @warn("Please: Enter a New Detector")
			continue
		end #try

		lowercase(input(
			"""\n
    	                - To add a new detector press return\n
    	                - To quit press 'q'|'Q' then return\n
			\n\t your Choice: """, :blue))  == "q" && break
	end #while
	return detectors_array |> sort
end #function


"""

	getDetectors(detector_info_array::Matrix{<:Real}, 
					 detectors_array::Vector{<:Detector} = Detector[]; 
					 						   console_FB=true)::Vector{Detector}

return `detectors_array` as Vector{Detector}, after extending it with the successfully converted detectors. while, 
attempt to convert detectors from the information in `detector_info_array`. 

!!! note
    if `console_FB` argument is set to true , the function will call `getDetectors()` to take input
    from the `console` if the `detector_info_array` is empty or contain no numerical element.

"""
function getDetectors(detector_info_array::Matrix{<:Real}, 
						  detectors_array::Vector{<:Detector} = Detector[]; 
						  							console_FB=true)::Vector{Detector}

	if isempty(detector_info_array) 
		if console_FB
			@info("The new detectors information may entered via the console")
			return getDetectors(detectors_array)
		else
		 	error("getDetectors: Empty `detector_info_array`")
		end

	else
		Vector{Detector}(detectors_array)
		for i_th_line = 1:size(detector_info_array)[1]
			try 
				push!(detectors_array, Detector((detector_info_array[i_th_line,:])...))

			catch err
			end #try
		end #for

		return detectors_array |> sort
	end   #if
end #function
