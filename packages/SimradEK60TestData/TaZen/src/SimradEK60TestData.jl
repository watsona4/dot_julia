module SimradEK60TestData

export EK60_DATA, EK60_SAMPLE, ECS_SAMPLE

const EK60_DATA = joinpath(dirname(@__FILE__), "../data")
const EK60_SAMPLE = joinpath(EK60_DATA,"JR230-D20091215-T121917.raw")
const ECS_SAMPLE = joinpath(EK60_DATA, "JR230.ecs")

end # module
