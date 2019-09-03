---
title: 'REDCap.jl: A Julia wrapper for the REDCap API'
tags:
  - REDCap
  - Julia
  - API Interface
authors:
 - name: Cory Cothrum
   orcid: 0000-0002-2794-1834
   affiliation: 1
affiliations:
 - name: Brown University
   index: 1
date: 22 August 2018
---

# Summary


REDCap is a medically focused database system in use by over 775,000 users worldwide. It has features for HIPAA compliance by default, longitudinal studies, and allows multiple users with different PID access rights to interface with a single database. It also features a user-friendly (and no technical experience required) web interface into a REDCap project. Part of this web interface is an extensive API system that enables most of a project's features to be manipulated through API calls, and numerous packages have been developed in other languages for this exact purpose.

Problematically, a good portion of these packages are either depreciated or limited in scope. PyCap, for instance, has been depreciated for ~2-3 years and handles a limited set of API calls. redcapAPI includes more functionality, but is much less intuitive to a user. The REDCap API includes examples of raw API calls in several languages, but none work "right out of the box" and require several alterations to the given example to function. This problem is only exacerbated by the limited availability of REDCap to a developer unaffiliated with an approved institution. The Official REDCap documentation is also focused more on the technical side of the API than the practical, with very few in-depth examples. The community is private, making communication with users versed in REDCap limited to those who aren't.

The primary purpose of REDCap.jl was to provide a Julia frontend to the REDCap API to better integrate into the workflow of the Data Science team, which used Julia extensively. Julia is a very nascent language based very heavily in both Python and Statistical Analysis, and as a result handles some things very differently then other languages. This, combined with the nuances of the REDCap API, proved to be major obstacles in development. This package is for users already familiar with these nuances in REDCap, and therefore knows how to avoid them. The individual API calls are handled by top-level functions, with many of the parameters being default values with very specific uses. REDCap itself supports json, xml, csv, and odm output, with Dataframe support added to facilitate easier sharing with other Julia programs. This package also supports easy file handling, allowing results to be imported from a file or exported to one in the appropriate format.

# Examples
Basic project creation process is as follows:
```julia
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
```
# Acknowledgements
I could not have done this without the support of Mary McGrath, Paul Stey, Fernando Gelin, and the entire Brown Data Science Team in learning both Julia and REDCap from scratch.