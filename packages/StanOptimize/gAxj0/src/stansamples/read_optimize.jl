"""

# read_optimize

Read optimize output file created by cmdstan. 

### Method
```julia
read_optimize(m::Stanmodel)
```

### Required arguments
```julia
* `m::Stanmodel`    : Stanmodel object
```

"""
function read_optimize(model::OptimizeModel)
  ## Collect the results in a Dict
  
  cnames = String[]
  res_type = "chain"
  
  ## tdict contains the arrays of values ##
  tdict = Dict()
  
  for i in 1:StanBase.get_n_chains(model)
      if isfile("$(model.output_base)_$(res_type)_$(i).csv")
        
        # A result type file for chain i is present ##
        
        instream = open("$(model.output_base)_$(res_type)_$(i).csv")
        if i == 1
          str = read(instream, String)
          sstr = split(str)
          tdict[:stan_version] = "$(parse(Int, sstr[4])).$(parse(Int, sstr[8])).$(parse(Int, sstr[12]))"
          close(instream)
          instream = open("$(model.output_base)_$(res_type)_$(i).csv")
        end
        
        # After reopening the file, skip all comment lines
        
        skipchars(isspace, instream, linecomment='#')
        line = Unicode.normalize(readline(instream), newline2lf=true)
        
        # Extract samples variable names
        
        idx = split(strip(line), ",")
        index = [idx[k] for k in 1:length(idx)]
        cnames = convert.(String, idx)

        # Read optimized values
        for i in 1:model.method.iter
          line = Unicode.normalize(readline(instream), newline2lf=true)
          flds = Float64[]
          if eof(instream) && length(line) < 2
            close(instream)
            break
          else
            flds = parse.(Float64, split(strip(line), ","))
            for k in 1:length(index)
              if index[k] in keys(tdict)
                
                # For all subsequent chains the entry should already be in tdict
                
                append!(tdict[index[k]], flds[k])
              else
                
                # First chain
                
                tdict[index[k]] = [flds[k]]
              end
            end
          end
        end
      end
  end
  
  (tdict, cnames)
  
end

