"""

# read_variational

Read variational sample output files created by cmdstan. 

### Method
```julia
read_variational(m::VariationalModelodel)
```

### Required arguments
```julia
* `m::VariationalModel`    : VariationalModel object
```

"""
function read_variational(m::VariationalModel)

  local a3d, index, idx, indvec
  
  ftype = "chain"
  
  for i in 1:StanBase.get_n_chains(m)
    if isfile("$(m.output_base)_$(ftype)_$(i).csv")
      instream = open("$(m.output_base)_$(ftype)_$(i).csv")
      skipchars(isspace, instream, linecomment='#')
      line = Unicode.normalize(readline(instream), newline2lf=true)
      idx = split(strip(line), ",")
      index = [idx[k] for k in 1:length(idx)]
      indvec = 1:length(index)
      if i == 1
        a3d = fill(0.0, m.method.output_samples, length(indvec), 
          StanBase.get_n_chains(m))
      end
      skipchars(isspace, instream, linecomment='#')
      for j in 1:m.method.output_samples
        skipchars(isspace, instream, linecomment='#')
        line = Unicode.normalize(readline(instream), newline2lf=true)
        if eof(instream) && length(line) < 2
          close(instream)
          break
        else
          flds = parse.(Float64, (split(strip(line), ",")))
          flds = reshape(flds[indvec], 1, length(indvec))
          a3d[j,:,i] = flds
        end
      end
    end
  end
  
  cnames = convert.(String, idx[indvec])
  
  (a3d, cnames)
  
end

