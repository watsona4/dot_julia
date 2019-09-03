[![Build Status](https://travis-ci.org/GregorMatheis/SalesForceBulkApi.jl.svg?branch=master)](https://travis-ci.org/GregorMatheis/SalesForceBulkApi.jl)
[![Coverage Status](https://coveralls.io/repos/github/GregorMatheis/SalesForceBulkApi.jl/badge.svg?branch=master)](https://coveralls.io/github/GregorMatheis/SalesForceBulkApi.jl?branch=master)

# SalesForceBulkApi.jl
Functions to query data with the sales force bulk api

Install:

```julia
import Pkg
Pkg.add("SalesForceBulkApi")
using SalesForceBulkApi
```

Usage:

Query data
```julia
session = login("youremail@adress.com/Login", "Your Password", "Your API Version (e.g. 45.0)")
sf_bulkapi_query(session, "Select Name FROM account limit 100")
```

Get overview of all objects and fields per object:

```julia
session = login("youremail@adress.com/Login", "Your Password", "Your API Version (e.g. 45.0)")

object_list(session) # List of all available objects
fields_description(session, "object name") # Gives all fields 
all_object_fields(session) # Handy iterator that creates a complete dataframe with all objects and fields. Runs a couple of seconds
```
Query deleted data:
```julia
sf_bulkapi_query(session, "Select Name, IsDeleted From Account", true) 
```

Running multiple queries at once
```julia
queries = ["Select Name From Account", "Select LastName From Contact"]
multi_result = multiquery(session, queries) #normal query
multi_result_all = multiquery(session, queries, true) #includes deleted objects
```
If multiple workers are available, queries get distributed across workers. Otherwise queries run async in one worker.
