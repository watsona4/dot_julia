# Package contents
This package follows the official 
[guidelines](https://docs.julialang.org/en/latest/manual/packages/#Creating-a-new-Package-1) 
for Julia package layout and contents. 

## File locations after installation
After installation, the package contents will be installed inside the hidden 
`~/.julia/` folder in the home directory.  The path can be printed from inside 
the `julia` shell by the command:

```julia-repl
julia> Pkg.dir("Granular")
"/Users/ad/.julia/v0.7/Granular"
```

The above output will be different for different platforms and Julia versions. 
In order to open this directory on macOS, run the following command:

```julia-repl
julia> run(`open $(Pkg.dir("Granular"))`)
```

On Linux, use the following command:

```julia-repl
julia> run(`xdg-open $(Pkg.dir("Granular"))`)
```

The above commands will open the directory containing all of the Granular.jl 
components. The main component of Granular.jl is the source code contained in 
the [src/](https://github.com/anders-dc/Granular.jl/tree/master/src) directory. 
The [docs/](https://github.com/anders-dc/Granular.jl/tree/master/docs) 
directory contains the documentation source via Markdown files.  The online 
documentation is generated from these files via 
[Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/) by the 
[docs/make.jl](https://github.com/anders-dc/Granular.jl/blob/master/docs/make.jl) 
script.  The documentation consists of manual pages, as well as auto-generated 
API reference that is parsed from the documentation of the Granular.jl source 
code ([src/](https://github.com/anders-dc/Granular.jl/tree/master/src) 
directory).

## Example scripts
The [examples](https://github.com/anders-dc/Granular.jl/tree/master/examples) 
directory contains several annotated examples, which are useful for getting 
started with the Granular.jl package and for demonstrating some of its 
features.  The examples are generally heavily annotated with comments to 
illustrate the purpose of the included commands.

The examples can be run by either navigating to the examples directory from the 
command line, and launching them with a command like `julia -e logo.jl`, or 
directly from the julia shell with:

```julia-repl
julia> include("$(Pkg.dir("Granular"))/examples/logo.jl")
```

It is recommended that the source code of the examples is inspected beforehand.
