# Part of Beauty.jl: Add Beauty to your julia output.
# Copyright (C) 2019 Quantum Factory GmbH

using DataFrames, Beauty
using DocStringExtensions

"""

Show displays `DataFrames.DataFrame` objects.

$(SIGNATURES)

"""
function Base.show(io::IO, mime::MIME"text/html", df::DataFrame)
    print(io, "<table class=\"data-frame\">")
    print(io, "<theard><tr>")
    for col in names(df)
        print(io, "<th>")
        print(io, string(col))
        print(io, "</th>")
    end
    print(io, "</tr></theard>")
    for row in eachrow(df)
        print(io, "<tr>")
        for val in row
            print(io, "<td>")
            try
                show(io, mime, val)
            catch
                if val isa AbstractString
                    # To Do: read the julia docs! It might make sense
                    #        to fix the generic print function for
                    #        printing to an IOContext with the
                    #        text/html encoding instead of only fixing
                    #        the following line to include a html
                    #        escaping function...
                    escaped = stringreplace(
                        val,
                        "<" => "@lt;",
                        ">" => "&gt;"
                        # and possibly more (but are they required, in
                        # modern, UTF8 html?)
                    )
                    print(io, escaped) # dirty hack; we should convert
                                       # the string val's content to
                                       # HTML (escaping occurences
                                       # e.g. of "<" and ">"), but
                                       # doing that the easy way, by
                                       # using show, will quote it
                elseif !(val === missing)
                    show(io, val)
                end
            end
            print(io, "</td>")
        end
        print(io, "</tr>")
    end
    print(io, "</table>")
end
