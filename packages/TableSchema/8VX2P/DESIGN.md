# Frictionless Data Julia Libraries - Design Document

Oleg Lavrovsky ~ [@loleg](https://github.com/loleg)
Last updated: *November 20, 2017*

## Overview

[Frictionless Data](http://frictionlessdata.io/) is a set of lightweight specifications, libraries and software improving the ways to get, share, and validate data.

This design document focuses on functional specification and design of two code libraries written in [Julia](https://julialang.org/): "Table Schema" and "Data Package". The design follows the general design prbinciples described at [specs.frictionlessdata.io](https://specs.frictionlessdata.io) and the V1 announcement ([blog.okfn.org](https://blog.okfn.org/2017/09/05/frictionless-data-v1-0/), [hackmd.io](https://hackmd.io/KwUzE5wIwRgWgGYENzDgFmAgzHKA2fJOABmHwGMATEmK8GIoA===)).

## Functional Specification

Each library needs to implement a set of core “actions” that are further described in the implementation [documentation](https://github.com/frictionlessdata/implementations#tableschema). For simplicity, these core actions are reproduced here, along with links to the corresponding unit test cases:

**Table Schema**

- read and validate a table schema descriptor [schema.jl](test/schema.jl#L27)
- create/edit a table schema descriptor [schema.jl](test/schema.jl#L27)
- provide a model-type interface to interact with a descriptor [schema.jl](test/schema.jl#L27)
- infer a Table Schema descriptor from a supplied sample of data [infer.jl](test/infer.jl#L14)
- validate a data source against the Table Schema descriptor [validate.jl](test/validate.jl#L3)
- validate in response to editing the descriptor [changes.jl](test/changes.jl#L18)
- enable streaming and reading of a data source through a Table Schema [read.jl](test/read.jl#L7)
- reading of a data source with cast on iteration [schema.jl](test/schema.jl#L64)
- saving of a descriptor to disk [save.jl](test/save.jl#L9)

**Data Package**

- read an existing Data Package descriptor [read.jl](https://github.com/frictionlessdata/DataPackage.jl/blob/master/test/read.jl)
- validate an existing Data Package descriptor, including profile-specific validation via the registry of JSON Schemas
- create a new Data Package descriptor
- edit an existing Data Package descriptor
- as part of editing a descriptor, helper methods to add and remove resources from the resources array
- validate edits made to a data package descriptor
- save a Data Package descriptor to a file path
- zip a Data Package descriptor and its co-located references (more generically: "zip a data package")
- read a zip file that "claims" to be a data package
- save a zipped Data Package to disk

## API Proposal

Package names should be short, named as the base name of its source directory, and CamelCase, as per conventions described in Julia's [Manual on Packages](https://docs.julialang.org/en/latest/manual/packages/).

We will have two central classes within the project: `Schema` and `Table`. These will allow us to have constructions like `Schema.infer()`, which are desirable for readability.

This first design proposal follows the basic usages described in [tableschema-py](https://github.com/frictionlessdata/tableschema-py), [tableschema-js](https://github.com/frictionlessdata/tableschema-js) and [tableschema-go](https://github.com/frictionlessdata/tableschema-go).

The `Schema()` type constructor accepts a stream (file I/O), string (JSON) or dictionary (parsed object) representation of a table schema:

```Julia
function Schema(dictionary::Dict) (*Schema, error)
function Schema(filename::String) (*Schema, error)
function Schema(stream::IO) (*Schema, error)
```

`Table` represents a table that is an instance of the schema, and is validated by it.

`Field` represents a set of resources in the schema, such as the columns in a table.

## Usage

For an example usage sequence please see [runtests.jl](test/runtests.jl) in the `test` subfolder. Tables and schema can be loaded as follows:

```Julia
using TableSchema

# read Table Schema from a JSON file:
filestream = os.open("schema.json")
schema = Schema(filestream)

# err is falsy, or an error summary:
err = schema.errors

# read Table Schema from a CSV file:
filestream = os.open("data.csv")
table = Table(filestream)
rows = table.read()

# save the Schema back to a file
if not table.errors and table.schema.valid
  table.schema.save("data_schema.json")
end
```

## Implementation

- At least, finish the basic implementation level. Interfaces are [described here](https://github.com/frictionlessdata/implementations#interface).
- Must follow OKI [coding standards](https://github.com/okfn/coding-standards).
- Development process is [described here](https://github.com/frictionlessdata/implementations#development-process).
- For code [style and linting](https://github.com/okfn/coding-standards#style-and-linting), we are going to use the Julia [Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/), and the [Lint.jl](https://github.com/tonyhffong/Lint.jl) tool for static analysis.
- The code will be written and tested in [Julia 1.0](https://docs.julialang.org/en/v1/), the latest stable release of which is 1.0.0 as of September 2018.
- We will use Julia's standard [user manual](https://docs.julialang.org/en/v1/manual) as documentation, which can be [locally generated](https://github.com/JuliaLang/julia/tree/master/doc)  using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).
- The library documentation must be searchable at https://pkg.julialang.org
- Unit and integration tests are going to be done using facilities of the Julia [Standard Library](https://docs.julialang.org/en/v1/stdlib/Test/)
