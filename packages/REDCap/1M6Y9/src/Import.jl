"""
	import_project_information(config::REDCap.Config, data; format::String="json")

Update basic attributes of given REDCap project.
NOTE: Only for projects in development

#### Parameters:
* `config` - Struct containing url and api-key
* `data` - Data to be imported - pass as a file location to import from disk
* `format` - "json", "xml", "csv", or "odm". declares format of imported data

#### Returns:
Number of successfully imported values
"""
function import_project_information(config::REDCap.Config, data; format::String="json", returnFormat::String="json")
	return api_pusher("import", "project_settings", config, data = import_file_checker(data, format), format=format, returnFormat=returnFormat)
end


"""
	import_metadata(config::REDCap.Config, data; format::String="json", returnFormat::String="json")

Import metadata (i.e., Data Dictionary) into a project.
NOTE: Only for projects in development

#### Parameters:
* `config` - Struct containing url and api-key
* `data` - Data to be imported - pass as a file location to import from disk
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `returnFormat` - Error message format

#### Returns:
Number of successfully imported fields
"""
###BROKEN(?)###
function import_metadata(config::REDCap.Config, data; format::String="json", returnFormat::String="json")
	return api_pusher("import", "metadata", config, data = import_file_checker(data, format), format=format, returnFormat=returnFormat)
end
#=
Breaks on JSON, XML, 
Works for CSV

newmeta = Dict("required_field"=>"",
  "section_header"=>"",
  "matrix_ranking"=>"",
  "select_choices_or_calculations"=>"",
  "field_type"=>"file",
  "field_note"=>"",
  "form_name"=>"demographics",
  "matrix_group_name"=>"",
  "field_label"=>"File Upload",
  "custom_alignment"=>"",
  "question_number"=>"",
  "text_validation_max"=>"",
  "text_validation_type_or_show_slider_number"=>"",
  "branching_logic"=>"",
  "field_annotation"=>"",
  "identifier"=>"",
  "text_validation_min"=>"",
  "field_name"=>"file_upload")

push!(meta, newmeta)

ERROR: HTTP.ExceptionRequest.StatusError(400, HTTP.Messages.Response:
"""
HTTP/1.1 400 Bad Request
Date: Wed, 25 Jul 2018 18:12:00 GMT
Server: Apache/2.4.6 (Red Hat Enterprise Linux)
X-Powered-By: PHP/5.4.16
Expires: 0
cache-control: no-store, no-cache, must-revalidate
Pragma: no-cache
Access-Control-Allow-Origin: *
REDCap-Random-Text: VxGV9VFPeaU9yzkMsFXFKUQuhMYCygnBXEgejwoi2wXnX
Content-Length: 343
Connection: close
Content-Type: application/json; charset=utf-8

{"error":"Each row MUST have a variable\/field name, but the following cells have a field name missing: A2.\nEach row MUST have a form name, but the following cells have a form name missing: B2.\nA field validation type is required in order to have a minimum or maximum validation value. The following cells are missing a validation type: I2"}""")
=#

"""
	import_users(config::REDCap.Config, data; format::String="json", returnFormat::String="json")

Update/import new users into a project.

#### Parameters:
* `config` - Struct containing url and api-key
* `data` - Data to be imported - pass as a file location to import from disk
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `returnFormat` - Error message format

#### Returns:
Number of succesfully added/modified users.
"""
###BROKEN###
function import_users(config::REDCap.Config, data; format::String="json", returnFormat::String="json")
	return api_pusher("import", "user", config, data = import_file_checker(data, format), format=format, returnFormat=returnFormat)
end

#=
No longer modifies users! Can add them wholesale, not modify them after???

=#


"""
	import_arms(config::REDCap.Config, data; override::Int=0, format::String="json", returnFormat::String="json")

Update/import Arms into a project.

#### Parameters:
* `config` - Struct containing url and api-key
* `data` - Data to be imported - pass as a file location to import from disk
* `override` - 0 (false) 1 (true) - overwrites existing arms
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `returnFormat` - Error message format

#### Returns:
Number of successfully imported arms
"""
###BROKEN###
function import_arms(config::REDCap.Config, data; override::Int=0, format::String="json", returnFormat::String="json")
	return api_pusher("import", "arm", config, data = import_file_checker(data, format), override=override, format=format, returnFormat=returnFormat)
end

#=
julia> arms = export_arms(config)
POSTing
POSTd
1-element Array{Any,1}:
 Dict{String,Any}(Pair{String,Any}("name", "Arm 1"),Pair{String,Any}("arm_num", 1))

julia> newarm
Dict{String,Any} with 2 entries:
  "name"    => "Arm 1"
  "arm_num" => 1

julia> push!(arms, newarm)
2-element Array{Any,1}:
 Dict{String,Any}(Pair{String,Any}("name", "Arm 1"),Pair{String,Any}("arm_num", "1"))
 Dict{String,Any}(Pair{String,Any}("name", "Arm 2"),Pair{String,Any}("arm_num", "2"))

julia> import_arms(config, arms)
POSTing
POSTd
2	<- this should indicate 2 arms added.

julia> export_arms(config)
POSTing
POSTd
1-element Array{Any,1}:
 Dict{String,Any}(Pair{String,Any}("name", "Arm 1"),Pair{String,Any}("arm_num", 1))

=#

"""
	import_events(config::REDCap.Config, data; override::Int=0, format::String="json", returnFormat::String="json")

Update/import Events into a project.

#### Parameters:
* `config` - Struct containing url and api-key
* `data` - Data to be imported - pass as a file location to import from disk
* `override` - 0 (false) 1 (true) - overwrites existing events
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `returnFormat` - Error message format

#### Returns:
Number of successfully imported events
"""
function import_events(config::REDCap.Config, data; override::Int=0, format::String="json", returnFormat::String="json")
	return api_pusher("import", "event", config, data = import_file_checker(data, format), override=override, format=format, returnFormat=returnFormat)
end


"""
	import_records(config::REDCap.Config, data::Any; format::String="json", dtype::String="flat", overwriteBehavior::String="normal", forceAutoNumber::Bool=false, dateFormat::String="YMD", returnContent::String="count", returnFormat::String="json")

Import a set of records for a project.

#### Parameters:
* `config` - Struct containing url and api-key
* `recordData` - Array of record data to be imported - pass as a file location to import from disk
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `dtype` - "flat" (one record per row) or "eav" (one data point per row)
* `overwriteBehavior` - "normal" - will not overwrite, "overwrite" - will
* `forceAutoNumber` - Force auto-numbering and overwrite given id number
* `dateFormat` - "YMD", "MDY", or "DMY"
* `returnContent` - "count" (number of successfully uploaded records), 
						"ids" (list of record numbers imported), 
						"auto-ids" (pair of assigned id and given id)
* `returnFormat` - Error message format

#### Returns:
Specified by returnContent
"""
function import_records(config::REDCap.Config, data; format::String="json", dtype::String="flat", overwriteBehavior::String="normal", forceAutoNumber::Bool=false, dateFormat::String="YMD", returnContent::String="count", returnFormat::String="json")
	return api_pusher("import", "record", config, data = import_file_checker(data, format), format=format, dtype=dtype, overwriteBehavior=overwriteBehavior, forceAutoNumber=forceAutoNumber, dateFormat=dateFormat, returnContent=returnContent, returnFormat=returnFormat)
end


"""
	import_instrument_event_mappings(config::REDCap.Config, data; format::String="json", returnFormat::String="json")

Import Instrument-Event Mappings into a project 

#### NOTE: This only works for longitudinal projects.

#### Parameters:
* `config` - Struct containing url and api-key
* `data` - Data to be imported - pass as a file location to import from disk
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `returnFormat` - Error message format

#### Returns:
Number of successfully imported inst-event mappings
"""
###BROKEN(?)###
function import_instrument_event_mappings(config::REDCap.Config, data; format::String="json", returnFormat::String="json")
	return api_pusher("import", "formEventMapping", config, data = import_file_checker(data, format), format=format, returnFormat=returnFormat)
end


"""
	import_file(config::REDCap.Config, record::String, field::String, event::String, file::String; repeat_instance::Int=1, returnFormat::String="json")

Upload a document to specific record to the designated uploading field.

#### Parameters:
* `config` - Struct containing url and api-key
* `record` - Destination record id
* `field` - Destination file upload field
* `event` - Destination event
* `repeat_instance` - Number of repeated instances (long project)
* `file` - File to be imported
* `returnFormat` - Error message format

#### Returns:
Nothing/errors
"""
###BROKEN###
function import_file(config::REDCap.Config, record::String, field::String, event::String, file::String; repeat_instance::Int=1, returnFormat::String="json")
	return api_pusher("import", "file", config, record=record, field=field, event=event, file=open(file), repeat_instance=repeat_instance, returnFormat=returnFormat)
end
#=
No longer properly passes files- REDCap returns an error of invalid file.
=#


"""
	create_project(config::REDCap.Config, project_title::String, purpose::Integer; format::String="json", returnFormat::String="json", odm="", purpose_other::String="", project_notes::String="", is_longitudinal::Integer=0, surveys_enabled::Integer=0, record_autonumbering_enabled::Integer=1)

Creates a project with the given parameters

#### Parameters:
* `config` - Struct containing url and super-api-key
* `format` - "json", "xml", "csv", or "odm". declares format of imported data
* `data` - Attributes of project to create- only project_title and purpose are required (* for default)
	* `project_title`: Title
	* `purpose`: Must be numerical (0 - test, 1 - other, 2 - research, 3 - Qual+, 4 - OpSupport)
	* `purpose_other`: If purpose == 1, string of purpose
	* `project_notes`: Notes
	* `is_longitudinal`: 0 - false*, 1 - true
	* `surveys_enabled`: 0 - false*, 1 - true
	* `record_autonumbering_enabled`: 0 - false, 1 - true*
* `returnFormat` - Error message format
* `odm` - XML string containing metadata

#### Returns:
The standard config for that project.
"""
function create_project(config::REDCap.Config, project_title::String, purpose::Integer; format::String="json", returnFormat::String="json", odm="", purpose_other::String="", project_notes::String="", is_longitudinal::Integer=0, surveys_enabled::Integer=0, record_autonumbering_enabled::Integer=1)
	if length(config.key)==64
		data = json_formatter([Dict{String, Any}("project_title" => project_title,
													"purpose" => purpose,
													"purpose_other" => purpose_other,
													"project_notes" => project_notes,
													"is_longitudinal" => is_longitudinal,
													"surveys_enabled" => surveys_enabled,
													"record_autonumbering_enabled" => record_autonumbering_enabled)], "import")
		#Send through api_pusher NOT poster
		response = api_pusher("import", "project", config, format=format, data=data, returnFormat=returnFormat, odm=odm)
		return Config(config.url, response; ssl=config.ssl) #inherit all settings except the newly generated key
	else
		@error("Please use a config object that contains a properly entered Super API key.\n$(config.key) is an invalid Super-API key.")
	end
end