using ExtensibleUnions
using Test

function f1 end
ExtensibleUnions._update_all_methods_for_extensiblefunction!(f1)

b = Type{Vector{T} where T}
@test_throws MethodError ExtensibleUnions._update_single_method!(f1, b, Set())
@test_throws MethodError ExtensibleUnions._update_single_method!(f1, b, Set(), nothing => nothing)
@test_throws MethodError ExtensibleUnions._replace_types(b)
@test_throws MethodError ExtensibleUnions._replace_types(b, nothing => nothing)

@test ExtensibleUnions._replace_types(Union{}) == Union{}
@test ExtensibleUnions._replace_types(Union{}, Union{} => Union{Float32, String}) == Union{Float32, String}
@test ExtensibleUnions._replace_types(Union{}, Union{Float32, String} => Union{Float32, Int32, String}) == Union{}
@test ExtensibleUnions._replace_types(Union{Int32}) == Union{Int32}
@test ExtensibleUnions._replace_types(Union{Int32}, Int32 => Float32) == Union{Float32}
@test ExtensibleUnions._replace_types(Union{Int32, Float32}) == Union{Int32, Float32}
@test ExtensibleUnions._replace_types(Union{Int32, Float32}, Union{Int32, Float32} => Union{String, Symbol}) == Union{String, Symbol}
@test ExtensibleUnions._replace_types(Union{Int32, Float32}, Float32 => String) == Union{Int32, String}
@test ExtensibleUnions._replace_types(Union{Int32, Float32, AbstractString}) == Union{Int32, Float32, AbstractString}
@test ExtensibleUnions._replace_types(Union{Int32, Float32, AbstractString}, Float32 => Symbol) == Union{Int32, Symbol, AbstractString}
@test ExtensibleUnions._replace_types(Union{Int32, Float32, AbstractString}, Union{Int32, Float32, AbstractString} => Symbol) == Symbol
@test ExtensibleUnions._replace_types(Union{Int32, Float32, AbstractString, Symbol}) == Union{Int32, Float32, AbstractString, Symbol}
@test ExtensibleUnions._replace_types(Union{Int32, Float32, AbstractString, Symbol}, Float32 => Char) == Union{Int32, Char, AbstractString, Symbol}
@test ExtensibleUnions._replace_types(Union{Int32, Float32, AbstractString, Symbol}, Union{Int32, Float32, AbstractString, Symbol} => Union{Int32, Float32, AbstractString, Symbol, Char}) == Union{Int32, Float32, AbstractString, Symbol, Char}

structlist = Any[]
@genstruct!(structlist)
@genstruct!(structlist)
@genstruct!(structlist)
@genstruct!(structlist)
@genstruct!(structlist)
@genstruct!(structlist)
@genstruct!(structlist)
# funclist = Any[]
# @genfunc!(funclist)
# @genfunc!(funclist)
FooTrait = structlist[1]
BarTrait = structlist[2]
BazTrait = structlist[3]
extensibleunion!(FooTrait)
extensibleunion!(BarTrait)
ExtensibleUnions._update_all_methods_for_extensibleunion!(FooTrait)
ExtensibleUnions._update_all_methods_for_extensibleunion!(BarTrait, nothing=>nothing)
StructA = structlist[4]
StructB = structlist[5]
StructC = structlist[6]
StructD = structlist[7]
# f = funclist[1]
# g = funclist[2]
function f end
function g end
f(x::FooTrait) = "foo"
f(x::BarTrait) = "bar"
extensiblefunction!(f, FooTrait, BarTrait)
extensiblefunction!(f, (FooTrait, BarTrait,))
ExtensibleUnions._update_all_methods_for_extensibleunion!(FooTrait)
ExtensibleUnions._update_all_methods_for_extensibleunion!(BarTrait, nothing=>nothing)
ExtensibleUnions._update_all_methods_for_extensiblefunction!(f)
addtounion!(FooTrait, StructA)
addtounion!(FooTrait, StructB)
addtounion!(FooTrait, StructC)
addtounion!(FooTrait, StructD)
addtounion!(BarTrait, StructA)
addtounion!(BarTrait, StructB)
addtounion!(BarTrait, StructC)
addtounion!(BarTrait, StructD)
ExtensibleUnions._update_all_methods_for_extensibleunion!(FooTrait)
ExtensibleUnions._update_all_methods_for_extensibleunion!(BarTrait, nothing=>nothing)
ExtensibleUnions._update_all_methods_for_extensiblefunction!(f)
g(x::BazTrait) = "baz"
ExtensibleUnions._registry_extensibleunion_to_members[BazTrait] = Set(Any[StructA, StructB, StructC, StructD])
ExtensibleUnions._update_single_method!(g, Tuple{typeof(g), BazTrait}, Set(Any[BazTrait]))
