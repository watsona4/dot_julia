```@meta
CurrentModule = REDCap
```
# Examples


## Basic Usage

A basic project can be created and accessed like so:
```julia
using REDCap

#create config object for project creation
super_config = REDCap.Config("<URL>", "<S-API>")

config = create_project(super_config, "Test Project", 1; purpose_other="Testing REDCap.jl Functionality", project_notes="This is not an actual REDCap Database.")


#Importing- NOTE: Records may be incomplete. Only provided fields will be updated
record=[Dict("sex"=>"0",
	  "age"=>"56",
	  "address"=>"168 Anderson Blvd. Quincy MA 01227",
	  "height"=>"80",
	  "dob"=>"1962-04-08",
	  "record_id"=>"1",
	  "bmi"=>"125",
	  "comments"=>"Randomly Generated - Demographics",
	  "email"=>"ALin@aol.com",
	  "first_name"=>"Alexia",
	  "demographics_complete"=>"0",
	  "telephone"=>"(617) 882-6049",
	  "weight"=>"80",
	  "last_name"=>"Lin",
	  "ethnicity"=>"1",
	  "race"=>"1")]

import_records(config, record)

#create new user with basic import/export permissions
user=[Dict("username" => "john_smith@email.com",
		 "email" => "john_smith@email.com",
		 "lastname" => "Smith",
		 "api_export"=>"1",
		 "api_import"=>"1")]

import_users(config, user)

#Exporting
records = export_records(config)

#Edit project info to remove development status
final_proj_info=Dict("project_title" => "RC Production",
				  	 "in_production" => "1")
import_project_information(config, final_proj_info)

#pdf summary of the project
export_pdf(config, "/<path>/export.pdf", allRecords=true)
```


## File Handling

Records and other project information can be loaded directly from a `.csv`, `.xml`, or `.odm`. Likewise, exported information can be saved directly to a specified file.

```julia
#Exporting - file_loc must be provided as the save path
export_records(config, file_loc="<path>/records.xml", format="xml")

export_users(config, file_loc="<path>/users.csv", format="csv")

#Importing - data passed as a file-path is loaded directly into the API
import_records(config, "<path>/records.xml", format="xml") #NOTE: The format must match the file format you are uploading

import_users(config, "<path>/users.csv", format="csv")
```