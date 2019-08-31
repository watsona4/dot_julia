# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AsterReader.jl/blob/master/LICENSE

using Documenter, AsterReader

makedocs(modules=[AsterReader],
         format = :html,
         sitename = "AsterReader.jl",
         pages = [
                  "Introduction" => "index.md",
                  "API" => "api.md"
                 ])
