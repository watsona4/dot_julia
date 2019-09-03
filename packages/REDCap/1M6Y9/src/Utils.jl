"""
	api_pusher(mode::String, content::String, config::Config; format::String="", returnFormat::String="", file_loc::String="", kwargs...)

Pass the type of api call, the config struct, and any needed kwargs for that api call.
Handles creation of the Dict of fields to pass to REDCap, and file IO/formatting. 

API documentation found here:
https://<your-redcap-site.com>/redcap/api/help/

#### Parameters:
* `mode` - "import", "export", or "delete"
* `content` - Passed by calling modules to indicate what data to access
* `config` - Struct containing url and api-key
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location of file
* `kwargs...` - Any addtl. arguments passed by the calling module

#### Returns:
Formatted response body
"""
function api_pusher(mode::String, content::String, config::Config; format::String="", returnFormat::String="", file_loc::String="", kwargs...)
	#initialize dict with basic info and api calls
	fields = Dict{String, Any}("token" => config.key,
					"action" => mode,						#import, export, delete
					"content" => content,					#API call to access
					"returnFormat" => returnFormat)

	if format=="df"
		if mode=="import"
			fields["format"] = "json" 						#REDCap doesnt know what df is
		elseif mode=="export"
			fields["format"] = "csv"						#Julia can parse csv as a df
		end
	else
		fields["format"] = format
	end

	for (k,v) in kwargs
		k=String(k) 										#k is a Symbol, make easier to handle
		if mode=="import" && isequal(k, "data")				#Turn all imported data into an IOBuffer so HTTP won't mess with it OR turn filterLogic data into a buffer because it uses []'s and REDCap can't understand URI encoding
			fields[k]=IOBuffer(v)
		elseif isa(v, Array)								#Turn arrays into specially URI encoded arrays
			for (i, item) in enumerate(v)
			    fields["$k[$(i-1)]"]=String(item)
			end
		elseif isequal(k, "filterLogic") && v != ""
			fields[k]=IOBuffer(v)
		else
			fields[k]=string(v)
		end
	end

	#POST request and get response
	response = poster(config, fields)

	#check if user wanted to save the file here
	if mode=="export"
		if length(file_loc)>0
			export_to_file(file_loc, response)
		else
			return formatter(response, format, mode)
		end
	elseif mode=="import" || mode=="delete"
		return formatter(response, returnFormat, "export")
	end
end


"""
	poster(config::Config, body)

Handles the POST duties for all modules. Also does basic Status checking and SSL verification.

#### Parameters:
* `config` - Struct containing url and api-key
* `body` - Request body data

#### Returns:
The response body.
"""
function poster(config::Config, body)
	println("POSTing")

	response = HTTP.post(config.url; body=body, require_ssl_verification=config.ssl)#, verbose=3)

	println("POSTd")
	if response.status != 200
		#Error - handle errors way more robustly- check for "error" field? here or back at api_pusher?
		#an error is an error is an error, so it throws no matter what, on REDCaps end
		println(response.status)
	else
		return String(response.body)
	end
end


"""
	generate_next_record_id(config::Config) 

#### Parameters:
* `config` - Struct containing url and api-key

#### Returns:
The next available ID number for project (Max record number +1)
"""
function generate_next_record_id(config::Config)
	fields = Dict("token" => config.key, 
				  "content" => "generateNextRecordName")
	return parse(Int64, poster(config, fields)) 		#return as integer
end


"""
	formatter(data, format, mode::String)

Takes data and sends out to the proper formating function.

#### Parameters:
* `data` - The data to be formatted
* `format` - The target format
* `mode` - Formatting for Import (data to server) or Export (data from server)

#### Returns:
The specified formatted/unformatted object
"""
function formatter(data, format, mode::String)
	if format=="json"
		return json_formatter(data, mode)
	elseif format=="csv"
		return data 						#very little needs to be done, but still keep as a sep. case
	elseif format=="xml"
		return xml_formatter(data, mode)
	elseif format=="odm"
		return odm_formatter(data, mode)
	elseif format=="df"
		return df_formatter(data, mode)
	elseif format=="text"
		return data 						#Internal format
	else
		@error("$format is an invalid format.\nValid formats: \"json\", \"csv\", \"xml\", \"odm\", or \"df\"")
	end
end


"""
	json_formatter(data, mode::String)

#### Parameters:
* `data` - The data to be formatted
* `mode` - Formatting for Import (data to server) or Export (data from server)

#### Returns:
Either a JSON'ed object or a parsed Dict
"""
function json_formatter(data, mode::String)
	if mode=="import"
		return JSON.json(data)
	else
		try
			return JSON.parse(data) 
		catch
			@warn("Data cannot be json formatted")
			return data 					#for things that arent dicts - a surprising amount of REDCap's output
		end
	end
end


"""
	xml_formatter(data, mode::String)

#### Parameters:
* `data` - The data to be formatted
* `mode` - Formatting for Import (data to server) or Export (data from server)

#### Returns:
Either an xml-formatted string, or an xml document
"""
function xml_formatter(data, mode::String)
	if mode=="import"
		return string(data)
	else
		return parse_string(string(data))
	end
end


"""
	odm_formatter(data, mode::String)

May just be XML in disguise - really weird format - Currently treated as just xml, but probably shouldnt be

#### Parameters:
* `data` - The data to be formatted
* `mode` - Formatting for Import (data to server) or Export (data from server)

#### Returns:
Either an xml-formatted string, or an xml document
"""
###BROKEN(?)###
function odm_formatter(data, mode::String)
	if mode=="import"
		return string(data)
	else
		try
			return parse_string(data)
		catch
			@warn("Data cannot be odm formatted")
			return data
		end
	end
end
#=
There is such sparse documentation on odm and Julia, and its so low priority- just use xml.
=#


"""
	df_formatter(data, mode::String)

#### Parameters:
* `data` - The data to be formatted
* `mode` - Formatting for Import (data to server) or Export (data from server)

#### Returns:
Either an JSON'ed dict, or a df
"""
function df_formatter(data, mode::String)
	if mode=="import"						#must turn df into a json'ed dict
		return json_formatter(df_parser(data), mode)
	else
		try
			return CSV.read(IOBuffer(data))
		catch
			@warn("Data cannot be df formatted")
			return data
		end
	end
end


"""
	df_parser(data::Union{DataFrame, Dict})

Takes a DF, turns it into a Dict
When a DF is passed, every row is turned into a dict() with the columns as keys, and pushed into an array to pass as a JSON object.

#### Parameters:
* `data` - Data to be formatted

#### Returns:
A JSON ready dictionary array.
"""
function df_parser(data::DataFrame)
	#df => dict
	chartDict=[]
	for row in DataFrames.eachrow(data)
		rowDict=Dict()
		for item in row
			if ismissing(item[2])
				rowDict[String(item[1])]="" #force things to be blanks
			else
				rowDict[String(item[1])]=string(item[2])
			end
		end
		push!(chartDict,rowDict)
	end
	return chartDict
end


"""
	import_from_file(file_loc::String, format::String)

Called by importing functions to load already formatted data directly from a designated file

#### Parameters:
* `file_loc` - Location of file
* `format` - The target format

#### Returns:
The formatted data
"""
function import_from_file(file_loc::String, format::String)
	valid_formats = ("json", "csv", "xml", "df", "odm") #redcap accepted formats (also df)
	try
		open(file_loc) do file
			if format ∈ valid_formats
				return String(read(file))
			else
				@error("$format is an invalid format.\nValid formats: \"json\", \"csv\", \"xml\", \"odm\", or \"df\"")
			end
		end
	catch
		@error("File could not be opened:\n$file_loc")
	end
end


"""
	import_file_checker()

Checks if the passed data is a valid path to a file, or data in itself. 
If a path, calls a loading function; if data, calls a formatter.

#### Parametes:
* `data` - The data to check
* `format` - The format to pass along

#### Returns:
The retreived/formatted data
"""
function import_file_checker(data, format::String)
	if isa(data, String) && length(data)<143 && ispath(data) #143 characters seems to be the hard limit for ispath(); longer and it returns an ERROR: stat: name too long (ENAMETOOLONG)
		try
			return import_from_file(data, format)
		catch
			@error("File could not be opened:\n$data")
		end
	else
		return formatter(data, format, "import")
	end
	
end


"""
	export_to_file(fileLoc::String, format::String, data)

Called by exporting functions to dump data into designated file, or yell at you for a bad path.

#### Parameters:
* `file_loc` - Location of file - pass with proper extensions
* `data` - The data to save to file

#### Returns:
Nothing/error
"""
function export_to_file(file_loc::String, data)
	try
		open(file_loc, "w") do file
			write(file, data)
			return "Success"
		end
	catch
		@error("File could not be opened:\n$file_loc")
	end
end