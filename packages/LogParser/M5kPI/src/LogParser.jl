module LogParser

###############################################################################
#
#
#	Imports and Exports
#
#
###############################################################################

export parseapachecombined, DataFrame, ApacheLog

import DataFrames: DataFrame

###############################################################################
#
#
#	Types
#
#
###############################################################################

struct ApacheLog
	ip
	rfc1413
	userid
	requesttime
	resource
	statuscode
	requestsize
	referrer
	useragent
end


###############################################################################
#
#
#	Constants
#
#
###############################################################################

#Regex for Apache Combined Log File Format:
#Format specified at http://httpd.apache.org/docs/2.4/logs.html

#Strict Mode - Works 99.9% of time on Juliabloggers and randyzwitch.com August test files
const apachecombinedregex = r"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\]) "([^"\r\n]*|[^"\r\n\[]*\[.+\][^"]+|[^"\r\n]+.[^"]+)" (\d{3}) (\d+|-) ("(?:[^"]|\")+)"? ("(?:[^"]|\")+)"?"""

#Non-strict mode: Capture as much info as possible
	const firsteightregex = r"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\]) "([^"\r\n]*|[^"\r\n\[]*\[.+\][^"]+|[^"\r\n]+.[^"]+)" (\d{3}) (\d+|-) ("(?:[^"]|\")+)"?"""
	const firstsevenregex = r"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\]) "([^"\r\n]*|[^"\r\n\[]*\[.+\][^"]+|[^"\r\n]+.[^"]+)" (\d{3}) (\d+|-)"""
	 const firstsixregex  = r"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\]) "([^"\r\n]*|[^"\r\n\[]*\[.+\][^"]+|[^"\r\n]+.[^"]+)" (\d{3})"""
	 const firstfiveregex = r"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\]) "([^"\r\n]*|[^"\r\n\[]*\[.+\][^"]+|[^"\r\n]+.[^"]+)"?"""
	 const firstfourregex = r"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\])"""
	const firstthreeregex = r"""([\d\.]+) ([\w.-]+) ([\w.-]+)"""
	  const firsttworegex = r"""([\d\.]+) ([\w.-]+)"""
	const firstfieldregex = r"""([\d\.]+)"""

###############################################################################
#
#
#	Functions
#
#
###############################################################################

function parseapachecombined(logline::AbstractString)

    regexarray = [apachecombinedregex, firstsevenregex, firstsixregex, firstfiveregex, firstfourregex, firstthreeregex, firsttworegex, firstfieldregex]

    #Declare variable defaults up front for less coding later
    ip = rfc1413 = userid = requesttime = resource = referrer = useragent = String("")
    statuscode = requestsize = Int(0)

 	for regex in regexarray

    	if (m = match(regex, logline)) != nothing

    	#Use try since we don't know how many matches actually happened
	    	try ip 			= String(m.captures[1]) catch; end
	    	try rfc1413 	= String(m.captures[2]) catch; end
	    	try userid		= String(m.captures[3]) catch; end
	    	try requesttime	= String(m.captures[4]) catch; end
	    	try resource	= String(m.captures[5]) catch; end
	    	try statuscode	= parse(Int, m.captures[6]) catch; end
	    	try requestsize	= parse(Int, m.captures[7]) catch; end
	    	try referrer	= String(m.captures[8]) catch; end
	    	try useragent	= String(m.captures[9]) catch; end

			return ApacheLog(ip, rfc1413, userid, requesttime,	resource, statuscode, requestsize, referrer, useragent)
		end

   	end #End for loop

    #If all else fails, return "nomatch" as referrer and logline as useragent field
    return ApacheLog(ip, rfc1413, userid, requesttime,	resource, statuscode, requestsize, "nomatch", logline)

end #End parseapachecombined::String

parseapachecombined(logarray::Array) = ApacheLog[parseapachecombined(x) for x in logarray]


###############################################################################
#
#
#	DataFrame parser
#
#
###############################################################################

function DataFrame(logarray::Array{ApacheLog,1})

       #fields to parse
    sym = [:ip, :rfc1413, :userid, :requesttime, :resource, :referrer, :useragent, :statuscode, :requestsize]

    #Allocate Arrays
    for value in sym[1:7]
        @eval $value = String[]
    end

    for value in sym[8:end]
        @eval $value = Int[]
    end

    #For each value in array, parse into individual arrays
    for apachelog in logarray
        for val in sym
            push!(eval(val), getfield(apachelog, val))
        end
    end

    #Append arrays into dataframe
    _df = DataFrame()

    for value in sym
    _df[value] = eval(value)
    end

    return _df

end

DataFrame(logline::ApacheLog) = DataFrame([logline])


end # module
