function get_n_chains(model::T) where {T <: CmdStanModels}
  model.n_chains[1]
end

function set_n_chains(model::T, n_chains) where {T <: CmdStanModels}
  model.n_chains[1] = n_chains
end