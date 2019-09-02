# Generate julialatex.el file
using LaTeX_Entities
const LE = LaTeX_Entities

open("julialatex.el", "w") do io
    def = LE.default
    for nam in def.nam
        println(io, "(puthash \"", word, "\" \"", LE.lookupname(def, nam), "\" julia-latexsubs)")
    end
end
