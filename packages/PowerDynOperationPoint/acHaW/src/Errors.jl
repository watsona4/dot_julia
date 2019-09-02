# (C) 2018 authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

using PowerDynBase: PowerDynamicsError

"Error to be thrown if something goes wrong during the operation point search."
struct OperationPointError <: PowerDynamicsError
    msg::String
end
