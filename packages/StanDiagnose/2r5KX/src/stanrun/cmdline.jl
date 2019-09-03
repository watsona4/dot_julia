"""

# cmdline 

Recursively parse the model to construct command line. 

### Method
```julia
cmdline(m)
```

### Required arguments
```julia
* `m::SampleModel`                : CmdStanSampleModel
```
"""
function cmdline(m::Union{DiagnoseModel, Diagnose, Gradient}, id)
  
  #=
  `./bernoulli diagnose test=gradient epsilon=1.0e-6 error=1.0e-6 
  random seed=-1 id=1 data file=bernoulli_1.data.R 
  output file=bernoulli_diagnose_1.csv refresh=100`
  =#
  
  cmd = ``
  # parse top level
  if isa(m, DiagnoseModel)
    # Handle the model name field for unix and windows
    cmd = `$(m.exec_path)`

    # Sample() specific portion of the model, might be recursive
    cmd = `$cmd $(cmdline(getfield(m, :method), id))`
    
    # Common to all models, not recursive
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
    
  else # The 'recursive' part, currently only Gradient <: Diagnostics
    
    if isa(m, Diagnostics)
      # Inset 'test=gradient' into cmdline
      cmd = `$cmd test=$(split(lowercase(string(typeof(m))), '.')[end])`
    else
      # Insert initial `diagnose` into cmdline
      cmd = `$cmd $(split(lowercase(string(typeof(m))), '.')[end])`
    end
    for name in fieldnames(typeof(m))
      if length(fieldnames(typeof(getfield(m, name)))) == 0
        cmd = `$cmd $(name)=$(getfield(m, name))`
      else
        # Composite (Gradient) object, handle all fields 
        # (by recursively calling cmdline) 
        cmd = `$cmd $(cmdline(getfield(m, name), id))`
      end
    end
  end
  
  cmd
  
end

