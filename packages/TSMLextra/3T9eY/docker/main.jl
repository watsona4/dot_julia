using TSML
using TSMLextra
using TSML.ArgumentParsers

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
  tsmlmain()
end
