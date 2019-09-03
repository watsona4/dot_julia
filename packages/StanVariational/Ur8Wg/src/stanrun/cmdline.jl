"""

# cmdline 

Recursively parse the model to construct command line. 

### Method
```julia
cmdline(m)
```

### Required arguments
```julia
* `m::CmdStanSampleModel`                : CmdStanSampleModel
```

### Related help
```julia
?CmdStanSampleModel                      : Create a CmdStanSampleModel
```
"""
function cmdline(m::Union{VariationalModel, Variational}, id)
  
  #=
  `/Users/rob/.julia/dev/StanVariational/examples/Bernoulli/tmp/bernoulli 
  variational algorithm=meanfield grad_samples=1 elbo_samples=100 
  iter=10000 tol_rel_obj=0.01 eval_elbo=100 output_samples=10000 
  random seed=-1 init=2 id=1 
  data file=/Users/rob/.julia/dev/StanVariational/examples/Bernoulli/tmp/bernoulli_data_1.R 
  output file=/Users/rob/.julia/dev/StanVariational/examples/Bernoulli/tmp/bernoulli_chain_1.csv 
  refresh=100`
  =#
  
  cmd = ``
  if isa(m, VariationalModel)
    # Handle the model name field for unix and windows
    cmd = `$(m.exec_path)`

    # Sample() specific portion of the model
    cmd = `$cmd $(cmdline(getfield(m, :method), id))`
    
    # Common to all models
    cmd = `$cmd random seed=$(getfield(m, :seed).seed)`
    
    # Init file required?
    if length(m.init_file) > 0 && isfile(m.init_file[id])
      cmd = `$cmd init=$(m.init_file[id])`
    else
      cmd = `$cmd init=$(m.init.bound)`
    end
    
    # Data file required?
    if length(m.data_file) > 0 && isfile(m.data_file[id])
      cmd = `$cmd id=$(id) data file=$(m.data_file[id])`
    end
    
    # Output options
    cmd = `$cmd output`
    if length(getfield(m, :output).file) > 0
      cmd = `$cmd file=$(string(getfield(m, :output).file))`
    end
    if length(m.diagnostic_file) > 0
      cmd = `$cmd diagnostic_file=$(string(getfield(m, :output).diagnostic_file))`
    end
    cmd = `$cmd refresh=$(string(getfield(m, :output).refresh))`
    
  else
    
    # The 'recursive' part
    cmd = `$cmd $(split(lowercase(string(typeof(m))), '.')[end])`
    for name in fieldnames(typeof(m))
      cmd = `$cmd $(name)=$(getfield(m, name))`
    end
  end
  
  cmd
  
end

