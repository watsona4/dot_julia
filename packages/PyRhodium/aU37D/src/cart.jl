#
# CART-related types and functions
#

struct Cart <: Wrapper
    pyo::PyObject

    function Cart(x::DataSet, y::Vector; threshold=nothing, threshold_type=">",
                         include=nothing, exclude=nothing, kwargs...)

        pandasDF = pandas_dataframe(x; include=include, exclude=exclude)

        cart = rhodium.Cart(pandasDF, y; threshold=threshold, threshold_type=threshold_type,
                            kwargs...)
        new(cart)
    end
end

function show_tree(c::Cart; kwargs...)
    fig = c.pyo.show_tree(kwargs...)
    return fig
end

function print_tree(c::Cart; coi=nothing, all=true, kwargs...)
    c.pyo.print_tree(;coi=coi, all=all, kwargs...)
    nothing
end

function save(c::Cart, file, format="png"; kwargs...)
    c.pyo[:save](file, format; kwargs...)
end

function save_pdf(c::Cart, file; feature_names=nothing, kwargs...)
    save(c, file, "pdf"; feature_names=feature_names, kwargs...)
end

function save_png(c::Cart, file; feature_names=nothing, kwargs...)
    save(c, file, "png"; feature_names=feature_names, kwargs...)
end