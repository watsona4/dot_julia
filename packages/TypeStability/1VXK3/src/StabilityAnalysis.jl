
export check_function, check_method
export StabilityReport, is_stable

"""
    check_function(func, signatures, acceptable_instability=Dict())

Check that the function is stable under each of the given signatures.

Return an array of method signature-`StabilityReport` pairs from
[`check_method`](@ref).
"""
function check_function(func, signatures, acceptable_instability=Dict{Symbol, Type}())
    result = Tuple{Any, StabilityReport}[]
    for params in signatures
        push!(result, (params, check_method(func, params, acceptable_instability)))
    end
    result
end

"""
    check_method(func, signature, acceptable_instability=Dict())

Create a `StabilityReport` object describing the type stability of the method.is

Compute non-concrete types of variables and return value, returning them in
a [`StabilityReport`](@ref) Object

`acceptable_instability`, if present, is a mapping of variables that are
allowed be non-concrete types.  `get` is called with the mapping, the
variable's symbol and `Bool` to get the variable's allowed type.  Additionally,
the return value is checked using `:return` as the symbol.
"""
function check_method(func, signature, acceptable_instability=Dict{Symbol, Type}())
    #Based off julia's code_warntype and show_ir

    unstable_vars_list = Array{Tuple{Symbol, Type}, 1}(undef, 0)

    function var_is_stable(typ, name)
        (isconcretetype(typ) && typ != Core.Box) ||
            begin
                (typ <: get(acceptable_instability, name, Bool))
            end
    end

    if VERSION < v"0.7.0-"
        code = code_typed(func, signature)

        function scan_exprs!(used, exprs)
            for ex in exprs
                if isa(ex, Slot)
                    used[ex.id] = true
                elseif isa(ex, Expr)
                    scan_exprs!(used, ex.args)
                end
            end
        end
    else
        code = code_typed(func, signature; optimize=false)
    end

    if length(code) == 0
        error("No methods found for $func matching $signature")
    elseif length(code) != 1
        warn("Mutliple methods for $func matching $signature")
    end

    for (src, rettyp) in code
        if !var_is_stable(rettyp, :return)
            push!(unstable_vars_list, (:return, rettyp))
        end
        slotnames = Base.sourceinfo_slotnames(src)
        used_slotids = falses(length(slotnames))

        if VERSION < v"0.7.0-"
            scan_exprs!(used_slotids, src.code)
            types = src.slottypes
        else
            stmts = src.code
            ssatypes = src.ssavaluetypes
            types = Vector{Type}(undef, length(slotnames))
            fill!(types, Union{})
            for idx in eachindex(stmts)
                if isa(stmts[idx], Expr) && stmts[idx].head == :(=)
                    if isa(ssatypes[idx], Core.Compiler.Const)
                        typ = typeof(ssatypes[idx].val)
                    else
                        typ = ssatypes[idx]
                    end
                    slotidx = stmts[idx].args[1].id
                    types[slotidx] = Union{types[slotidx], typ}
                    used_slotids[slotidx] = true
                end
            end
        end

        if isa(types, Vector)
            for i = 1:length(slotnames)
                if used_slotids[i]
                    name = Symbol(slotnames[i])
                    typ = types[i]
                    if !var_is_stable(typ, name)
                        push!(unstable_vars_list, (name, typ))
                    end

                    #else not an issue for type stability
                end
            end
        else
            warn("Can't access types of CodeInfo")
        end
    end

    return StabilityReport(unstable_vars_list)
end

"""
    StabilityReport()
    StabilityReport(unstable_variables::Vector{Tuple{Symbol, Type}})

Holds information about the stability of a method.

If `unstable_vars` is present, set the fields.  Otherwise, creates an empty set.

See [`is_stable`](@ref)
"""
struct StabilityReport
    "A list of unstable variables and their values"
    unstable_variables::Dict{Symbol, Type}

    StabilityReport(v::Dict{Symbol, Type}) = new(v)
end

StabilityReport() = StabilityReport(Dict{Symbol, Type}())
StabilityReport(vars) = StabilityReport(Dict{Symbol, Type}(vars))

function Base.:(==)(x::StabilityReport, y::StabilityReport)
    x.unstable_variables == y.unstable_variables
end

"""
    is_stable(report::StabilityReport)::Bool
    is_stable(reports::AbstractArray{StabilityReport})::Bool
    is_stable(reports::AbstractArray{Tuple{<:Any, StabilityReport}})::Bool

Check if the given [`StabilityReport`](@ref)s don't have any unstable types.
"""
is_stable(report::StabilityReport) = length(report.unstable_variables) == 0
is_stable(reports::AbstractArray{StabilityReport}) = all(is_stable.(reports))
is_stable(reports::Set{StabilityReport}) = all(is_stable.(reports))
is_stable(reports::AbstractArray{<:Tuple{<:Any, StabilityReport}}) = all(map(pair->is_stable(pair[2]), reports))

"""
    stability_warn(func_name, report::AbstractArray{Tuple{<:Any,StabilityReport}})

Displays warnings about the function if any of the reports are not stable
"""
function stability_warn(func_name, reports)
    for (args, report) in reports
        if !is_stable(report)
            println(stderr, "$func_name($(join(args, ", "))) is not stable")
            for (var, typ) in report.unstable_variables
                println(stderr, "  $var is of type $typ")
            end
        end
    end
end
