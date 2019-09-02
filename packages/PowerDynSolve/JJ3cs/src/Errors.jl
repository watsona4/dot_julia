# (C) 2018 Potsdam Institute for Climate Impact Research, authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

using PowerDynBase: PowerDynamicsError

"Error to be thrown if something goes wrong during when solving a power grid model."
struct GridSolutionError <: PowerDynamicsError
    msg::String
end

"Error to be thrown if something goes wrong during when solving a power grid model."
struct PowerDynamicsPlottingError <: PowerDynamicsError
    msg::String
end
