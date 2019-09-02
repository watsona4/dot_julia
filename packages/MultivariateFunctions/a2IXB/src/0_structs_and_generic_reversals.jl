import Base.+, Base.-, Base./, Base.*, Base.^
import Base.sort, Base.convert, Base.zero
import SchumakerSpline.evaluate
using Dates
abstract type MultivariateFunction end
"""
    PE_Unit(b_::Float64, base_::Float64, d_::Int)
    PE_Unit(b_::Float64, base_::Date, d_::Int)

This creates a PE_Unit which has a functional form of exp(b_(x-base_)) (x-base_)^d.
They cannot be used in any productive way by themselves but are needed to construct a PE_Function.
An empty PE_Unit (which might be used to create a constant PE_Function) can be created by PE_Unit().
"""
struct PE_Unit
    b_::Float64
    base_::Float64
    d_::Integer
    function PE_Unit()
        return new(0.0,0.0,0)
    end
    function PE_Unit(b_::Float64, base_::Float64, d_::Int)
        if d_ < 0
            error("Negative polynomial powers are not supported by this package")
            # These are banned due to the complications for calculus. Most
            # divisions are not allowed for the same reason.
        elseif (b_ ≂ 0.0) & (d_ == 0)
            return new(0.0,0.0,0)
        else
            return new(b_,base_,d_)
        end
    end
    function PE_Unit(b_::Float64, base_::Date, d_::Int)
        numeric_base = years_from_global_base(base_)
        return PE_Unit(b_, numeric_base, d_)
    end
end


function evaluate(unit::PE_Unit, x::Float64)
    diff = x - unit.base_
    return exp(unit.b_ * diff) * (diff)^unit.d_
end

const default_symbol = :default

"""
    PE_Function(multiplier_::Float64, functions_::Dict{Symbol,PE_Unit})

This is the main constructor for a PE Function. The functional form of the function is the multiplier multiplied by all PE_Units.

For instance the PE_Function created by PE_Function(6.0, Dict([:x, :y] .=> [PE_Unit(1.0,1.0,1), PE_Unit(0.0,2.0,4)]))
has a functional form of 6 (x-1) exp(x-1) (y-2)^4

The following convenience functions create a PE_Function where there is only one variable (with a symbol :default).
    PE_Function(multiplier_::Float64,b_::Float64, base_::Float64, d_::Int)
    PE_Function(multiplier_::Float64,b_::Float64, base_::Date, d_::Int)
The following convenience function creates a PE_Function where there are no variables and hence it is constant:
    PE_Function(num::Float64 = 0.0)
"""
struct PE_Function <: MultivariateFunction
    multiplier_::Float64
    units_::Dict{Symbol,PE_Unit}
    function PE_Function(num::Float64 = 0.0)
        return new(num,Dict{Symbol,PE_Unit}())
    end
    function PE_Function(multiplier_::Float64, units_::Dict{Symbol,PE_Unit})
        for k in keys(units_)
            if (units_[k].b_ ≂ 0.0) & (units_[k].d_ == 0)
                pop!(units_, k)
            end
        end
        if multiplier_ ≂ 0.0
            return PE_Function(0.0)
        end
        return new(multiplier_, units_)
    end
    function PE_Function(multiplier_::Float64, units_::Dict{Symbol,Tuple{Float64,PE_Unit}})
        new_mult = multiplier_
        new_dict = Dict{Symbol,PE_Unit}()
        for k in keys(units_)
            new_mult    = new_mult * units_[k][1]
            new_dict[k] = units_[k][2]
        end
        return PE_Function(new_mult, new_dict)
    end
    function PE_Function(multiplier_::Float64,b_::Float64, base_::Float64, d_::Int)
        unit = PE_Unit(b_, base_, d_)
        units_ = Dict{Symbol,PE_Unit}(default_symbol .=> [unit])
        return PE_Function(multiplier_, units_)
    end
    function PE_Function(multiplier_::Float64,b_::Float64, base_::Date, d_::Int)
        base_as_float = years_from_global_base(base_)
        return PE_Function(multiplier_, b_, base_as_float, d_)
    end
end
Base.broadcastable(e::PE_Function) = Ref(e)

function get_bases(f::PE_Function)
    dic = Dict{Symbol,Float64}()
    for k in keys(f.units_)
        dic[k] = f.units_[k].base_
    end
    return dic
end

"""
    rebadge(f::PE_Function, mapping::Dict{Symbol,Symbol})
    can be used to change the names of the variables in a MultivariateFunction.
"""
function rebadge(f::PE_Function, mapping::Dict{Symbol,Symbol})
    original_units = deepcopy(f.units_)
    units_ = Dict{Symbol,PE_Unit}()
    for k in keys(mapping)
        if k in keys(f.units_)
            unit = pop!(original_units,k)
            units_[mapping[k]] = unit
        end
    end
    for k in keys(original_units)
        unit = pop!(original_units,k)
        units_[k] = unit
    end
    return PE_Function(f.multiplier_, units_)
end

function rebadge(f::MultivariateFunction, new_symbol::Symbol)
    underlying = underlying_dimensions(f)
    if length(underlying) > 1
        mapping = Dict{Symbol,Symbol}(collect(underlying) .=> [new_symbol])
        return rebadge(f, mapping)
    else
        error("It is not possible to rebadge multivariate functions unless a full mapping dictionary is input to the rebadge function.")
    end
end

"""
    evaluate(f::MultivariateFunction, coordinates::Dict{Symbol,Float64})
    evaluates a function at coordinates.

    For univariate functions with a variable name of :default (such as those created by PE_Function's convenience functions)
    evaluation can take place with no dictionary:
    evaluate(f::MultivariateFunction, coordinate::Float64)
"""
function evaluate(f::PE_Function, coordinates::Dict{Symbol,Float64})
    val = f.multiplier_
    units = deepcopy(f.units_)
    for k in intersect(keys(units), keys(coordinates))
        unit = pop!(units, k)
        val = val * evaluate(unit, coordinates[k])
    end
    if length(units) == 0
        return val
    else
        return PE_Function(val, units)
    end
end

"""
    underlying_dimensions(f::MultivariateFunction)
    Returns a set containing all of the variables upon which f depends.
"""
function underlying_dimensions(a::Missing)
    return Set{Symbol}()
end
function underlying_dimensions(a::PE_Function)
    return Set(keys(a.units_))
end

function evaluate(f::MultivariateFunction, coordinate::Float64; dim_name::Symbol = default_symbol)
    return evaluate(f, Dict{Symbol,Float64}(dim_name => coordinate))
end
function evaluate(f::MultivariateFunction, day::Date; dim_name::Symbol = default_symbol)
    coordinate = years_from_global_base(day)
    return evaluate(f, Dict{Symbol,Float64}(dim_name => coordinate))
end
"""
    Sum_Of_Functions(functions)

Creates a Sum_Of_Functions from an array of PE_Functions and/or Sum_Of_Functions.
The constructors for this type go through each input Sum_Of_Functions and takes out the contained PE_Functions (so unecessary nesting doesnt occur where a Sum_Of_Functions could contain another Sum_Of_Functions).
The constructors also aggregate PE_Functions where possible. For intance if two PE_Functions have the same PE_Units and differ in their multiplier these multipliers can be added.
The constructors also remove zero multiplier PE_Functions.
"""
struct Sum_Of_Functions <: MultivariateFunction
    functions_::Array{PE_Function,1}
    function Sum_Of_Functions(funs::Array{PE_Function,1})
        # This is O((n^2)/2). Ideally I could get O(n).
        functions = funs[(((p->p.multiplier_).(funs) .≂ 0.0) .== false)]
        len = length(functions)
        if len == 0
            return new(Array{PE_Function,1}())
        end
        equiv_class = Array{Int,1}(undef,len)
        equiv_class .= 0
        for i in 1:(len-1)
            f1 = functions[i]
            if equiv_class[i] == 0
                equiv_class[i] = maximum(equiv_class) + 1
                for j in (i+1):(len)
                    if equiv_class[j] == 0
                        f2 = functions[j]
                        if f1.units_ ≂ f2.units_
                            equiv_class[j] = equiv_class[i]
                        end
                    end
                end
            end
        end
        classes = unique(equiv_class)
        len = length(classes)
        functions_ = Array{PE_Function,1}(undef,len)
        for i in 1:len
            funcs = functions[equiv_class .== classes[i]]
            mult  = (p->p.multiplier_).(funcs)
            units = funcs[1].units_
            functions_[i] = PE_Function(sum(mult), units)
        end
        return new(functions_)
    end
    function Sum_Of_Functions(f::PE_Function)
        return new([f])
    end
    function Sum_Of_Functions(functions::Array{Sum_Of_Functions,1})
        flattened_array = vcat((p->p.functions_).(functions)...)
        return Sum_Of_Functions(convert(Array{PE_Function,1}, flattened_array))
    end
    function Sum_Of_Functions(functions)
        if length(functions) == 0
            ff = convert(Array{PE_Function,1}, [])
            return new(ff)
        else
            undefined_funcs  = functions[typeof.(functions) .== Missing  ]
            piecewise_funcs  = functions[typeof.(functions) .== MultivariateFunctions.Piecewise_Function]
            if length(undefined_funcs) > 0
                return Missing()
            elseif length(piecewise_funcs) > 0
                error("It is not possible to construct a sum of functions from a piecewise function.")
            end
            pe_funcs   = functions[typeof.(functions) .== MultivariateFunctions.PE_Function]
            sum_funcs  = functions[typeof.(functions) .== MultivariateFunctions.Sum_Of_Functions]
            pe_sum = Sum_Of_Functions(convert(Array{PE_Function,1}, pe_funcs))
            if length(sum_funcs) == 0
                return pe_sum
            else
                sum_array = vcat(pe_sum, sum_funcs)
                return Sum_Of_Functions(convert(Array{Sum_Of_Functions,1}, sum_array))
            end
        end
    end
end
Base.broadcastable(e::Sum_Of_Functions) = Ref(e)

function evaluate(f::Sum_Of_Functions, coordinates::Dict{Symbol,Float64})
    if length(f.functions_) > 0
        vals = evaluate.(f.functions_, Ref(coordinates))
        return sum(vals)
    else
        return 0.0
    end
end

function underlying_dimensions(a::Sum_Of_Functions)
    under = underlying_dimensions.(a.functions_)
    if length(under) == 0
        return Set{Symbol}()
    else
        return union(under...)
    end
end

function rebadge(f::Sum_Of_Functions, mapping::Dict{Symbol,Symbol})
    len = length(f.functions_)
    funcs = Array{PE_Function,1}(undef, len)
    for i in 1:len
        funcs[i] = rebadge(f.functions_[i], mapping)
    end
    return Sum_Of_Functions(funcs)
end

function convert(::Type{Sum_Of_Functions}, f::PE_Function)
    return Sum_Of_Functions(f)
end
function convert(::Type{Union{Missing,Sum_Of_Functions}}, f::PE_Function)
    return Sum_Of_Functions(f)
end
function convert(::Type{Union{Missing,Sum_Of_Functions}}, f::Missing)
    return f
end

"""
    Piecewise_Function(functions_::Array{Union{Missing,Sum_Of_Functions}}, thresholds_::OrderedDict{Symbol,Array{Float64,1}})

Creates a Piecewise_Function from a multidimensional array of Sum_Of_Functions and an ordered dict of thresholds. The xth dimension
in the thresholds dict corresponds to the xth dimension of the array of functions. A function can be lookuped up considering the thresholds and
then selecting from the array. For instance if the first dimension is denoted :y and it's thresholds are [-4.0,0.0,3.4] and we query at a point with
a :y coordinate of 2.7 then the function we look up will be from the file functions_[2, ...] where ... represents the coordinates the the other dimensions.
This is because 2.7 is greater than the second element of [-4.0,0.0,3.4] but less than the third.
If this piecewise function were to be queried at a :y coordinate of -5.0 then a missing value will be returned. To specify piecewise functions on an
unlimited domain the first element of the threshold can be set as -Inf. To set a limited domain on the upper end then add a Missing value to the functions_
array. Any other (ie interior) point can also be made undefined by putting a Missing() type into the functions_ array.

Note that Piecewise_Function works by assigning a Sum_Of_Functions to every region within the space defined by the thresholds_ dict. It is only possible to
specify a region as a hypercube however. More complex regions are not possible.

Note too that piecewise functions will scale poorly in high dimensions. If there are 10 dimensions and each has 4 elements in its threshold dict then
the array for the piecewise function will have more than one million entries. In cases where there are no interactions between dimensions it is more
efficient to use a Sum_Of_Piecewise_Functions object (which is basically an array of Piecewise Functions). For instance consider the following function:
f(x,y,z) = max(x,5) + max(y,3) + max(z,3)
We could code this as a piecewise function or as the sum of three piecewise functions. The three piecewise function implementation will contain fewer PE_Functions.
"""
struct Piecewise_Function <: MultivariateFunction
    # Here we use ints to represent the function i n each subcube of the space. This saves on size and computation in
    # cases where the same function is in more than one cuve.
    functions_::Array{Union{Missing,Sum_Of_Functions}}
    thresholds_::OrderedDict{Symbol,Array{Float64,1}}
    function Piecewise_Function(functions_::Array{Union{Missing,Sum_Of_Functions}}, thresholds_::OrderedDict{Symbol,Array{Float64,1}})
        if length(keys(thresholds_)) == length(size(functions_))
            return new(functions_, thresholds_)
        else
            error("In generating a Piecewise_Function, the number of threshold keys and the dimensionality of the function array must be the same.")
        end
    end
    function Piecewise_Function(functions_::Array{Sum_Of_Functions}, thresholds_::OrderedDict{Symbol,Array{Float64,1}})
        return Piecewise_Function(convert(Array{Union{Missing,Sum_Of_Functions}},  functions_), thresholds_)
    end
    function Piecewise_Function(functions_::Array, thresholds_::OrderedDict{Symbol,Array{Float64,1}})
        # This might catch alot of times where someone wants a piecewise function of a piecewise function.
        # The strategy here will be to build a piecewise function without the piecewise bits. Then loop over and add the piecewise bits to the first.
        piecewise_indices = findall(typeof.(functions_) .== MultivariateFunctions.Piecewise_Function)
        if length(piecewise_indices) == 0
            #converted_funcs = convert(Array{Union{Missing,Sum_Of_Functions}}, functions_)
            converted_funcs = convert(Array{Union{Missing,Sum_Of_Functions}}, functions_)
            return Piecewise_Function(converted_funcs, thresholds_)
        else
            pwFuncs = deepcopy(functions_[piecewise_indices])
            functions_[piecewise_indices] .= Sum_Of_Functions([PE_Function(0.0)])
            previous_piecewise = Piecewise_Function(convert(Array{Union{Missing,Sum_Of_Functions}}, functions_), thresholds_)
            for i in 1:length(pwFuncs)
                cube = get_function_cube(thresholds_, piecewise_indices[i])
                pw_small = Piecewise_Function(pwFuncs[i], cube, true)
                previous_piecewise = previous_piecewise + pw_small
            end
        end
        return previous_piecewise
    end
    function Piecewise_Function(f::Piecewise_Function, hypercube::Dict{Symbol,Tuple{Float64,Float64}}, zero_outside_cube::Bool = true)
        ks = collect(keys(f.thresholds_))
        for k in ks
            if !(k in keys(hypercube))
                hypercube[k] = (f.thresholds_[k][1],Inf)
            end
        end
        lower, upper = [Dict{Symbol,Float64}(ks .=> val) for val in transpose.(hcat.(getindex.((hypercube,),ks)...))]
        lower_point = get_point_coordinates(f, lower)
        upper_point = get_point_coordinates(f, upper)
        number_in_each_dimension = (upper_point .- lower_point)

        funcs = f.functions_[range.(lower_point,upper_point; step = 1)...]
        pad_start = Array{Bool,1}()
        pad_end = Array{Bool,1}()
        new_thresholds_ = OrderedDict{Symbol,Array{Float64,1}}()
        for i in 1:length(ks)
            k = ks[i]
            thres = f.thresholds_[k][lower_point[i]:upper_point[i]]
             if (-Inf < thres[1])  # thres cannot be higher based on how lower_point was made. They could be equal.
                 append!(pad_start, [true])
                 thres = vcat([-Inf], hypercube[k][1], thres[2:length(thres)])
            elseif (-Inf == thres[1]) & (thres[1] < hypercube[k][1])
                append!(pad_start, [true])
                thres = vcat([-Inf], hypercube[k][1], thres[2:length(thres)])
            elseif (-Inf == thres[1]) & (thres[1] == hypercube[k][1])
                append!(pad_start, [false])
            end
            if (hypercube[k][2] < Inf)  # thres cannot be higher based on how lower_point was made. They could be equal.
                append!(pad_end, [true])
                thres = vcat(thres, [hypercube[k][2]])
           else
               append!(pad_end, [false])
           end
           new_thresholds_[k] = thres
        end
        funcs_ = Array{Union{Missing,Sum_Of_Functions},length(f.thresholds_)}(undef, ((number_in_each_dimension .+ 1 .+ pad_start .+ pad_end)...))
        if zero_outside_cube
            funcs_ .= PE_Function(0.0)
        else
            funcs_ .= Missing()
        end
        funcs_[range.(1 .+ pad_start, pad_start .+ vcat(size(funcs)...)  ; step = 1)...] = funcs
        return Piecewise_Function(funcs_, new_thresholds_)
    end
    function Piecewise_Function(functions_::Array, starts::Array{Float64,1})
        thresholds_ = OrderedDict{Symbol,Array{Float64,1}}(default_symbol => starts)
        return Piecewise_Function(functions_, thresholds_)
    end
    function Piecewise_Function(functions_::Array, starts::Array{Date,1})
        starts_ = years_from_global_base.(starts)
        return Piecewise_Function(functions_, starts_)
    end
end
Base.broadcastable(e::Piecewise_Function) = Ref(e)

function rebadge(f::Missing, mapping::Dict{Symbol,Symbol})
    return missing
end

function rebadge(f::Piecewise_Function, mapping::Dict{Symbol,Symbol})
    funcs = rebadge.(f.functions_, Ref(mapping))
    new_thresholds = OrderedDict{Symbol,Array{Float64,1}}()
    thresholds = f.thresholds_
    for m in keys(thresholds)
        if m in keys(mapping)
            new_thresholds[mapping[m]] = thresholds[m]
        else
            new_thresholds[m] = thresholds[m]
        end
    end
    return Piecewise_Function(funcs, new_thresholds)
end

function get_function_cube(thresholds_::OrderedDict{Symbol,Array{Float64,1}}, ind )
    index = vcat(Tuple(ind)...)
    cube = Dict{Symbol,Tuple{Float64,Float64}}()
    ks = collect(keys(thresholds_))
    for i in 1:length(ks)
        k = ks[i]
        spot = index[i]
        if length(thresholds_[k]) > spot
            cube[k] = (thresholds_[k][spot] , thresholds_[k][spot+1])
        else
            cube[k] = (thresholds_[k][spot] , Inf)
        end
    end
    return cube
end

function get_point_coordinates(f::Piecewise_Function, coordinates::Dict{Symbol,Float64})
    labels = collect(keys(f.thresholds_))
    segment_coordinates = Array{Int,1}(undef,length(labels))
    for i in 1:length(labels)
        dimen = labels[i]
        segment_coordinates[i] = searchsortedlast(f.thresholds_[dimen], coordinates[dimen])
    end
    return segment_coordinates
end

function get_correct_function_from_piecewise(f::Piecewise_Function, coordinates::Dict{Symbol,Float64})
    segment_coordinates = get_point_coordinates(f, coordinates)
    if 0 in segment_coordinates
        return Missing()
    else
        func = getindex(f.functions_, segment_coordinates...)
        return func
    end
end

function get_point_coordinates(f::Piecewise_Function, cubes::Dict{Symbol,Tuple{Float64,Float64}})
    labels = collect(keys(f.thresholds_))
    segment_coordinates = Array{Int,1}(undef,length(labels))
    for i in 1:length(labels)
        dimen = labels[i]
        segment_coordinates[i] = searchsortedlast(f.thresholds_[dimen], cubes[dimen][1])
    end
    return segment_coordinates
end

function get_correct_function_from_piecewise(f::Piecewise_Function, cubes::Dict{Symbol,Tuple{Float64,Float64}})
    segment_coordinates = get_point_coordinates(f, cubes)
    if 0 in segment_coordinates
        return Missing()
    else
        func = getindex(f.functions_, segment_coordinates...)
        return func
    end
end

function evaluate(f::Piecewise_Function, coordinates::Dict{Symbol,Float64})
    func = get_correct_function_from_piecewise(f, coordinates)
    return evaluate(func, coordinates)
end
function evaluate(f::Missing, coordinates::Dict{Symbol,Float64})
    return missing
end

function underlying_dimensions(f::Piecewise_Function)
    underlying = union(underlying_dimensions.(f.functions_)...)
    for k in keys(f.thresholds_)
        if f.thresholds_[k] != [-Inf]
            push!(underlying, k)
        end
    end
    return underlying
end



function get_threshold_dict(f1::Piecewise_Function,f2::Piecewise_Function)
    labels1 = collect(keys(f1.thresholds_))
    labels2 = collect(keys(f2.thresholds_))
    keyset = unique(vcat(labels1,labels2))
    theshold_dict = OrderedDict{Symbol,Array{Float64,1}}()
    for k in keyset
        if (k in keys(f1.thresholds_)) & (k in keys(f2.thresholds_))
            theshold_dict[k] = unique(sort!(vcat(f1.thresholds_[k], f2.thresholds_[k])))
        elseif (k in keys(f1.thresholds_))
            theshold_dict[k] = f1.thresholds_[k]
        else
            theshold_dict[k] = f2.thresholds_[k]
        end
    end
    return theshold_dict
end

function create_common_pieces(f1::Piecewise_Function,f2::Piecewise_Function)
    thresholds_ = get_threshold_dict(f1,f2)
    labels_     = collect(keys(thresholds_))
    lengths     = length.(get.(Ref(thresholds_), labels_, 0))
    functions1_ = Array{Union{Missing,Sum_Of_Functions},length(labels_)}(undef, lengths...)
    functions2_ = Array{Union{Missing,Sum_Of_Functions},length(labels_)}(undef, lengths...)
    for i in CartesianIndices(functions1_)
        starts = Dict(labels_ .=>  getindex.(  get.(Ref(thresholds_), labels_,0)  , Tuple(i)) .+ 100eps()  ) # The 100eps() here is to ensure we are inside the hypercube rather than on a boundary.
        functions1_[i] = get_correct_function_from_piecewise(f1, starts)
        functions2_[i] = get_correct_function_from_piecewise(f2, starts)
    end
    return Piecewise_Function(functions1_, thresholds_) , Piecewise_Function(functions2_, thresholds_)
end

# Sum of Piecewise functions
"""
    Sum_Of_Piecewise_Functions(functions_::Array{Piecewise_Function,1}, global_funcs_::Sum_Of_Functions)
At the cost of being less flexible a Sum_Of_Piecewise_Functions is more efficient than a PiecewiseFunction.
Use this if trying to represent a piecewise function that can be decomposed into a sum of lower dimensional
piecewise functions.
"""
struct Sum_Of_Piecewise_Functions <: MultivariateFunction
    functions_::Array{Piecewise_Function,1}
    global_funcs_::Sum_Of_Functions
    function Sum_Of_Piecewise_Functions(functions_::Array{Piecewise_Function,1})
        new(functions_, Sum_Of_Functions([]))
    end
    function Sum_Of_Piecewise_Functions(functions_::Array{Piecewise_Function,1}, sum_func_::Sum_Of_Functions)
        new(functions_, sum_func_)
    end
    function Sum_Of_Piecewise_Functions(functions_::Array{Sum_Of_Functions,1})
        return Sum_Of_Functions(functions_)
    end
    function Sum_Of_Piecewise_Functions(functions_::Sum_Of_Functions)
        return functions_
    end
    function Sum_Of_Piecewise_Functions(functions_::Array)
        pe_function_funcs                        = functions_[typeof.(functions_) .== MultivariateFunctions.PE_Function]
        Sum_Of_Functions_funcs                   = functions_[typeof.(functions_) .== MultivariateFunctions.Sum_Of_Functions]
        piecewise_funcs                          = functions_[typeof.(functions_) .== MultivariateFunctions.Piecewise_Function]
        sum_of_piecewise_functions_funcs         = functions_[typeof.(functions_) .== MultivariateFunctions.Sum_Of_Piecewise_Functions]
        piece_length = length(piecewise_funcs)
        funcs_length = length(functions_)
        if length(pe_function_funcs) + length(Sum_Of_Functions_funcs) + piece_length + length(sum_of_piecewise_functions_funcs) < length(functions_)
            error("A Sum_Of_Piecewise_Functions can only be created by an array of multivariate functions")
        elseif (funcs_length == 0) # So we have no functions input.
            return Sum_Of_Functions([])
        elseif (piece_length == 0) # so all are globals.
            globals = vcat(pe_function_funcs, Sum_Of_Functions_funcs, map(x -> x.global_funcs_ , sum_of_piecewise_functions_funcs)...)
            return Sum_Of_Functions(globals)
        elseif (piece_length == funcs_length) # So all are piecewise
            return new(piecewise_funcs, Sum_Of_Functions([]))
        else # We have both function types
            globals = vcat(pe_function_funcs, Sum_Of_Functions_funcs, map(x -> x.global_funcs_ , sum_of_piecewise_functions_funcs)...)
            pieces = vcat(piecewise_funcs, map(x -> x.functions_ , sum_of_piecewise_functions_funcs)...)
            return new(pieces, globals)
        end
    end
end

function underlying_dimensions(f::Sum_Of_Piecewise_Functions)
    return union(union(underlying_dimensions.(f.functions_)...), union(underlying_dimensions(f.global_funcs_)) )
end
function evaluate(f::Sum_Of_Piecewise_Functions, coordinates::Dict{Symbol,Float64})
    return sum(evaluate.(f.functions_, Ref(coordinates))) + evaluate(f.global_funcs_, coordinates)
end

function convert(::Type{Piecewise_Function}, f::Sum_Of_Piecewise_Functions)
    len = length(f.functions_)
    if len < 1
        error("It is not possible to convert a zero length Sum_Of_Piecewise_Functions into a Piecewise_Function.")
    elseif len == 1
        return f.functions_[1] + f.global_funcs_
    else
        pw =  f.functions_[1] + f.functions_[2]
        for l in 3:len
            pw = pw + f.functions_[l]
        end
        return pw + f.global_funcs_
    end
end



## Equivalence
const tol = 100*eps()
"""
    ≂
This tests whether two structs are close after allowing for numerical tolerance.
"""
function ≂(a::Float64,b::Float64)
    return abs(a-b) < tol
end
function ≂(a::Missing,b::Missing)
    return true
end
function ≂(a::MultivariateFunction,b::Missing)
    return false
end
function ≂(a::Missing,b::MultivariateFunction)
    return false
end
function ≂(a::MultivariateFunction,b::MultivariateFunction)
    return false # Note that this will not be called unless there is no overloads - hence it is a different function.
end
function ≂(a::PE_Unit,b::PE_Unit)
    if (a.b_ ≂ b.b_) & (a.base_ ≂ b.base_) & (a.d_ == b.d_)
        return true
    else
        return false
    end
end
function ≂(a::Dict{Symbol,PE_Unit},b::Dict{Symbol,PE_Unit})
    if keys(a) != keys(b)
        return false
    else
        for k in keys(a)
            if !(a[k] ≂ b[k])
                return false
            end
        end
    end
    return true
end
function ≂(a::PE_Function,b::PE_Function)
    if a.multiplier_  ≂ b.multiplier_
        if a.units_ ≂ b.units_
            return true
        end
    end
    return false
end


# Date support

function convert_format(val::Float64)
    return val
end
function convert_format(val::Symbol)
    return val
end
function convert_format(val::Int)
    return convert(Float64,val)
end
function convert_format(val::Date)
    return years_from_global_base(val)
end

function convert_to_conformable_dict(coordinates::Dict{Symbol,Any})
    new_coordinates = Dict{Symbol,Float64}()
    for dim in keys(coordinates)
        val = coordinates[dim]
        new_coordinates[dim] = convert_format(val)
    end
    return new_coordinates
end
function convert_to_conformable_dict(coordinates::Dict{Symbol,Tuple{Any,Any}})
    new_coordinates = Dict{Symbol,Tuple{Union{Symbol,Float64}, Union{Symbol,Float64}}}()
    for dim in keys(coordinates)
        val = coordinates[dim]
        new_tup = Tuple{Union{Symbol,Float64}, Union{Symbol,Float64}}((convert_format(val[1]), convert_format(val[2])))
        new_coordinates[dim] = new_tup
    end
    return new_coordinates
end

# DataFrame evaluation

function evaluate(f::PE_Function, coordinates::DataFrame)
    result = Array{Float64}(undef,size(coordinates)[1])
    result .= f.multiplier_
    if length(f.units_) == 0
        return result
    end
    units = deepcopy(f.units_)
    col_names = names(coordinates)
    for col in col_names
        if haskey(units, col)
            ff = pop!(units, col)
            result .= result .* evaluate.(Ref(ff), coordinates[col])
        end
    end
    if length(units) == 0
        return result
    else
        return PE_Function.(result, units)
    end
end

function evaluate(f::Sum_Of_Functions, coordinates::DataFrame)
    if length(f.functions_) == 0
        return repeat([0.0], size(coordinates)[1])
    end
    results = evaluate.(f.functions_, Ref(coordinates))
    return sum(results)
end
function evaluate(f::Piecewise_Function, coordinates::DataFrame)
    len = size(coordinates)[1]
    results = Array{Union{Float64,MultivariateFunction},1}(undef, len)
    underlying = underlying_dimensions(f)
    for r in 1:len
        coordinate = Dict{Symbol,Float64}()
        for dimen in names(coordinates)
            coordinate[dimen] = coordinates[r,dimen]
        end
        results[r] = evaluate(f ,coordinate)
    end
    return results
end
function evaluate(f::Sum_Of_Piecewise_Functions, coordinates::DataFrame)
    result = evaluate(f.global_funcs_, coordinates)
    for i in 1:length(f.functions_)
        result = result + evaluate(f.functions_[i], coordinates)
    end
    return result
end
