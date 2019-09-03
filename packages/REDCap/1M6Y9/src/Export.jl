"""
	export_field_names(config::REDCap.Config; field::String="", format::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `field` - Specifies the field to export
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `file_loc` - Location to export to

#### Returns:
Formatted dict of export/import-specific version of field names 
for all fields (or for one field, if desired) in project: 
'original_field_name', 'choice_value', and 'export_field_name'
"""
function export_field_names(config::REDCap.Config; field::String="", format::String="json", file_loc::String="")
	return api_pusher("export", "exportFieldNames", config, field=field, format=format, file_loc=file_loc)
end


"""
	export_instruments(config::REDCap.Config; format::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `file_loc` - Location to export to

#### Returns:
Formatted dict for data collection instruments of project.
"""
function export_instruments(config::REDCap.Config; format::String="json", file_loc::String="")
	return api_pusher("export", "instrument", config, format=format, file_loc=file_loc)
end


"""
	export_metadata(config::REDCap.Config; fields::Array=[], forms::Array=[], format::String="json", returnFormat::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `fields` - Array of field names to pull data from
* `forms` - Array of form names to pull data from
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Formatted dict of the metadata for project.
"""
function export_metadata(config::REDCap.Config; fields::Array=[], forms::Array=[], format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "metadata", config, fields=fields, forms=forms, format=format, returnFormat=returnFormat, file_loc=file_loc)
end


"""
	export_project_information(config::REDCap.Config; format::String="json", returnFormat::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Formatted dict of the basic attributes of given REDCap project.
"""
function export_project_information(config::REDCap.Config; format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "project", config, format=format, returnFormat=returnFormat, file_loc=file_loc)
end


"""
	export_users(config::REDCap.Config; format::String="json", returnFormat::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Array of formatted dicts of users for project.
"""
function export_users(config::REDCap.Config; format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "user", config, format=format, returnFormat=returnFormat, file_loc=file_loc)
end


"""
	export_version(config::REDCap.Config; format::String="json") 

Returns a string of the current REDCap version.

#### Parameters:
* `config` - Struct containing url and api-key
* `format` - "json", "xml", "csv", or "odm". decides format of returned data

#### Returns:
The version number (eg 1.0.0) as a string
"""
function export_version(config::REDCap.Config; format::String="text")
	return api_pusher("export", "version", config, format=format)
end


"""
	export_arms(config::REDCap.Config; arms::Array=[], format::String="json", returnFormat::String="json", file_loc::String="") 

Returns a dict of all arms used in the project.

#### NOTE: This only works for longitudinal projects.

#### Parameters:
* `config` - Struct containing url and api-key
* `arms` - Array of arm names to export
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Formatted dict of Arms for project.
"""
function export_arms(config::REDCap.Config; arms::Array=[], format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "arm", config, format=format, returnFormat=returnFormat, arms=arms, file_loc=file_loc)
end


"""
	export_events(config::REDCap.Config; arms::Array=[], format::String="json", returnFormat::String="json", file_loc::String="") 

#### NOTE: This only works for longitudinal projects.

#### Parameters:
* `config` - Struct containing url and api-key
* `arms` - Array of arm names to export
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Formatted dict of events for project.
"""
function export_events(config::REDCap.Config; arms::Array=[], format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "event", config, format=format, returnFormat=returnFormat, arms=arms, file_loc=file_loc)
end


"""
	export_pdf(config::REDCap.Config, file_loc::String; record::String="", event::String="", instrument::String="", allRecords::Bool=false) 

Exports a PDF for a selected portion of the project.

#### Parameters:
* `config` - Struct containing url and api-key
* `record` - Record ID to populate PDF
* `event` - Event name to populate PDF
* `instrument` - Name of instrument to populate PDF
* `allRecords` - Flag to take all records or not - if passed, the other specifying fields will be ignored
* `file_loc` - Location to export to

#### Returns:
PDF file for: 
* 1) single data collection instrument (blank),
* 2) all instruments (blank), 
* 3) single instrument (with data from a single record),
* 4) all instruments (with data from a single record), 
* 5) all instruments (with data from ALL records)
"""
function export_pdf(config::REDCap.Config, file_loc::String; record::String="", event::String="", instrument::String="", allRecords::Bool=false)
	if allRecords==true 					#REDCap handles request differently based which fields passed
		output = api_pusher("export", "pdf", config, file_loc=file_loc, allRecords=allRecords)
	else
		output = api_pusher("export", "pdf", config, file_loc=file_loc, record=record, event=event, instrument=instrument)
	end
end


"""
	export_project(config::REDCap.Config; returnMetadataOnly::Bool=false, records::Array=[], fields::Array=[], events::Array=[], format::String="xml", returnFormat::String="json", exportSurveyFields::Bool=false, exportDataAccessGroups::Bool=false, filterLogic::String="", exportFiles::Bool=false, file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `returnMetadataOnly` - Flag to return metedata or not
* `records` - Array of record names to include
* `fields` - Array of field names to include
* `events` - Array of event names to include
* `returnFormat` - Error message format
* `exportSurveyFields` - Flag to return survey fields or not
* `exportDataAccessGroups` - Flag to return DAGroups or not
* `filterLogic` - Allows collection of records that fulfill a criteria eg. "[age] > 65"
* `exportFiles` - Flag to include files or not
* `file_loc` - Location to export to

#### Returns:
Entire project as XML.
"""
function export_project(config::REDCap.Config; returnMetadataOnly::Bool=false, records::Array=[], fields::Array=[], events::Array=[], format::String="xml", returnFormat::String="json", exportSurveyFields::Bool=false, exportDataAccessGroups::Bool=false, filterLogic::String="", exportFiles::Bool=false, file_loc::String="")
	output = api_pusher("export", "project_xml", config, returnMetadataOnly=returnMetadataOnly, records=records, fields=fields, events=events, format=format, returnFormat=returnFormat, exportSurveyFields=exportSurveyFields, exportDataAccessGroups=exportDataAccessGroups, filterLogic=filterLogic, exportFiles=exportFiles, file_loc=file_loc)
	if length(file_loc)>0
		return "Success"
	else
		return xml_formatter(output, "export")
	end
end


"""
	export_records(config::REDCap.Config; format::String="json", dtype::String="flat", records::Array=[], fields::Array=[], forms::Array=[], events::Array=[], rawOrLabel::String="raw", rawOrLabelHeaders::String="raw", exportCheckboxLabel::Bool=false, returnFormat::String="json", exportSurveyFields::Bool=false, exportDataAccessGroups::Bool=false, filterLogic::String="", file_loc::String="")

#### Parameters:
* `config` - Struct containing url and api-key
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `dtype` - Output mode: "flat" (output one record per row) or "eav" (one data point per row)
* `records` - Array of record names to include
* `fields` - Array of field names to include
* `forms` - Array of form names to include
* `events` - Array of event names to include
* `rawOrLabel` - "raw" or "label" - export raw coded values or labels for multiple choice fields
* `rawOrLabelHeaders` - Same as above, for headers
* `exportCheckboxLabel` - Checkbox behavior: export checkboxes as "checked/unchecked" or as "field-name/'blank'"
* `returnFormat` - Error message format
* `exportSurveyFields` - Flag to return survey fields or not
* `exportDataAccessGroups` - Flag to return DAGroups or not
* `filterLogic` - Allows collection of records that fulfill a criteria eg. "[age] > 65"
* `file_loc` - Location to export to

#### Returns:
An array of Dictionaries containing record information
"""
function export_records(config::REDCap.Config; format::String="json", dtype::String="flat", records::Array=[], fields::Array=[], forms::Array=[], events::Array=[], rawOrLabel::String="raw", rawOrLabelHeaders::String="raw", exportCheckboxLabel::Bool=false, returnFormat::String="json", exportSurveyFields::Bool=false, exportDataAccessGroups::Bool=false, filterLogic::String="", file_loc::String="")
	return api_pusher("export", "record", config, format=format, dtype=dtype, records=records, fields=fields, forms=forms, events=events, rawOrLabel=rawOrLabel, rawOrLabelHeaders=rawOrLabelHeaders, exportCheckboxLabel=exportCheckboxLabel, exportSurveyFields=exportSurveyFields, exportDataAccessGroups=exportDataAccessGroups, filterLogic=filterLogic, returnFormat=returnFormat, file_loc=file_loc)
end



"""
	export_survey_queue_link(config::REDCap.Config, record::String; returnFormat::String="json") 

#### Parameters:
* `config` - Struct containing url and api-key
* `record` - Record id for link
* `returnFormat` - Error message format

#### Returns:
Unique Survey Queue link.
"""
function export_survey_queue_link(config::REDCap.Config, record::String; format::String="text", returnFormat::String="json")
	return api_pusher("export", "surveyQueueLink", config, record=record, format=format, returnFormat=returnFormat)
end


"""
	export_survey_return_code(config::REDCap.Config, record::String, instrument::String, event::String; repeat_instance::Integer=1, returnFormat::String="json") 

#### Parameters:
* `config` - Struct containing url and api-key
* `record` - Record id for link
* `instrument` - Name of instrument to export code for
* `event` - event Name conatining instrument
* `repeat_instance` - Number of repeated instances (long project)
* `returnFormat` - Error message format

#### Returns:
Unique Return Code in plain text format.
"""
function export_survey_return_code(config::REDCap.Config, record::String, instrument::String, event::String; format::String="text", repeat_instance::Integer=1, returnFormat::String="json")
	return api_pusher("export", "surveyReturnCode", config, record=record, instrument=instrument, event=event, 
							repeat_instance=repeat_instance, format=format, returnFormat=returnFormat)
end


"""
	export_instrument_event_mappings(config::REDCap.Config, arms::Array=[]; format::String="json", returnFormat::String="json", file_loc::String="") 

#### NOTE: This only works for longitudinal projects.

#### Parameters:
* `config` - Struct containing url and api-key
* `arms` - Array of arm names to export
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Formatted dict of instrument-event mappings for project.
"""
function export_instrument_event_mappings(config::REDCap.Config, arms::Array=[]; format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "formEventMapping", config, arms=arms, format=format, returnFormat=returnFormat, file_loc=file_loc)
end


"""
	export_survey_participant_list(config::REDCap.Config, instrument::String, event::String; format::String="json", returnFormat::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `instrument` - Name of instrument to export list of participants
* `event` - Event name conatining instrument
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
Formatted dict of all participants for specific survey instrument.
"""
function export_survey_participant_list(config::REDCap.Config, instrument::String, event::String; format::String="json", returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "participantList", config, event=event, instrument=instrument, format=format, returnFormat=returnFormat, file_loc=file_loc)
end


"""
	export_file(config::REDCap.Config, record::String, field::String, event::String; repeat_instance::Integer=1, returnFormat::String="json", file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `record` - Record id containing file
* `field` - Field containing file
* `event` - Event containing file
* `repeat_instance` - Number of repeated instances (long. project)
* `returnFormat` - Error message format
* `file_loc` - Location to export to

#### Returns:
File attached to individual record.
"""
function export_file(config::REDCap.Config, record::String, field::String, event::String; repeat_instance::Integer=1, returnFormat::String="json", file_loc::String="")
	return api_pusher("export", "file", config, event=event, record=record, field=field, repeat_instance=repeat_instance, returnFormat=returnFormat, file_loc=file_loc)
end


"""
	export_report(config::REDCap.Config, report_id::Integer; format::String="json", returnFormat::String="json", rawOrLabel::String="raw", rawOrLabelHeaders::String="raw", exportCheckboxLabel::Bool=false, file_loc::String="") 

#### Parameters:
* `config` - Struct containing url and api-key
* `report_id` - Id of report to export
* `format` - "json", "xml", "csv", or "odm". decides format of returned data
* `returnFormat` - Error message format
* `rawOrLabel` - "raw" or "label" - export raw coded values or labels for multiple choice fields
* `rawOrLabelHeaders` - Same as above, for headers
* `exportCheckboxLabel` - Checkbox behavior: export checkboxes as "checked/unchecked" or as "field-name/'blank'"
* `file_loc` - Location to export to

#### Returns:
Formatted dict of report.
"""
function export_report(config::REDCap.Config, report_id; format::String="json", returnFormat::String="json", rawOrLabel::String="raw", rawOrLabelHeaders::String="raw", exportCheckboxLabel::Bool=false, file_loc::String="")
	return api_pusher("export", "report", config, report_id=report_id, rawOrLabel=rawOrLabel, rawOrLabelHeaders=rawOrLabelHeaders, 
							exportCheckboxLabel=exportCheckboxLabel, format=format, returnFormat=returnFormat, file_loc=file_loc)
end


""" 
	export_survey_link(config::REDCap.Config, record::String, instrument::String, event::String; repeat_instance::Int=1, returnFormat::String="json") 

#### Parameters:
* `config` - Struct containing url and api-key
* `record` - Record id
* `instrument` - Name of instrument linking to
* `event` - Event name containing instrument
* `repeat_instance` - Number of repeated instances (long project)
* `returnFormat` - Error message format

#### Returns:
Unique survey link.
"""
function export_survey_link(config::REDCap.Config, record::String, instrument::String, event::String; format::String="text", repeat_instance::Int=1, returnFormat::String="json")
	return api_pusher("export", "surveyLink", config, record=record, instrument=instrument, event=event, 
							format=format, repeat_instance=repeat_instance, returnFormat=returnFormat)
end