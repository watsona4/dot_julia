# GoogleSheetsCSVExporter

[![Build Status](https://travis-ci.com/eiel/GoogleSheetsCSVExporter.jl.svg?branch=master)](https://travis-ci.com/eiel/GoogleSheetsCSVExporter.jl)

Import Google Sheets using CSV Export.
Support only, link shared file.

## Example

```
using GoogleSheetsCSVExporter, CSV, DataFrames

url = "https://docs.google.com/spreadsheets/d/1klF3cdwF91KtEV8MGgplkqpDGRDpKoD9zIerPJDGovA/edit#gid=0"
@show GoogleSheetsCSVExporter.fromURI(url) |> CSV.File |> DataFrame
```
