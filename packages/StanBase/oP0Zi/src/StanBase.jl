"""
Helper infrastructure to compile and sample models using `cmdstan`.

[`StanModel`](@ref) wraps a model definition (source code), while [`stan_sample`](@ref) can
be used to sample from it.

[`stan_compile`](@ref) can be used to pre-compile a model without sampling. A
[`StanModelError`](@ref) is thrown if this fails, which contains the error messages from
`stanc`.
"""
module StanBase

using Reexport

@reexport using Unicode, DelimitedFiles, Distributed
@reexport using StanDump, StanRun, StanSamples
@reexport using MCMCChains
@reexport using Parameters

using DocStringExtensions: FIELDS, SIGNATURES, TYPEDEF

import StanRun: stan_sample, stan_cmd_and_paths, default_output_base
import StanSamples: read_samples

include("stanmodel/shared_fields.jl")
include("stanmodel/top_level_types.jl")
include("stanmodel/help_types.jl")
include("stanmodel/HelpModel.jl")
include("stanmodel/update_model_file.jl")
include("stanmodel/number_of_chains.jl")
include("stanrun/cmdline.jl")
include("stanrun/stan_sample.jl")
include("stansamples/stan_summary.jl")
include("stansamples/read_summary.jl")

"""
The directory which contains the cmdstan executables such as `bin/stanc` and
`bin/stansummary`. Inferred from the environment variable `JULIA_CMDSTAN_HOME` or `ENV["JULIA_CMDSTAN_HOME"]`
when available.

If these are not available, use `set_cmdstan_home!` to set the value of CMDSTAN_HOME.

Example: `set_cmdstan_home!(homedir() * "/Projects/Stan/cmdstan/")`

Executing `versioninfo()` will display the value of `JULIA_CMDSTAN_HOME` if defined.
"""
CMDSTAN_HOME=""

function __init__()
  global CMDSTAN_HOME = if isdefined(Main, :JULIA_CMDSTAN_HOME)
    Main.JULIA_CMDSTAN_HOME
  elseif haskey(ENV, "JULIA_CMDSTAN_HOME")
    ENV["JULIA_CMDSTAN_HOME"]
  elseif haskey(ENV, "CMDSTAN_HOME")
    ENV["CMDSTAN_HOME"]
  else
    @warn("Environment variable CMDSTAN_HOME not set. Use set_cmdstan_home!.")
    ""
  end
end

"""Set the path for the `CMDSTAN_HOME` environment variable.

Example: `set_cmdstan_home!(homedir() * "/Projects/Stan/cmdstan/")`
"""
set_cmdstan_home!(path) = global CMDSTAN_HOME = path

const src_path = @__DIR__

"""
# `rel_path_stanbase`

Relative path using the StanBase.jl src directory. This approach has been copied from
[DynamicHMCExamples.jl](https://github.com/tpapp/DynamicHMCExamples.jl)

### Example to get access to the data subdirectory
```julia
rel_path_stanbase("..", "data")
```
"""
rel_path_stanbase(parts...) = normpath(joinpath(src_path, parts...))

stan_help = stan_sample

export
  @shared_fields_stanmodels,
  CmdStanModels,
  HelpModel,
  cmdline,
  stan_help,
  stan_sample,
  read_summary,
  stan_summary,
  set_cmdstan_home!

end # module
