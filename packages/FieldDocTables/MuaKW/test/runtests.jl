module TestFieldDocTables

using FieldDocTables, FieldMetadata, PrettyTables, Test, Markdown

import FieldMetadata: @default, default, @bounds, bounds, @description, description

const FIELDDOCTABLE = FieldDocTable((Description=description, Default=default, Bounds=bounds))

"""
This type tests if FIELDMETADATA is printed as a markdown table.

$(FIELDDOCTABLE)
"""
@description @bounds @default mutable struct TestStruct
   " A field doc"
   a::Int     | 2   | (1, 10)     | "an Int"
   b::Float64 | 4.0 | (2.0, 20.0) | "a Float"
end

@test Markdown.plain(@doc TestStruct) == "This type tests if FIELDMETADATA is printed as a markdown table.\n\n| Field | Description | Default |      Bounds |        Docs |\n| -----:| -----------:| -------:| -----------:| -----------:|\n|     a |      an Int |       2 |     (1, 10) | A field doc |\n|     b |     a Float |     4.0 | (2.0, 20.0) |             |\n"

end
