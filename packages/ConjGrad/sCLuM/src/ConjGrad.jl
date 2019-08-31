module ConjGrad

    using LinearAlgebra
    using MPI

    export CGData
    export cg
    export cg!

    include("linearalgebra.jl")
    include("cg.jl")

end  # module ConjGrad
