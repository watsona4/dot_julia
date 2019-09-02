#=
    JupyterParam.jl
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

module JupyterParameters

export jjnbparam

using DataStructures
using JSON
using ArgParse
using IJulia
using Conda

"""
install jupyter (IF NEEDED) via conda
would only need to be done the first time
"""
function install_jupyter()
    jupyter = IJulia.JUPYTER
    if jupyter == "jupyter" || jupyter == "jupyter.exe" # look in PATH
        jupyter = Sys.which(IJulia.exe("jupyter"))
        if jupyter === nothing
            jupyter = joinpath(Conda.SCRIPTDIR, IJulia.exe("jupyter"))
        end
    end
    if !Sys.isexecutable(jupyter)
        if dirname(jupyter) == abspath(Conda.SCRIPTDIR)
           printstyled( """
                        Couldn't find jupyter, installing via Conda . . .

                        This is a one time event (per JupyterParam install) at most
                        You shouldn't see this message again and if you do please report it to the developer
                        """
                      , color = :cyan
                      )
           Conda.add("jupyter")
        else
            error("$jupyter is not installed, cannot run $subcommand")
        end
    end
end

"""
search the jjnb for the cell taged with "parameters"
"""
function find_parameters_cell( jsondict:: OrderedDict
                             )         :: Int
    param_cell = Vector{Int}(undef,0)
    
    for (i,cell) in enumerate(jsondict["cells"])
        if haskey(cell["metadata"], "tags")
            if "parameters" in cell["metadata"]["tags"]
                push!(param_cell, i)
            end
        end
    end

    if length(param_cell) == 0
        error("Found NO cells containing the tag \"parameters\"")
    end
    if length(param_cell) > 1
        error("Found multiple cells containing the tag \"parameters\"")
    end

    return param_cell[1]
end

function view_source( jsondict :: OrderedDict
                    , cellnum  :: Int
                    )
    return view(jsondict["cells"][cellnum]["source"],:)
end

"""
replace the default values with the passed values and return the jsondict
"""
function paramitify_jjnb( infile        :: String
                        , passed_params :: Dict
                        )               :: OrderedDict

    jsondict = JSON.parsefile(infile, dicttype=OrderedDict)
    pcellnum = find_parameters_cell(jsondict)

    pcell = view_source(jsondict, pcellnum)

    default_params = OrderedDict()
    for (i,line) in enumerate(pcell)
        if (line[1] == '#') | all(isspace,line)
            default_params[string('#',i)] = line
        elseif (line[1] == ';')
            default_params[string(';',i)] = line
        else
            varname_val = strip.(split(line, "="))
            @assert( length(varname_val) == 2
                   , """
                     Check the parameters cell in the notebook. Expected something of the form
                         varname = varval
                     Instead we got
                         $varname_val
                     """
                   )
            varname, varval = varname_val
            default_params[varname] = varval
        end
    end

    for (i,defpar) in enumerate(default_params)
        k,defv = defpar
        if !((k[1] == '#') || (k[1] == ';'))

            if k in keys(passed_params)
                v = passed_params[k]

                # check if we need to put quotes around the value
                if defv[1] == '"'
                    v = string('"',v,'"')
                end

                line = string(k, " = ", v)

                if pcell[i][end] == '\n'
                    line = string(line, '\n')
                end

                pcell[i] = line
            end
        end
    end

    return jsondict
end

function get_kernels()
    return readdir(IJulia.kerneldir())
end

function jjnbparam(args :: AbstractVector{String})
    if length(args) < 4
        error("""
              Requires at least: infile outfile --var value
              Received: $args
              if you want to overwrite the infile (NOT RECOMMENDED) then pass:
                  infile infile --var value
              """
             )
    end

    infile  = popfirst!(args)
    outfile = popfirst!(args)
    if !(occursin(".ipynb",infile) && occursin(".ipynb",outfile))
        error("""
              Please check your arguments! You need to pass at least infile and outfile.
              Also they need to have the correct extension (.ipynb)
              Currently we have
                infile = $infile
                outfile = $outfile
              """
             )
    end

    nargs = div(length(args), 2)

    s = ArgParseSettings()
    for i in 1:2:length(args)
        arg = args[i]
        @assert( arg[1:2] == "--"
               , "there appears to be an error in the passed parameter list: $args"
               )
        add_arg_table(s, args[i])
    end
    passed_params = parse_args(args, s)

    install_jupyter()
    jnb_cmd = IJulia.find_jupyter_subcommand("nbconvert")

    push!(jnb_cmd.exec, "--to=notebook", "--execute", "--ExecutePreprocessor.allow_errors=True")
    if "timeout" in keys(passed_params)
        push!(jnb_cmd.exec, "--ExecutePreprocessor.timeout=$(passed_params["timeout"])")
        delete!(passed_params, "timeout")
    end
    if "kernel_name" in keys(passed_params)
        kernel = passed_params["kernel_name"]
        kernels = get_kernels()
        if !(kernel in kernels)
            error("""
                  The kernel you requested doesn't seem to be present in the listing.
                  The availible kernels are:
                  $kernels
                  """
                 )
        end
        push!(jnb_cmd.exec, "--ExecutePreprocessor.kernel_name=$kernel")
        delete!(passed_params, "kernel_name")
    end

    open(outfile, "w") do outf
        printstyled("Starting paramitification of ", infile, "...\n", color = :cyan)
        jsondict = paramitify_jjnb(infile, passed_params)
        printstyled("Successful replacement of parameters!\n", color = :green)
        JSON.print(outf, jsondict, 1)
        printstyled("Wrote ", outfile, '\n', color = :green)
    end

    push!(jnb_cmd.exec, outfile, "--output", outfile)
    printstyled("Running ", jnb_cmd.exec, '\n', color = :cyan)
    run(jnb_cmd)
end

function jjnbparam()
    args = copy(ARGS)
    jjnbparam(args)
end

end
