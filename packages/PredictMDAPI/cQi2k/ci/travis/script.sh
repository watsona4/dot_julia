#!/bin/bash

set -ev

echo "COMPILED_MODULES=$COMPILED_MODULES"
export JULIA_FLAGS="--check-bounds=yes --code-coverage=all --color=yes --compiled-modules=$COMPILED_MODULES --inline=no"
echo "JULIA_FLAGS=$JULIA_FLAGS"

julia $JULIA_FLAGS -e '
    import Pkg;
    Pkg.build("PredictMDAPI");
    '

julia $JULIA_FLAGS -e '
    import Pkg;
    Pkg.test("PredictMDAPI"; coverage=true);
    '

julia $JULIA_FLAGS -e '
    logger = Base.CoreLogging.current_logger_for_env(Base.CoreLogging.Debug, Symbol(splitext(basename(something(@__FILE__, "nothing")))[1]), something(@__MODULE__, "nothing"))
    if !isnothing(logger)
        if ispath(Base.active_project())
            println(logger.stream, "# Location of default environment Project.toml: \"$(Base.active_project())\"")
            println(logger.stream, "# Beginning of default environment Project.toml")
            println(logger.stream, read(Base.active_project(), String))
            println(logger.stream, "# End of default environment Project.toml")
        else
            println(logger.stream, "# File \"$(Base.active_project())\" does not exist")
        end
        if ispath(joinpath(dirname(Base.active_project()), "Manifest.toml"))
            println(logger.stream, "# Location of default environment Manifest.toml: \"$(joinpath(dirname(Base.active_project()), "Manifest.toml"))\"")
            println(logger.stream, "# Beginning of default environment Manifest.toml")
            println(logger.stream, read(joinpath(dirname(Base.active_project()), "Manifest.toml"),String))
            println(logger.stream, "# End of default environment Manifest.toml")
        else
            println(logger.stream, "# File \"$(joinpath(dirname(Base.active_project()), "Manifest.toml"))\" does not exist")
        end
    end
    '

julia $JULIA_FLAGS -e '
    import Pkg;
    try Pkg.add("Coverage") catch end;
    '

julia $JULIA_FLAGS -e '
    import Coverage;
    import PredictMDAPI;
    cd(joinpath(dirname(pathof(PredictMDAPI)), "..",));
    Coverage.Codecov.submit(Coverage.Codecov.process_folder());
    '

julia $JULIA_FLAGS -e '
    logger = Base.CoreLogging.current_logger_for_env(Base.CoreLogging.Debug, Symbol(splitext(basename(something(@__FILE__, "nothing")))[1]), something(@__MODULE__, "nothing"))
    if !isnothing(logger)
        if ispath(Base.active_project())
            println(logger.stream, "# Location of default environment Project.toml: \"$(Base.active_project())\"")
            println(logger.stream, "# Beginning of default environment Project.toml")
            println(logger.stream, read(Base.active_project(), String))
            println(logger.stream, "# End of default environment Project.toml")
        else
            println(logger.stream, "# File \"$(Base.active_project())\" does not exist")
        end
        if ispath(joinpath(dirname(Base.active_project()), "Manifest.toml"))
            println(logger.stream, "# Location of default environment Manifest.toml: \"$(joinpath(dirname(Base.active_project()), "Manifest.toml"))\"")
            println(logger.stream, "# Beginning of default environment Manifest.toml")
            println(logger.stream, read(joinpath(dirname(Base.active_project()), "Manifest.toml"),String))
            println(logger.stream, "# End of default environment Manifest.toml")
        else
            println(logger.stream, "# File \"$(joinpath(dirname(Base.active_project()), "Manifest.toml"))\" does not exist")
        end
    end
    '
