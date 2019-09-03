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
function cmdline(m::Union{OptimizeModel, Optimize, Lbfgs, Bfgs, Newton}, id)
  
  #=
  `/Users/rob/.julia/dev/StanOptimize/examples/Bernoulli/tmp/bernoulli
  optimize algorithm=lbfgs init_alpha=0.001 tol_obj=1.0e-8 tol_rel_
  obj=10000.0 tol_grad=1.0e-8 tol_rel_grad=1.0e7 tol_param=1.0e-8 
  history_size=5 iter=2000 save_iterations=1 random seed=-1 init=2 
  id=1 data file=/Users/rob/.julia/dev/StanOptimize/examples/Bernoulli/tmp/bernoulli_data_1.R 
  output file=/Users/rob/.julia/dev/StanOptimize/examples/Bernoulli/tmp/bernoulli_chain_1.csv 
  refresh=100`
  =#
  
  cmd = ``
  if isa(m, OptimizeModel)
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
    if isa(m, OptimizeAlgorithm)
      cmd = `$cmd algorithm=$(split(lowercase(string(typeof(m))), '.')[end])`
    else
      cmd = `$cmd $(split(lowercase(string(typeof(m))), '.')[end])`
    end
    for name in fieldnames(typeof(m))
      if  isa(getfield(m, name), String) || isa(getfield(m, name), Tuple)
        cmd = `$cmd $(name)=$(getfield(m, name))`
      elseif length(fieldnames(typeof(getfield(m, name)))) == 0
        if isa(getfield(m, name), Bool)
          cmd = `$cmd $(name)=$(getfield(m, name) ? 1 : 0)`
        else
          if name == :metric || isa(getfield(m, name), DataType)
            cmd = `$cmd $(name)=$(split(lowercase(string(typeof(getfield(m, name)))), '.')[end])`
          else
            cmd = `$cmd $(name)=$(getfield(m, name))`
          end
        end
      else
        cmd = `$cmd $(cmdline(getfield(m, name), id))`
      end
    end
  end
  
  cmd
  
end

