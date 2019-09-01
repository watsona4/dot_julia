push!(LOAD_PATH,"../src/")
using Documenter,EntityComponentSystem
makedocs(
modules = [EntityComponentSystem],
sitename="EntityComponentSystem.js")
