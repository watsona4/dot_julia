using Test
using Documenter

@test isdefined(Documenter.Writers, :enable_backend)
@test isdefined(Documenter.Writers, :backends_enabled)

@test Documenter.Writers.backends_enabled[:latex] === false

using DocumenterLaTeX

@test Documenter.Writers.backends_enabled[:latex] === true
