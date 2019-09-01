
using Literate

freadme=joinpath(@__DIR__, "readme.jl")
output_folder=@__DIR__


Literate.markdown(freadme, output_folder)

