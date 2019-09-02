# LogParser

Linux: [![Build Status](https://travis-ci.org/randyzwitch/LogParser.jl.svg?branch=master)](https://travis-ci.org/randyzwitch/LogParser.jl) </br>
Windows: [![Build status](https://ci.appveyor.com/api/projects/status/j33i3qtdnpqwjwfk?svg=true)](https://ci.appveyor.com/project/randyzwitch/logparser-jl) </br>
Codecov: [![codecov](https://codecov.io/gh/randyzwitch/LogParser.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/randyzwitch/LogParser.jl) </br>

LogParser.jl is a package for parsing server logs. Currently, only server logs having the [Apache Combined](http://httpd.apache.org/docs/2.2/logs.html#combined) format are supported (although [Apache Common](http://httpd.apache.org/docs/2.2/logs.html#common) may parse as well). Additional types of logs may be added in the future as well.

LogParser.jl will attempt to handle the log format even if it is mangled, returning partial matches as best as possible. For example, if the end of the log entry is mangled, you may still get an IP address returned, timestamp and other parts that were able to be parsed.

## Code examples

The API for this package is straightforward:

	using LogParser

	logarray = [...] #Any AbstractArray of Strings

	#Parse file
	parsed_vals = parseapachecombined(logarray)

	#Convert to DataFrame if desired
	parsed_df = DataFrame(parsed_vals)

## Licensing

LogParser.jl is licensed under the [MIT "Expat" license](https://github.com/randyzwitch/LogParser.jl/blob/master/LICENSE.md)
