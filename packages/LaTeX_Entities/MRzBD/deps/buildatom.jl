# Generate completions.json
using LaTeX_Entities
const LE = LaTeX_Entities

open("completions.json", "w") do io
    println(io, "{")
    def = LE.default
    for nam in def.nam
        println(io, "  \", word, ""\": \"", LE.lookupname(def, nam), ""\",")
    end
    skip(io, -2)
    println(io)
    println(io, "}")
end
