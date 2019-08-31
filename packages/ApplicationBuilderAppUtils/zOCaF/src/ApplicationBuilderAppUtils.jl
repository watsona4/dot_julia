"""
    module ApplicationBuilderAppUtils

Provides utilities for applications built with ApplicationBuilder.jl.
"""
module ApplicationBuilderAppUtils

"""
    is_static_compiling()

Returns true if the caller is being statically compiled via
`ApplicationBuilder.build_app_bundle()`, and false otherwise.

Note that this will return false when _executing_ a statically compiled program; it only
returns true _during_ compilation. It is intended for use in top-level, global statements.
"""
function is_static_compiling()
    get(ENV, "COMPILING_APPLE_BUNDLE", "") == "true"
end

"""
    get_bundle_resources_dir()

Return the runtime path to the application bundle's resources directory. This is calculated
relative to the path to this binary, obtained via `argv[0]`.

On macOS, this will be `/path/to/MyApp.app/Contents/Resources`. On Windows/linux, this will
be `/path/to/MyApp/res`.
"""
function get_bundle_resources_dir()
    # When statically compiled, PROGRAM_FILE is set by ApplicationBuilder/src/program.c
    # Use `realpath()` to follow any potential symlinks so that we end up navigating to the
    # true bundle resources directory.
    full_binary_name = realpath(PROGRAM_FILE)

    @static if Sys.isapple()
        m = match(r".app/Contents/MacOS/[^/]+$", full_binary_name)
        if m != nothing
            resources_dir = joinpath(dirname(dirname(full_binary_name)), "Resources")
            return resources_dir
        else
            return pwd()
        end
    else
        # TODO: Should we do similar verification on linux/windows? Maybe use splitpath()?
        resources_dir = joinpath(dirname(dirname(full_binary_name)), "res")
        return resources_dir
    end
end

"""
    cd_to_bundle_resources()

Change directories to the application bundle's resources directory, as calculated by
`get_bundle_resources_dir()`.

On macOS, this will be `/path/to/MyApp.app/Contents/Resources`. On Windows/linux, this will
be `/path/to/MyApp/res`.
"""
function cd_to_bundle_resources()
    resources_dir = get_bundle_resources_dir()
    cd(resources_dir)
    println("cd_to_bundle_resources(): Changed to new pwd: $(pwd())")
    nothing
end

# Fully precompile methods in this Module so that they don't add startup time to binaries.
precompile(is_static_compiling, ())
precompile(get_bundle_resources_dir, ())
precompile(cd_to_bundle_resources, ())

end  # module
