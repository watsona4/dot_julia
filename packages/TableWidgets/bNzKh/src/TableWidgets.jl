module TableWidgets

using InteractBase, Widgets, CSSUtil, Observables, WebIO
using Tables
using IterTools
import Observables: AbstractObservable, @map, @map!, @on
import Widgets: AbstractWidget, components, widgettype, layout!

import InteractBulma
using DataStructures
import DataStructures: reset!

using MacroTools

export categoricalselector, rangeselector, selector, selectors
export dataeditor, addfilter

const examplefolder = joinpath(@__DIR__, "..", "examples")

include("utils.jl")
include("selector.jl")
include("selectors.jl")
include("table.jl")
include("edit.jl")
include("filter.jl")

end # module
