import PredictMDAPI

import Test

logger = Base.CoreLogging.current_logger_for_env(Base.CoreLogging.Debug, Symbol(splitext(basename(something(@__FILE__, "nothing")))[1]), something(@__MODULE__, "nothing"))
if !isnothing(logger)
    if ispath(Base.active_project())
        println(logger.stream, "# Location of test environment Project.toml: \"$(Base.active_project())\"")
        println(logger.stream, "# Beginning of test environment Project.toml")
        println(logger.stream, read(Base.active_project(), String))
        println(logger.stream, "# End of test environment Project.toml")
    else
        println(logger.stream, "# File \"$(Base.active_project())\" does not exist")
    end
    if ispath(joinpath(dirname(Base.active_project()), "Manifest.toml"))
        println(logger.stream, "# Location of test environment Manifest.toml: \"$(joinpath(dirname(Base.active_project()), "Manifest.toml"))\"")
        println(logger.stream, "# Beginning of test environment Manifest.toml")
        println(logger.stream, read(joinpath(dirname(Base.active_project()), "Manifest.toml"),String))
        println(logger.stream, "# End of test environment Manifest.toml")
    else
        println(logger.stream, "# File \"$(joinpath(dirname(Base.active_project()), "Manifest.toml"))\" does not exist")
    end
end

logger = Base.CoreLogging.current_logger_for_env(Base.CoreLogging.Debug, Symbol(splitext(basename(something(@__FILE__, "nothing")))[1]), something(@__MODULE__, "nothing"))
if !isnothing(logger)
    if ispath(joinpath(dirname(pathof(PredictMDAPI)), "..", "Project.toml"))
        println(logger.stream, "# Location of PredictMDAPI package Project.toml: \"$(joinpath(dirname(pathof(PredictMDAPI)), "..", "Project.toml"))\"")
        println(logger.stream, "# Beginning of PredictMDAPI package Project.toml")
        println(logger.stream, read(joinpath(dirname(pathof(PredictMDAPI)), "..", "Project.toml"), String))
        println(logger.stream, "# End of PredictMDAPI package Project.toml")
    else
        println(logger.stream, "# File \"$(joinpath(dirname(pathof(PredictMDAPI)), "..", "Project.toml"))\" does not exist")
    end
    if ispath(joinpath(dirname(pathof(PredictMDAPI)), "..", "Manifest.toml"))
        println(logger.stream, "# Location of PredictMDAPI package Manifest.toml: \"$(joinpath(dirname(pathof(PredictMDAPI)), "..", "Manifest.toml"))\"")
        println(logger.stream, "# Beginning of PredictMDAPI package Manifest.toml")
        println(logger.stream, read(joinpath(dirname(pathof(PredictMDAPI)), "..", "Manifest.toml"),String))
        println(logger.stream, "# End of PredictMDAPI package Manifest.toml")
    else
        println(logger.stream, "# File \"$(joinpath(dirname(pathof(PredictMDAPI)), "..", "Manifest.toml"))\" does not exist")
    end
end
