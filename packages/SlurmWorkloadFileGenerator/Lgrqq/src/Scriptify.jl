"""
# module Scriptify



# Examples

```jldoctest
julia>
```
"""
module Scriptify

using SlurmWorkloadFileGenerator.Commands
using SlurmWorkloadFileGenerator.SystemModules
using SlurmWorkloadFileGenerator.Shells

export scriptify

scriptify(s::Sbatch) = join(["#$(prefix(s)) $(string(dir, long = true, with_value = true))" for dir in s.directives], '\n')
scriptify(modules::AbstractVector{<: SystemModule}) = join(["module load $(string(m))" for m in modules], '\n')
scriptify(s::Shell) = string(s.path)

end
