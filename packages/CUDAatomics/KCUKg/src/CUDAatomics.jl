module CUDAatomics

using CUDAnative, LLVM
using LLVM.Interop

let type_map = Dict( Int32 => ("u32", "r", "b32", "s32"), UInt32 => ("u32", "r", "b32", "u32"), Int64 => ("u64", "l", "b64", "s64"), UInt64 => ("u64", "l", "b64", "s64"), Float32 => ("f32", "f", "b32", "f32"), Float64 => ("f64", "d", "b64", "f64") ), atomiclist = [("add",2,1), ("exch",2,3), ("min",2,4), ("max",2,4), ("inc",2,1), ("dec",2,1), ("cas",3,3), ("and",2,3), ("or",2,3), ("xor",2,3)]

global @generated function cvt( a::Type{T}, b::U ) where {T,U}
    round_str = ""
    if U==Float32
        if !(T in [Float32, Float64])
            round_str = "rzi."
        end
    elseif U==Float64
        if T==Float32
            round_str = "rn."
        elseif T!=Float64
            round_str = "rzi."
        end
    else
        if T in [Float32,Float64]
            round_str = "rn."
        end
    end

    call_string = string("cvt.",round_str,type_map[T][1],".",type_map[U][1], " \$0, \$1;")
    ex = :(@asmcall)
    append!(ex.args, [call_string, string("=",type_map[T][2],",",type_map[U][2]), false, Symbol(T), :(Tuple{$U}), :b])
    return :(Base.@_inline_meta; $ex)
end

function atomicexpression(instr::String, nargs, typeindex)
    fex = :(@generated function $(Symbol("atomic"*instr))(a) end)
    for i=1:(nargs-1)
        push!(fex.args[3].args[1].args, Symbol("a"*"$i"))
    end
    push!(fex.args[3].args[1].args, Expr(:kw, :index, 1))
    push!(fex.args[3].args[1].args, Expr(:kw, :field, Val(nothing)))
    fargs = fex.args[3].args[2].args
    append!(fargs, (quote
        type_map = $type_map
        fieldsym = field.parameters[1]
        if fieldsym == nothing
            base_type = a.parameters[1]
            offset = 0
        else
            field_index = findfirst(fieldnames(a.parameters[1]) .== fieldsym)
            base_type = a.parameters[1].types[field_index]
            offset = (cumsum(sizeof.(a.parameters[1].types)) .- sizeof.(a.parameters[1].types))[field_index]
        end
        ASstr = a.parameters[3] == CUDAnative.AS.Shared ? "shared" : "global"
    end).args)

    append!(fargs, (quote
        call_string = string( "cvta.to.",ASstr,".u64 %rd1, \$1;\natom.",ASstr,".",$instr,".", type_map[base_type][$typeindex], " \$0, [%rd1],")
        call_string = string(call_string, string(string(string.(" \$", collect(2:$nargs), ",")...)[1:end-1],";"))
    end).args)

    for i=1:(nargs-1)
        varsym = Symbol("a"*"$i")
        subex = :($(Symbol("a"*"$i"*"val")) = $varsym==base_type ? $(QuoteNode(:($varsym))) : :(cvt($base_type, $varsym)))
        subex.args[end].args[end].args[end].args[end] = varsym
        push!(fargs, subex)
    end

    append!(fargs, (quote
        ex = :(@asmcall)
        constraint_list = Array{String}(["=", type_map[base_type][2], ",l"])
        argtype_expr = :(Tuple{UInt64})
        for i=2:$nargs
            push!(constraint_list,string(","*type_map[base_type][2]))
            push!(argtype_expr.args,Symbol(base_type))
        end
        append!(ex.args, [call_string, string(constraint_list...), true, Symbol(base_type), argtype_expr, :( UInt64(a.ptr.ptr) + $offset + $(sizeof(base_type))*(index-1)), a1val])
        return :(Base.@_inline_meta; $ex)
    end).args)

    for i=2:(nargs-1)
        push!(fargs[end-2].args[end].args, Symbol("a"*"$i"*"val"))
    end

    return fex
end

for atomicfunc in atomiclist
    eval(atomicexpression(atomicfunc[1], atomicfunc[2], atomicfunc[3]))
    eval(:(export $(Symbol("atomic"*atomicfunc[1]))))
end


end

function atomicsub(a::CuDeviceArray{Int32, N, A}, b, index=1, field=Val(nothing)) where {N,A}
    atomicadd(a, -b, index, field)
end
export atomicsub

export cvt

end
