using EchoviewEcs

using Test

filename = joinpath(dirname(@__FILE__),
                  "data/sample.ecs")

calibrations = load(filename)

@test length(calibrations) == 4
@test calibrations[1]["Frequency"] == 18.0
@test calibrations[2]["Frequency"] == 38.0
@test calibrations[3]["Frequency"] == 120.0
@test calibrations[4]["Frequency"] == 200.0
@test calibrations[4]["EK60SaCorrection"] == -1.54f0

@test calibrations[1]["SoundSpeed"] == 1520f0 # Specified in SourceCal
@test calibrations[2]["SoundSpeed"] == 1541.21f0 # Inheritted from FileSet
