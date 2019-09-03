#
# PRIM-related types and functions
#

struct PrimBox <: Wrapper
    pyo::PyObject

    function PrimBox(pyo::PyObject)
        new(pyo)
    end
end

function Base.show(io::IO, box::PrimBox)
    print(io, box.pyo.__str__())
end

function show_tradeoff(box::PrimBox)
    fig = pycall(box.pyo.show_tradeoff, PyObject)
    return fig
end

function show_details(box::PrimBox, fig=nothing)
    pycall(box.pyo[:show_details], PyObject, fig=fig)
    nothing
end

stats(box::PrimBox) = box.pyo[:stats]

limits(box::PrimBox) = box.pyo[:limits]

Base.length(box::PrimBox) = box.pyo[:__len__]()

# From original python doc:
# x : a matrix-like object (pandas.DataFrame, numpy.recarray, etc.)
# the independent variables [can be anything convertible to a DataFrame]
#
# y : a list-like object, the column name (str), or callable
# the dependent variable either provided as a list-like object
# classifying the data into cases of interest (e.g., False/True),
# a list-like object storing the raw variable value (in which case
# a threshold must be given), a string identifying the dependent
# variable in x, or a function called on each row of x to compute the
# dependent variable
struct Prim <: Wrapper
    pyo::PyObject
    
    function Prim(x::DataSet, y::Vector; 
                  threshold=nothing, threshold_type=">",
                  obj_func=prim.lenient1, 
                  peel_alpha=0.05, paste_alpha=0.05, mass_min=0.05, 
                  include=nothing, exclude=nothing, coi=nothing)

        pandasDF = pandas_dataframe(x; include=include, exclude=exclude)

        # Convert y into Vector{Bool} by matching category of interest
        # Note that classification and coi can be strings or symbols,
        # as long as they're consistent (i.e., 'in' and '==' work.)
        if coi != nothing
            if coi isa AbstractArray
                y = [value in coi for value in y]
            else
                y = (y .== coi)
            end
        end      

        prim = rhodium.Prim(pandasDF, y;
                            threshold=threshold, threshold_type=threshold_type,
                            obj_func=obj_func, peel_alpha=peel_alpha, paste_alpha=paste_alpha, 
                            mass_min=mass_min) # include=include, exclude=exclude, coi=coi)
        return new(prim)
    end
end

function find_box(p::Prim)
    pyo = pycall(p.pyo.find_box, PyObject)
    return PrimBox(pyo)
end

function find_all(p::Prim)
    boxes = pycall(p.pyo[:find_all], PyVector)
    return boxes
end

# Python code says this needs to be tested...
"""
    perform_pca(p::Prim, subsets::Dict=nothing, exclude=nothing)

Pre-process the data by performing a pca based rotation on it.

Arguments:
    subsets: optional dict with group name as key and a list of 
             uncertainty names as values. If this is used, a
             constrained PCA-PRIM is executed 
             (N.B. the list of uncertainties should not contain 
             categorical uncertainties. 
    exclude: optional list of str, the uncertainties that should
             be excluded from the rotation
"""
function perform_pca(p::Prim, subsets::Dict=nothing, exclude=nothing)
    p.pyo[:perform_pca](;subsets=subsets, exclude=exclude)
end