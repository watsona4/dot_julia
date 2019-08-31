__precompile__()

"""
MADS: Model Analysis & Decision Support in Julia (Mads.jl v1.0) 2016

http://mads.lanl.gov
http://madsjulia.lanl.gov
http://gitlab.com/mads/Mads.jl

Licensing: GPLv3: http://www.gnu.org/licenses/gpl-3.0.html

Copyright 2016.  Los Alamos National Security, LLC.  All rights reserved.

This material was produced under U.S. Government contract DE-AC52-06NA25396 for
Los Alamos National Laboratory, which is operated by Los Alamos National Security, LLC for
the U.S. Department of Energy. The Government is granted for itself and others acting on its
behalf a paid-up, nonexclusive, irrevocable worldwide license in this material to reproduce,
prepare derivative works, and perform publicly and display publicly. Beginning five (5) years after
--------------- November 17, 2015, ----------------------------------------------------------------
subject to additional five-year worldwide renewals, the Government is granted for itself and
others acting on its behalf a paid-up, nonexclusive, irrevocable worldwide license in this
material to reproduce, prepare derivative works, distribute copies to the public, perform
publicly and display publicly, and to permit others to do so.

NEITHER THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR LOS ALAMOS NATIONAL SECURITY, LLC,
NOR ANY OF THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL LIABILITY OR
RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY INFORMATION, APPARATUS, PRODUCT, OR
PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.

LA-CC-15-080; Copyright Number Assigned: C16008
"""
module RobustPmap

import Distributed
import Compat.String

import JLD2
import FileIO

"Check for type exceptions"
function checkexceptions(x::Any, t::Type=Any)
	for i = 1:length(x)
		if isa(x[i], Exception)
			throw(x[i])
		elseif !isa(x[i], t) # typeof(x[i]) != t
			throw(TypeError(:RobustPmap, "checkexceptions for parameter $i", t, x[i]))
		end
	end
	return nothing
end

"Robust pmap call"
function rpmap(f::Function, args...; t::Type=Any)
	x = Distributed.pmap(f, args...; on_error=x->x)
	checkexceptions(x, t)
	return convert(Array{t, 1}, x)
end

"Robust pmap call with checkpoints"
function crpmap(f::Function, checkpointfrequency::Int, filerootname::String, args...; t::Type=Any)
	fullresult = t[]
	hashargs = hash(args)
	if checkpointfrequency <= 0
		checkpointfrequency = length(args[1])
	end
	for i = 1:ceil(Int, length(args[1]) / checkpointfrequency)
		r = (1 + (i - 1) * checkpointfrequency):min(length(args[1]), (i * checkpointfrequency))
		filename = string(filerootname, "_", hashargs, "_", i, ".jld2")
		theseargs = map(x->x[r], args)
		if isfile(filename)
			partialresult = FileIO.load(filename, "partialresult")
		else
			partialresult = rpmap(f, map(x->x[r], args)...; t=t)
			FileIO.save(filename, "partialresult", partialresult)
		end
		append!(fullresult, partialresult)
	end
	return fullresult
end

end
