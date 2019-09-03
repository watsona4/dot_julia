macro shared_fields_stanmodels()
  return esc(:(
    name::AbstractString;
    model::AbstractString;
    n_chains::Vector{Int64};
    seed::StanBase.RandomSeed;
    init::StanBase.Init;
    output::StanBase.Output;
    tmpdir::AbstractString;
    output_base::AbstractString;
    exec_path::AbstractString;
    data_file::Vector{String};
    init_file::Vector{String};
    cmds::Vector{Cmd};
    sample_file::Vector{String};
    log_file::Vector{String};
    diagnostic_file::Vector{String};
    summary::Bool;
    printsummary::Bool;
    sm::StanRun.StanModel;
  ))
end
