import Base.show
using Random

mutable struct HelpModel <: CmdStanModels	
    @shared_fields_stanmodels
    method::Help
end

function HelpModel(
  name::AbstractString,
  model::AbstractString,
  n_chains=[4];
  seed = RandomSeed(),
  init = Init(),
  output = Output(),
  tmpdir = mktempdir(),
  method = Help(),
  kwargs...)
  
  !isdir(tmpdir) && mkdir(tmpdir)
  
  StanBase.update_model_file(joinpath(tmpdir, "$(name).stan"), strip(model))
  sm = StanModel(joinpath(tmpdir, "$(name).stan"))
  
  output_base = StanRun.default_output_base(sm)
  exec_path = StanRun.ensure_executable(sm)
  
  stan_compile(sm)
  
  HelpModel(name, model, n_chains, seed, init, output,
    tmpdir, output_base, exec_path, String[], String[], 
    Cmd[], String[], String[], String[], false, false, sm, method)
end

function help_model_show(io::IO, m, compact::Bool)
  println("  name =                    \"$(m.name)\"")
  println("  method =                  $(m.method)")
  println("  n_chains =                $(get_n_chains(m))")
  println("  output =                  Output()")
  println("    file =                    \"$(split(m.output.file, "/")[end])\"")
  println("    diagnostics_file =        \"$(split(m.output.diagnostic_file, "/")[end])\"")
  println("    refresh =                 $(m.output.refresh)")
  println("  tmpdir =                  \"$(m.tmpdir)\"")
end

show(io::IO, m::HelpModel) = help_model_show(io, m, false)
