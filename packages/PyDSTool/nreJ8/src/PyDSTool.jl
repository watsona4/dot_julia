__precompile__()

module PyDSTool

using PyCall, DataStructures, DiffEqBase, RecipesBase, LinearAlgebra

const ds = PyNULL()

function __init__()
  try
    copy!(ds, pyimport_conda("PyDSTool", "pydstool", "conda-forge"))
    return
  catch err
    if err isa PyCall.PyError
      # A dirty hack to force importing PyDSTool:
      # https://github.com/JuliaDiffEq/PyDSTool.jl/issues/5
      #
      # At this point, we assume that "import PyDSTool" was failed due
      # to the bug in how it checks SciPy version number.  We
      # workaround it by monkey-patching `scipy.__version__` while
      # importing PyDSTool.  We make ./_pydstool_jl_hack.py importable
      # and execute it by importing it.
      pushfirst!(PyVector(pyimport("sys")["path"]), @__DIR__)
      pyimport("_pydstool_jl_hack")
    else
      rethrow()
    end
  end
  copy!(ds, pyimport_conda("PyDSTool", "pydstool", "conda-forge"))
end

include("constants.jl")
include("ode_construct_solve.jl")
include("bifurcation.jl")

export ds, build_args

export PYDSTOOL_CURVE_CLASSES, ALL_POINT_TYPES

export set_name,set_ics,set_pars, set_vars, set_tdata,set_fnspecs,
       set_tdomain, interpert_pts, build_ode, solve_ode,bifurcation_curve

export find_changes
end
