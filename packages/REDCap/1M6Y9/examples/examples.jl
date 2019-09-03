# A basic project can be created and accessed like so:

using REDCap

# Create the config object for project creation
super_config = REDCap.Config("<URL>", "<S-API>")

# `create_project()` returns the new projects config object, ready to use.
config = create_project(super_config, "Test Project", 1; purpose_other="Testing REDCap.jl Functionality", project_notes="This is not an actual REDCap Database.")

# ### Importing- NOTE: Records may be incomplete. Only provided fields will be updated
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

# Create new user with basic import/export permissions
user=[Dict("username" => "john_smith@email.com",
         "email" => "john_smith@email.com",
         "lastname" => "Smith",
         "api_export"=>"1",
         "api_import"=>"1")]

import_users(config, user)

# ### Exporting
records = export_records(config)

# `.pdf` summary of the project
export_pdf(config, "/<path>/export.pdf", allRecords=true)