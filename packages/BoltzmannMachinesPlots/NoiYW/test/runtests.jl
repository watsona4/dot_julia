# Run examples in BoltzmannMachines.jl with plotting
import BoltzmannMachines
include(joinpath(dirname(pathof(BoltzmannMachines)), "..", "test", "examples.jl"))

using BoltzmannMachinesPlots
function test_scatterhidden()
   hidden = rand(100, 2)
   labels = rand(["1", "2", "3"], 100)
   scatterhidden(hidden,
         opacity = 0.5, labels = labels)
end
test_scatterhidden()

