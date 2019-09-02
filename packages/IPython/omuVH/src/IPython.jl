"""
Launch IPython in Julia

## Usage

Run `using IPython` and then type `.` in empty `julia>` prompt or run
`IPython.start_ipython()`.  If you are using IPython 7.0 or above, you
can switch back to Julia REPL by `backspace` or `ctrl-h` key (like
other REPL modes).  For older versions of IPython, exiting IPython as
usual (e.g., `ctrl-d`) brings you back to the Julia REPL.  Re-entering
IPython keeps the previous state.  Use pre-defined `Main` object to
access Julia namespace from IPython.  Use `py"..."` string macro to
access Python namespace from Julia.

**Note:**
First launch of IPython may be slow.

# Examples
```
julia> xs = [1, 2, 3];  # some Julia variable

julia> using IPython

julia> IPython.start_ipython()  # or type . (a dot)

In [1]: Main.xs  # accessing Julia variable
array([1, 2, 3], dtype=int64)

In [2]: Main.xs += 10

In [3]: ε = "varepsilon"

In [4]: exit()  # or type backspace or ctrl-d

julia> xs
3-element Array{Int64,1}:
 11
 12
 13

julia> using PyCall

julia> py"ε"  # you can access Python variables with PyCall.@py_str macro
"varepsilon"

julia> py"ϵ"  # but be careful when using Unicode!
"varepsilon"
```
"""
module IPython

using Compat
using Compat: @warn, @info
include("julia_api.jl")
include("core.jl")
include("convenience.jl")
include("julia_repl.jl")

end # module
