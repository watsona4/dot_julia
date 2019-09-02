#=
    build
    Copyright © 2019 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using Conda

cforge = "conda-forge"
if !(cforge in Conda.channels())
    Conda.add_channel(cforge)
end

Conda.add("jupyter_contrib_nbextensions")
