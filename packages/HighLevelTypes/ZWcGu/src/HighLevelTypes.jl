module HighLevelTypes

export @hl, @concretify, tuplejoin

const _hl_types = Dict{Symbol, Tuple}()

@inline tuplejoin(x) = (x,)
@inline tuplejoin(x::Tuple, y::Tuple) = (x..., y...)
@inline tuplejoin(x::Tuple, y) = (x..., y)
@inline tuplejoin(x, y::Tuple) = (x, y...)
@inline tuplejoin(x, y) = (x,y)
@inline tuplejoin(x::Tuple, y, z...) = (x..., tuplejoin(y, z...)...)
@inline tuplejoin(x, y, z...) = (x, tuplejoin(y, z...)...)

function maketypesconcrete(expression)
    for (i,arg) in enumerate(expression.args)
        if isa(arg, Symbol) 
            if haskey(_hl_types, arg)                
                expression.args[i] = Symbol("_", arg)                
            end
        elseif :args in fieldnames(typeof(arg))
            maketypesconcrete(arg)
        end
    end
end

#creates a highlevel type: uses abstract types of attribute fields
macro hl(typeexpr::Expr)   
    mutable, nameblock, args = typeexpr.args
    createhltype(mutable, nameblock, args)           
end

#uses concrete types for all highlevel types
macro concretify(expr::Expr)  
    maketypesconcrete(expr)
    esc(expr)
end



function createhltype(mutable, nameblock, args)
    if !isa(nameblock, Symbol) && nameblock.head == :<:        
        parentname = nameblock.args[2]
        nameblock = nameblock.args[1]        
    else
        parentname = :NOPARENT
    end

    if isa(nameblock, Symbol)
        name, params = nameblock, []
    elseif nameblock.head == :curly
        name, params = nameblock.args[1], nameblock.args[2:end]
    end
    
    if parentname == :NOPARENT         
        _hl_types[name] = params, args        
        acode = :(abstract type $name end)
    else
        _hl_types[name] = vcat(_hl_types[parentname][1], params), :( $(_hl_types[parentname][2].args...) ; $(args.args...))
        acode = :(abstract type $name <: $parentname end)
    end
            
    tname = Symbol(:_, name)
    tname = :($tname{})
    append!(tname.args, _hl_types[name][1]) 
    constrcode = quote 
        $(Symbol(name,"Builder"))(args...) = args
        $name(args...) = $(Symbol("_",name))($(Symbol(name,"Builder"))(args...)...)
    end
        
    if mutable          
        code = quote
            $acode
            mutable struct $tname <: $name
                $(_hl_types[name][2].args...)
            end
            $constrcode
        end
    else
        code = quote
            $acode
            struct $tname <: $name
                $(_hl_types[name][2].args...)
            end
            $constrcode
        end
    end
    esc(code) 
end
 
end # module
