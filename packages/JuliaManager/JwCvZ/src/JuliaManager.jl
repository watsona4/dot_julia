module JuliaManager

const version = v"0.1.1"
# This could be useful for checking frontend-backend compatibility.

include("SysImageHack/SysImageHack.jl")
using .SysImageHack: compile_patched_sysimage

bundled_jlm() = joinpath(dirname(@__DIR__), "jlm", "jlm")

"""
    JuliaManager.install_cli([destdir = "~/.julia/bin"])

Install `jlm` CLI at `destdir`.
"""
function install_cli(destdir=joinpath(homedir(), ".julia", "bin"))
    destpath = joinpath(destdir, "jlm")
    if isfile(destpath)
        @info "CLI `jlm` is already installed at $destpath"
    else
        @info "Installing CLI `jlm` at $destpath"
        mkpath(destdir)
        symlink(bundled_jlm(), destpath)
    end

    installed = Sys.which("jlm")
    if installed === nothing
        @warn "`jlm` is not on PATH.  Please make sure $destdir is in PATH."
    elseif realpath(installed) != realpath(destpath)
        @warn """
        A `jlm` program different from the one just installed may be
        executed.  Please check your PATH.
        Program to be executed:
            $installed
        Program that is installed:
            $destpath
        """
    end

    return
end

end # module
