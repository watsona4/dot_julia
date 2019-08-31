module ApplicationBuilderAppUtilsTest

using ApplicationBuilderAppUtils
using Test

function with_tmp_PROGRAM_FILE(f::Function, path)
    tmpdir = mktempdir()
    program_file = joinpath(tmpdir, path)
    mkpath(program_file)

    _orig_PROGRAM_FILE = Base.PROGRAM_FILE
    try
        @eval Base PROGRAM_FILE = $program_file
        f(program_file)
    finally
        @eval Base PROGRAM_FILE = $_orig_PROGRAM_FILE
    end
end

@testset "bundle_resources" begin
    @static if Sys.isapple()
        with_tmp_PROGRAM_FILE("MyApp.app/Contents/MacOS/program") do program_file
            @test splitpath(ApplicationBuilderAppUtils.get_bundle_resources_dir())[end-2:end] == ["MyApp.app", "Contents", "Resources"]
        end
    else
        with_tmp_PROGRAM_FILE("MyApp/bin/program") do program_file
            @test splitpath(ApplicationBuilderAppUtils.get_bundle_resources_dir())[end-1:end] == ["MyApp", "res"]
        end
    end
end

end
