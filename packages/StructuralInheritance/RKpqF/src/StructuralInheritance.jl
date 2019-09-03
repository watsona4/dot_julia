module StructuralInheritance

export @protostruct, totuple

const FieldType = Union{Symbol,Expr}
const SymbolTuple = Tuple{Vararg{Symbol,N}} where {N}

#Stores prototype field definitions
const fieldBacking = IdDict{Type, Vector{FieldType}}()

#prototype -> self
#concrete -> prototype
const shadowMap = IdDict{Type,Type}()

#store parametric type information
const parameterMap = IdDict{Type,Vector{FieldType}}()

const mutabilityMap = IdDict{Type,Bool}()


"""
Creates an abstract type with the given name
"""
abstracttype(name) = :(abstract type $name end)

"""
attaches parameters to a name
"""
function addparams(name,params)
    if length(params) == 0
        name
    else
        :($name{$(params...)})
    end
end


"""
returns an array with only the field definitions
"""
function filtertofields(unfiltered)
    filter(x->x isa Symbol || (x isa Expr && x.head == :(::)),unfiltered)
end

"""
flattens the scope of the fields
"""
flattenfields(x) = FieldType[]
flattenfields(x::Symbol) = FieldType[x]
function flattenfields(x::Expr)::Vector{FieldType}
    if x.head == :block
        vcat(FieldType[],flattenfields.(x.args)...)
    else
        FieldType[x]
    end
end

isfunctiondefinition(x) = false
isfunctiondefinition(x::Expr) = (x.head == :(=) || x.head == :function)

"""
returns array with only the field constructors
"""
function extractconstructors(_quote)
    filter(isfunctiondefinition,_quote.args[3].args)
end


"""
extracts the fields from a struct definition
"""
extractfields(leaf) = filtertofields(flattenfields(leaf.args[3]))


function newnames(nameNode::Symbol,module_,prefix)
    protoName = Symbol(prefix,nameNode)
    return (:($nameNode <: $protoName),protoName,nameNode,protoName)
end
function newnames(nameNode,module_,prefix)
    """
    handle inheritence conversions
    """
    function rectify(@nospecialize(x))::FieldType
        val = module_.eval(deparametrize(x))::Type
        if isabstracttype(val)
            x
        elseif haskey(shadowMap,val)
            addparams(:($(qualifyname(shadowMap[val]))),getparameters(x))
        else
            throw("inheritence from concrete types is limited to those defined by @protostruct, $val not found")
        end
    end

    if nameNode.head == :<:
        inheritFrom = rectify(nameNode.args[2])::Union{Type,FieldType}
        structHead = deepcopy(nameNode.args[1])::FieldType

        if isparametric(structHead)
            protoName = nameNode
            protoChild = protoName.args[1]::Expr
            protoChild.args[1] = Symbol(prefix,structHead.args[1])
            protoName.args[2] = inheritFrom
            return (:( $(structHead) <: $(detypevar(protoChild))),
                    protoName,
                    structHead,
                    protoChild)

        elseif structHead isa Symbol
            protoName = deepcopy(nameNode)
            lightProto = Symbol(prefix,structHead)
            protoName.args[1]  = lightProto
            protoName.args[2] = inheritFrom
            return (:( $(structHead) <: $(lightProto)),
                    protoName,
                    structHead,
                    lightProto)
        end
    end


    if isparametric(nameNode)
        protoName = deepcopy(nameNode)
        protoName.args[1] = Symbol(prefix,nameNode.args[1]::Symbol)
        return (:( $(nameNode) <: $(detypevar(protoName))),
                protoName,
                nameNode,
                protoName)
    end

    throw("structure of strucure name not identified")
end

"""
from Foo{A<:B}
returns Foo{A}
"""
detypevar(x) = x
function detypevar(x::Expr)
    if x.head == :<:
        detypevar(x.args[1]::FieldType)
    else
        Expr(x.head,detypevar.(x.args)...)::Expr
    end
end

isparametric(x) = false
isparametric(x::Expr) = x.head == :curly || any(isparametric,x.args)


ispath(x) = false
ispath(x::Expr) = x.head == :.

iscontainerlike(x) = false
iscontainerlike(x::Expr) = (x.head in (:vect,:hcat,:row,
                                       :vcat, :call,
                                       :tuple,:curly,:macrocall))

function getpath(x)
    oldpath = Symbol[]
    while ispath(x)
        push!(oldpath,(x.args[2]::QuoteNode).value)
        x = x.args[1]::FieldType
    end
    oldpath = push!(oldpath,x)
    oldpath[2:end], oldpath[1]
end

function get2parameters(x)
    if x isa Expr && x.head == :<:
        (stablegetparameters(x.args[1]),getparameters(x.args[2]))
    else
        (stablegetparameters(x),Symbol[])
    end
end

getparameters(x)::Vector = isparametric(x) ? detypevar.(x.args[2:end]) : Symbol[]
stablegetparameters(x)::Vector{Symbol} = isparametric(x) ? detypevar.(x.args[2:end]) : Symbol[]

function getfieldnames(x)
    f(x::Symbol) = x
    f(x::Expr) = x.args[1]::Symbol
    f.(x)
end

"""
creates AST for expanding a struct into a tuple with the fields given
"""
function tupleexpander(x,fields)
    Expr(:tuple,((y)->:($x.$y)).(getfieldnames(fields))...)
end

"""
throws an error is the fields contain overlapping symbols
"""
function assertcollisionfree(x,y)
    xf,yf = getfieldnames(x), getfieldnames(y)
    if any(x->(x in xf),yf) #faster then sets for expected field counts
        throw("Field defined in multiple locations")
    end
end

"""
returns a copy with replacement fields
"""
function replacefields(struct_,fields)
    out = deepcopy(struct_)
    out.args[3].args = fields
    out
end

"""
adds source module information to the type name
"""
fulltypename(x,modulePath,inhibit) = x #is a literal

function fulltypename(x::Union{Expr,Symbol},modulePath,inhibit)
    if x in inhibit
        return x
    end
    if iscontainerlike(x)
        fullargs = (fulltypename(y,modulePath,inhibit) for y in x.args)
        return Expr(x.head,fullargs...)
    end
    qualifyname(x,modulePath)
end

function qualifyname(@nospecialize(x::Type))
    qualifyname(nameof(x),Symbol[fullname(parentmodule(x))...])
end

function qualifyname(x::Expr,modulePath)
    oldpath,x = getpath(x)

    isWrapped = length(modulePath) == 1
    out = Expr(:.,modulePath[1],QuoteNode(isWrapped ? oldpath[1] : modulePath[2]))
    for i = 3:length(modulePath)
        out = Expr(:.,out,QuoteNode(modulePath[i]))
    end
    for i = length(oldpath):-1:(isWrapped + 1)
        out = Expr(:.,out,QuoteNode(oldpath[i]))
    end
    Expr(:.,out,QuoteNode(x))
end
function qualifyname(x::Symbol,modulePath)
    if length(modulePath) == 1
        return Expr(:.,modulePath[1],QuoteNode(x))
    end
    out = Expr(:.,modulePath[1],QuoteNode(modulePath[2]))
    for i = 3:length(modulePath)
        out = Expr(:.,out,QuoteNode(modulePath[i]))
    end
    Expr(:.,out,QuoteNode(x))
end

"""
annotates module information to unanotated typed fields
"""
function sanitize!(modulePath,fields,inhibit)
    for i = eachindex(fields)
        temp = fields[i]
        if temp isa Expr
            if temp.args[2] isa FieldType
                temp.args[2] = fulltypename(temp.args[2]::FieldType,modulePath,inhibit)
            end
        end
    end
end

"""
update parameters from old fields
"""
function updateParameters(oldFields,oldParams,parameters,parentType,modulePath)
    update(x) = x
    function update(x::Symbol)
        if x in oldParams
            loc = findfirst(y->(y==x),oldParams)
            newParam = parameters[2][loc]
            if newParam in parameters[1]
                return newParam
            else
                return fulltypename(newParam,modulePath,parameters[1])
            end
        end
        x
    end
    function update(x::Expr)
        Expr(x.head,(update(z) for z in x.args)...)
    end
    update.(oldFields)
end

"""
turns an object into a tuple of its fields
"""
function totuple(x) #low efficiency version
    if fieldcount(typeof(x)) > 0
        tuple((getfield(x,y) for y in fieldnames(typeof(x)))...)
    else
        (x,)
    end
end

"""
returns a renamed struct
"""
function rename(struct_,name)
    newStruct = deepcopy(struct_)
    newStruct.args[2] = name
    newStruct
end

"""
strips parameterization off of a name that does
not include inheritence information
"""
deparametrize(name) = name
deparametrize(name::Expr) = name.head == :curly ? name.args[1] : name

"""
registers a new struct and abstract type pair
"""
function register(@nospecialize(concrete),@nospecialize(proto),fields,parameters,mutability)

    fieldBacking[proto] = fields
    shadowMap[concrete] = proto
    parameterMap[proto] = parameters
    mutabilityMap[proto] = mutability
    shadowMap[proto] = proto
end

inherits(x::Symbol) = false
inherits(x::Expr) = x.head != :curly

"""
@protostruct(struct_ [, prefix_])

creates a struct that can have structure inherited from it and can inherit
structure.

additionally it creates an abstract type with a name given by the struct
definitions name and a prefix. The concrete type inherits from the abstract
type and anything which inherits the concrete types structure also inherits
behavior from the abstract type.

```Julia
julia> using StructuralInheritance

julia> @protostruct struct A{T}
           fieldFromA::T
       end
ProtoA

julia> @protostruct struct B{D} <: A{Complex{D}}
          fieldFromB::D
       end "SomeOtherPrefix"
SomeOtherPrefixB

julia> @protostruct struct C <: B{Int}
         fieldFromC
       end
ProtoC
```
"""
macro protostruct(struct_,prefix_ = "Proto",mutablilityOverride = false)
    protostruct(__module__,struct_,prefix_,mutablilityOverride)
end

function protostruct(__module__,struct_,prefix_,mutablilityOverride)
    try
        prefix = (prefix_ isa Union{String,Symbol}) ? string(prefix_) : string(__module__.eval(prefix_))

        if length(prefix) == 0
            throw("Prefix must have finite Length")
        end

        struct_ = macroexpand(__module__,struct_,recursive=true)::Expr

        mutability = struct_.args[1]::Bool
        newName,name,newStructLightName,lightname = newnames(struct_.args[2]::FieldType,__module__,prefix)

        newParameters,oldParameters = get2parameters(struct_.args[2]::FieldType)

        fields = extractfields(struct_)
        prototypeDefinition = abstracttype(name)
        structDefinition = rename(struct_,newName)
        SI = StructuralInheritance
        modulePath = Symbol[fullname(__module__)...]
        if !inherits(name)
            sanitize!(modulePath,fields,newParameters)
        else #inheritence case
            parentType = get(shadowMap,__module__.eval(deparametrize(name.args[2])),nothing)
            oldFields = get(fieldBacking,parentType ,FieldType[])
            oldMutability = get(mutabilityMap,parentType,nothing)

            if oldMutability != nothing && oldMutability != mutability
                if eval(mutablilityOverride) != true
                    throw("$(oldMutability ? "im" : "")mutable object"*
                    " inheriting from $(oldMutability ? "" : "im")mutable")
                end
            end

            assertcollisionfree(fields,oldFields)
            sanitize!(modulePath,fields,newParameters)
            oldFields = updateParameters(oldFields,
                                        get(parameterMap,parentType,FieldType[]),
                                         (newParameters,oldParameters),
                                         parentType,
                                         modulePath)
            fields = vcat(oldFields,fields)
            constructors = extractconstructors(struct_)
            structDefinition = replacefields(structDefinition,
                                             vcat(fields,constructors))
        end
        return esc(quote
            $prototypeDefinition
            $structDefinition
            function $SI.totuple(x::$(deparametrize(newStructLightName)))
                $(tupleexpander(:x,fields))
            end
            $SI.register($(deparametrize(newStructLightName)),
                         $(deparametrize(lightname)),
                         $(Meta.quot(fields)),
                         $(Meta.quot(newParameters)),
                         $mutability)
        end)

    catch e
        return :(throw($e))
    end
end


end
