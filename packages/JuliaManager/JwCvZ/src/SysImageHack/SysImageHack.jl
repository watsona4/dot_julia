module SysImageHack

using PackageCompiler: compile_incremental

assetpath(name) = joinpath(@__DIR__, "scripts", name)

function compile_patched_sysimage(sysimage; kwargs...)
    tmp_syso, _curr_syso = compile_incremental(
        assetpath("Project.toml"),
        assetpath("patch.jl");
        kwargs...)
    cp(tmp_syso, sysimage, force=true)
    return
end

end  # module
