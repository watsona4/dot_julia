#!/usr/bin/env julia

using SimradRaw
using SimradEK60TestData
using Test

# EK60 file

_datagrams = collect(datagrams(EK60_SAMPLE))

@test length(_datagrams) == 2860

# EK80 file

# _datagrams = collect(datagrams(EK80_SAMPLE))

# @test length(_datagrams) == 461
