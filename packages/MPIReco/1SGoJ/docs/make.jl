using Documenter, MPIReco

makedocs(
    format = :html,
    modules = [MPIReco],
    sitename = "MPI Reconstruction",
    authors = "Tobias Knopp,...",
    pages = [
        "Home" => "index.md",
        "Getting Started" => "overview.md",
        "Basic Reconstruction" => "basicReconstruction.md",
        "Parameters" => "parameters.md",
        "Results" => "recoResults.md",
        "Multi-Contrast" => "multiContrast.md",
        "Multi-Patch" => "multiPatch.md",
        "Compression" => "matrixCompression.md"
    ],
    html_prettyurls = false, #!("local" in ARGS),
)

deploydocs(repo   = "github.com/MagneticParticleImaging/MPIReco.jl.git",
           target = "build")
