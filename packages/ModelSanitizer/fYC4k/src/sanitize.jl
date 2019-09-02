"""
    Sanitize a model.

    If your model is stored in `m` and your data are stored in `x1`,
    `x2`, `x3`, etc. then you can sanitize your model with:
    ```julia
    sanitize!(Model(M), Data(x1), Data(x2), Data(x3), ...)
    ```
"""
function sanitize! end

function sanitize!(m::Model{T}; kwargs...)::Model{T} where T
    sanitize!(m, Vector{Data}(undef, 0); kwargs...)
    return m
end

function sanitize!(m::Model{T}, varargs...; kwargs...)::Model{T} where T
    sanitize!(m, convert(Vector{Data}, collect(varargs)); kwargs...)
    return m
end

function sanitize!(m::Model{T}, data::Vector{Data}; kwargs...)::Model{T} where T
    _sanitize!(m, data, _elements(data); kwargs...)
    return m
end

function sanitize!(location::ForceSanitize, varargs...; kwargs...)
    sanitize!(convert(Vector{ForceSanitize}, vcat(location, collect(varargs))); kwargs...)
    return location, varargs...
end

function sanitize!(locations::Vector{ForceSanitize}; kwargs...)
    _sanitize!(locations; kwargs...)
    return locations
end

function _sanitize!(locations::Vector{ForceSanitize}; kwargs...)
    for i = 1:length(locations)
        if isassigned(locations, i)
            _sanitize!(locations[i]; kwargs...)
        end
    end
    return locations
end

function _sanitize!(location::ForceSanitize; kwargs...)
    zero!(location.loc; kwargs...)
    return location
end

function _sanitize!(m::T, data::Vector{Data}, elements::_DataElements; kwargs...)::T where T
    _sanitize_fields!(m, data, elements)
    _sanitize_iterable!(m, data, elements)
    _sanitize_indexable!(m, data, elements)
    return m
end

function _sanitize_fields!(m::T, data::Vector{Data}, elements::_DataElements; kwargs...)::T where T
    for field in fieldnames(T)
        _sanitize!(_get_property(m, field), data, elements)
    end
    return m
end

function _sanitize_iterable!(m::T, data::Vector{Data}, elements::_DataElements; kwargs...)::T where T
    if _is_iterable(T)
        try
            for object in m
                try
                    _sanitize!(object, data, elements)
                catch ex_inner
                    # showerror(stderr, ex)
                    # Base.show_backtrace(stderr, catch_backtrace())
                    # @debug("Ignoring exception [inner]", exception=(ex, catch_backtrace()))
                end
            end
        catch ex_outer
            # showerror(stderr, ex)
            # Base.show_backtrace(stderr, catch_backtrace())
            # @debug("Ignoring exception [outer]", exception=(ex, catch_backtrace()))
        end
    end
    return m
end

function _sanitize_indexable!(m::T, data::Vector{Data}, elements::_DataElements; kwargs...)::T where T
    if _has_isassigned(T)
        _sanitize_indexable_with_check_assigned!(m, data, elements)
    else
        _sanitize_indexable_without_check_assigned!(m, data, elements)
    end
    return m
end

function _sanitize_indexable_with_check_assigned!(m::T, data::Vector{Data}, elements::_DataElements; kwargs...)::T where T
    if _is_indexable(T)
        for i = 1:length(m)
            if isassigned(m, i)
                _sanitize!(m[i], data, elements)
            end
        end
    end
    return m
end

function _sanitize_indexable_without_check_assigned!(m::T, data::Vector{Data}, elements::_DataElements; kwargs...) where T
    if _is_indexable(T)
        for i = 1:length(m)
            try
                _sanitize!(m[i], data, elements)
            catch
            end
        end
    end
    return m
end
