using Nemo

if VERSION < v"0.7.0-DEV.2004"
	using Base.Test
else
	using Test
end

include("../test/ModularForms-test.jl")

test_all()
