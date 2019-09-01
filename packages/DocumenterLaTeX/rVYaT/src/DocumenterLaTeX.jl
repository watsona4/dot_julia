module DocumenterLaTeX

using Documenter

const LaTeX = Documenter.Writers.LaTeXWriter.LaTeX
export LaTeX

function __init__()
    if !isdefined(Documenter.Writers, :enable_backend)
        @warn """Incompatible Documenter version.

        Documenter.Writers is missing the enable_backend() function.
        """
        return
    end
    Documenter.Writers.enable_backend(:latex)
    nothing
end

end # module
