using Test, GoogleSheetsCSVExporter, CSV

url = "https://docs.google.com/spreadsheets/d/10lDb5TlSZwlsxUSyzLcWDMI9LFRK1S_MRuz8pI_FFxA/edit#gid=0"
table = GoogleSheetsCSVExporter.fromURI(url) |> CSV.File
rows = map(row -> (row.a, row.b, row.c), table)
@test rows[1] == (1, 2, 3)
@test rows[2] === (4, missing, 5)
