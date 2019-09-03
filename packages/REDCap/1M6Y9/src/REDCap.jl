"""
	REDCap

Legacy Julia 0.6 frontend for the REDCap API. Handles all available API calls from REDCap through top-level functions.
Must have a valid `REDCap.Config` object set up with the API key and url. 
Compatable with REDCap Version 8.1.0
"""
module REDCap

using HTTP
using JSON
using LightXML
using CSV
using DataStructures
using DataFrames

include("Config.jl")
include("Utils.jl")
include("Export.jl")
include("Import.jl")
include("Delete.jl")

export export_field_names,
		export_instruments,
		export_metadata,
		export_project_information,
		export_users,
		export_version,
		export_arms,
		export_events,
		export_pdf,
		export_project,
		export_records,
		export_survey_queue_link,
		export_survey_return_code,
		export_instrument_event_mappings,
		export_survey_participant_list,
		export_file,
		export_report,
		export_survey_link,
		generate_next_record_id,

		import_project_information,
		import_metadata,
		import_users,
		import_arms,
		import_events,
		import_records,
		import_instrument_event_mappings,
		import_file,

		delete_arms,
		delete_events,
		delete_file,
		delete_records,

		create_project

end