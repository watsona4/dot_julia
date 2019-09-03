#!/usr/bin/env julia

using SimradEK60TestData
using Test

@test isfile(EK60_SAMPLE)
@test isfile(ECS_SAMPLE)
@test isfile(joinpath(EK60_DATA, "JR230.ecs"))
