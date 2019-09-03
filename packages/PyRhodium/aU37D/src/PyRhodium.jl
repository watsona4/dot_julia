module PyRhodium

using PyCall
using PyPlot
using IterableTables
using Distributions
using DataFrames
using DataStructures

export
    Model, Parameter, Response, Lever, RealLever, IntegerLever, CategoricalLever, 
    PermutationLever, SubsetLever, Constraint, Brush, DataSet, pandas_dataframe,
    named_tuple, named_tuples, optimize, scatter2d, scatter3d, pairs, 
    parallel_coordinates, apply, evaluate, sample_lhs, set_parameters!, 
    set_levers!, set_responses!, set_constraints!, set_uncertainties!,
    Prim, PrimBox, find_box, find_all, show_tradeoff, stats, limits,
    Cart, show_tree, print_tree, save, save_pdf, save_png,
    Sensitivity, SAResult, sa, oat, plot, plot_sobol, find

const rhodium = PyNULL()
const prim = PyNULL()
const pd = PyNULL()
const seaborn = PyNULL()

function __init__()
    copy!(rhodium, pyimport("rhodium"))
    copy!(prim, pyimport("prim"))
    copy!(pd, pyimport("pandas"))
    copy!(seaborn, pyimport("seaborn"))

    # TBD: see if it works to simply call __init__(function) without storing the julia function
    py"""
    from rhodium import *
    class JuliaModel(Model):
        
        def __init__(self, function, **kwargs):
            super(JuliaModel, self).__init__(self._evaluate)
            self.j_function = function
            
        def _evaluate(self, **kwargs):
            result = self.j_function(**kwargs)
            return result
    """

    # Create a Python class that can store the SAResult (a subclass of dict) in 
    # an instance var so we can access it without conversion. Otherwise, PyCall 
    # converts it to a Dict and we can't use it as an argument to the plot routines
    # that are methods of rhodium.SARsult.
    py"""
    import rhodium

    class SAResultContainer(object):
        def __init__(self, sa_result):
            self.sa_result = sa_result

    def my_sa(*args, **kwargs):
        sa_result = rhodium.sa(*args, **kwargs)
        return SAResultContainer(sa_result)
    """    
end

include("core.jl")
include("prim.jl")
include("cart.jl")
include("sa.jl")

end # module
