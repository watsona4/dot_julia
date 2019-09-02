using PkgUtils
using Pkg, Test

@elapsed begin
    @time @testset "Dependencies" begin include("dependencies.jl") end
end
  
