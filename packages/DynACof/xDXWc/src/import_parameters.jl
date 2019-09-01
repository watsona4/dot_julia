"""
    import_parameters(path::String,Names)

Import the model parameters from local files, or from default values in the parameter structures: 
- constants
- site
- soil
- coffee
- tree (for a simulation of a monocrop coffee plantation, use an empty string for the tree, see example)

# Arguments 
- `path::String`: The path to the parameter files folder. If `path= "package"`, take the default files from the package
- `Names::NamedTuple{(:constants, :site, :meteo, :soil, :coffee, :tree),NTuple{6,String}}`: list the file names. 

# Details
For the full list of parameters and the format of the parameter files, see [`site`](@ref).

# Return
A list of all input parameters for DynACof

# Examples
```julia
# Default from package: 
import_parameters("package")

# Reading it from local files: 
import_parameters("D:/parameter_files",(constants= "constants.jl",site="site.jl",meteo="meteorology.txt",soil="soil.jl",coffee="coffee.jl",tree="tree.jl"))

# For a coffee monocrop (without shade trees)
import_parameters("D:/parameter_files",(constants= "constants.jl",site="site.jl",meteo="meteorology.txt",soil="soil.jl",coffee="coffee.jl",tree=""))
```
"""
function import_parameters(path::String= "package",Names= (constants= "constants.jl",site="site.jl",meteo="meteorology.txt",soil="soil.jl",coffee="coffee.jl",tree="tree.jl"))

    if path == "package"
        paths= repeat(["package"],length(Names))
        paths_names= keys(Names)
        paths = NamedTuple{paths_names}(paths)       
    else
        paths= map(x -> normpath(string(path,"/",x)),Names)
    end

    if Names.tree==""
        # This code is more elegant but eval only works at REPL. Keep the other one until I find a solution.
        # params= map(x -> :(struct_to_tuple($x, read_param_file($(Meta.parse(":$x")),paths.$x))),param_struct)
        # eval_params= map(eval, params)
        params= map((x,y) -> struct_to_tuple(y, read_param_file(x,getfield(paths,x))),
                    [:constants,:site, :soil, :coffee],
                    (constants,site,soil,coffee))
        params= merge(params...,(Tree_Species= "No_Shade",))
    else
        params= map((x,y) -> struct_to_tuple(y, read_param_file(x,getfield(paths,x))),
                    [:constants,:site, :soil, :coffee, :tree],
                    (constants,site,soil,coffee,tree))
        params= merge(params...)
    end
    
    return params
end


"""
    read_param_file(structure::Symbol,filepath::String="package")

Read DynACof parameter files and create the structure according to its structure.
If parameters are missing from the file, the structure is filled with the default values.

# Arguments
- `structure::Int64`: The structure type. Must be one of `constants`, `site`, `soil`, `coffee`, `tree`
- `filepath::Float64`: The path to the parameter file

# Return
The corresponding structure with the values read from the parameter file.

# Examples
```julia
julia> read_param_file(:constants)
constants(0.0010130000000000007, 0.622, 101.325, 0.5, 9.81, 287.0586, 8.314, 273.15, 0.41, 1.0000000000000006e-6, 1367.0, 5.670367e-8, 0.018, 4.57, 2.45, 0.4,2.15e-5)

julia> read_param_file(:site)
DynACof.site("Aquiares", "1979/01/01", 9.93833, -83.72861, 6, 1040.0, 25.0, 0.58, 0.144)
```
"""
function read_param_file(structure::Symbol,filepath::String="package")
    if basename(filepath)=="package"
        return eval(:($structure()))
    else
        params= evalfile(filepath)
        b= map((x,y) -> :($x = $y),collect(keys(params)),collect(values(params)))
        return eval(:($structure(;$(b...))))
    end
end
