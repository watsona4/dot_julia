import Pkg

function get_my_version()
    version_number = try
    projecttoml_filename = joinpath(dirname(dirname(@__FILE__)),"Project.toml")
    projecttoml_parsed = Pkg.TOML.parse(read(projecttoml_filename, String))
    VersionNumber(projecttoml_parsed["version"])
    catch e
        @warn(string("Ignoring error: ", e))
        VersionNumber(0)
    end
    return version_number
end

macro async_errhandle(ex)
    ex_string = string(ex)
    quote
        t = @async try
            $(esc(ex))
        catch err
            bt = catch_backtrace()
            @warn "@async error from @async $($ex_string)"
            showerror(stderr, err, bt)
        end
    end
end
