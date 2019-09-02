using LinearAlgebra

module JuliaPetra

# Internal Utilities
include("Utils.jl")


# Communication interface
include("Comm.jl")
include("LocalComm.jl")
include("Distributor.jl")
include("Directory.jl")

include("BlockMapData.jl")
include("BlockMap.jl")

include("BasicDirectory.jl")
include("DirectoryMethods.jl")


# Communication implementations
include("SerialComm.jl")


# Data interface
include("ImportExportData.jl")
include("Import.jl")
include("Export.jl")

include("DistObject.jl")


# Dense Data types
include("MultiVector.jl")
include("DenseMultiVector.jl")


# Sparse Data types
include("Operator.jl")
include("RowGraph.jl")
include("RowMatrix.jl")


include("SparseRowView.jl")
include("LocalCSRGraph.jl")
include("LocalCSRMatrix.jl")

include("CSRGraphConstructors.jl")
include("CSRGraphInternalMethods.jl")
include("CSRGraphExternalMethods.jl")

include("CSRMatrix.jl")



function __init__()
    #code dependant on MPI.jl can't be precompiled
    sourcedir = dirname(@__FILE__)
    include(joinpath(sourcedir, "MPIUtil.jl"))
    include(joinpath(sourcedir, "MPIComm.jl"))
    include(joinpath(sourcedir, "MPIDistributor.jl"))
end

end # module
