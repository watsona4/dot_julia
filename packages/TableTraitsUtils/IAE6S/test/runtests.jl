using TableTraitsUtils
using DataValues
using Test

include("test_source_without_length.jl")

@testset "TableTraitsUtils" begin

@test_throws ArgumentError TableTraitsUtils.create_columns_from_iterabletable(nothing)
@test_throws ArgumentError TableTraitsUtils.create_columns_from_iterabletable(nothing, errorhandling=:error)
@test TableTraitsUtils.create_columns_from_iterabletable(nothing, errorhandling=:returnvalue)===nothing

@test_throws ArgumentError TableTraitsUtils.create_columns_from_iterabletable([1,2,3])
@test_throws ArgumentError TableTraitsUtils.create_columns_from_iterabletable([1,2,3], errorhandling=:error)
@test TableTraitsUtils.create_columns_from_iterabletable([1,2,3], errorhandling=:returnvalue)===nothing

@test_throws ArgumentError TableTraitsUtils.create_columns_from_iterabletable(Iterators.filter(i->true, [1,2,3]))
@test_throws ArgumentError TableTraitsUtils.create_columns_from_iterabletable(Iterators.filter(i->true, [1,2,3]), errorhandling=:error)
@test TableTraitsUtils.create_columns_from_iterabletable(Iterators.filter(i->true, [1,2,3]), errorhandling=:returnvalue)===nothing

@test create_columns_from_iterabletable(NamedTuple{(:a,:b),Tuple{Int,String}}[]) == (Any[Int[],String[]], [:a,:b])
@test create_columns_from_iterabletable((i for i in NamedTuple{(:a,:b),Tuple{Int,String}}[])) == (Any[Int[],String[]], [:a,:b])

@test_throws ArgumentError create_columns_from_iterabletable(Int[])
@test_throws ArgumentError create_columns_from_iterabletable(Int[], errorhandling=:error)
@test create_columns_from_iterabletable(Int[], errorhandling=:returnvalue) === nothing
@test_throws ArgumentError create_columns_from_iterabletable((i for i in Int[]))
@test_throws ArgumentError create_columns_from_iterabletable((i for i in Int[]), errorhandling=:error)
@test create_columns_from_iterabletable((i for i in Int[]), errorhandling=:returnvalue) === nothing

columns = (Int[1,2,3], Float64[1.,2.,3.], String["John", "Sally", "Drew"])
names = [:children, :age, :name]

it = TableTraitsUtils.create_tableiterator(columns, names)

columns2, names2 = TableTraitsUtils.create_columns_from_iterabletable(it)

columns3, names3 = TableTraitsUtils.create_columns_from_iterabletable(it, sel_cols=:all)

columns23, names23 = TableTraitsUtils.create_columns_from_iterabletable(it, sel_cols=[2,3])

@test columns[1] == columns2[1] == columns3[1]
@test columns[2] == columns2[2] == columns3[2]
@test columns[3] == columns2[3] == columns3[3]
@test length(columns) == length(columns2) == length(columns3)
@test columns[2] == columns23[1]
@test columns[3] == columns23[2]
@test length(columns23) == 2

@test names == names2 == names3
@test names[2:3] == names23

@test isequal(create_columns_from_iterabletable([(a=DataValue{Any}(), b=DataValue{Int}())], na_representation=:missing),
    ([Any[missing], Union{Missing,Int}[missing]], [:a, :b])
)

@test create_columns_from_iterabletable([(a=DataValue{Any}(), b=DataValue{Int}())], na_representation=:datavalue) ==
    ([DataValue{Any}[NA], DataValue{Int}[NA]], [:a, :b])

it2 = TestSourceWithoutLength()

columns4, names4 = TableTraitsUtils.create_columns_from_iterabletable(it2)
@test columns4[1] == [1,2]
@test columns4[2] == [1.,2.]
@test names4 == [:a, :b]

columns5, names5 = TableTraitsUtils.create_columns_from_iterabletable(it2, sel_cols=:all)
@test columns5[1] == [1,2]
@test columns5[2] == [1.,2.]
@test names5 == [:a, :b]

columns6, names6 = TableTraitsUtils.create_columns_from_iterabletable(it2, sel_cols=[2])
@test columns6[1] == [1.,2.]
@test names6 == [:b]

columns_with_nulls = (Union{Int,Missing}[3, 2, missing], Float64[2.,5.,9.], Union{String,Missing}["a", missing, "b"])
it3 = TableTraitsUtils.create_tableiterator(columns_with_nulls, names)

columns7, names7 = TableTraitsUtils.create_columns_from_iterabletable(it3)

@test columns7[1] == [3,2,NA]
@test columns7[2] == [2.,5.,9.]
@test columns7[3] == ["a",NA,"b"]
@test length(columns7) == 3
@test names7 == names

columns_with_DV = ([3, 2, NA], [2.,5.,9.], ["a", NA, "b"])
it4 = TableTraitsUtils.create_tableiterator(columns_with_DV, names)

columns8, names8 = TableTraitsUtils.create_columns_from_iterabletable(it4)

@test columns8[1] == [3,2,NA]
@test columns8[2] == [2.,5.,9.]
@test columns8[3] == ["a",NA,"b"]
@test length(columns8) == 3
@test names8 == names

it = TableTraitsUtils.create_tableiterator(Any[], Symbol[])

@test length(it)==0
@test iterate(it)===nothing

end
