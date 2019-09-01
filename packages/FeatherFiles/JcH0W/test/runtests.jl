using FeatherFiles
using DataValues
using IteratorInterfaceExtensions
using TableTraits
using Test

@testset "FeatherFiles" begin

source = [(Name="John", Age=34., Children=2),
    (Name="Sally", Age=54., Children=1),
    (Name="Jim", Age=34., Children=0)]

output_filename = tempname() * ".feather"

source |> save(output_filename)

try
    sink = load(output_filename) |> IteratorInterfaceExtensions.getiterator |> collect

    @test source == sink

    featherfile = load(output_filename)

    @test IteratorInterfaceExtensions.isiterable(featherfile) == true
    @test TableTraits.supports_get_columns_copy_using_missing(featherfile) == true
    ff_as_cols = TableTraits.get_columns_copy_using_missing(featherfile)
    @test ff_as_cols == (Name=["John", "Sally", "Jim"], Age=[34., 54., 34.], Children=[2,1,0])
finally
    GC.gc()
    GC.gc()
    # rm(output_filename)
end

source2 = [(Name=DataValue("John"), Age=DataValue(34.), Children=DataValue{Int}()),
    (Name=DataValue("Sally"), Age=DataValue{Float64}(), Children=DataValue(1)),
    (Name=DataValue{String}(), Age=DataValue(34.), Children=DataValue(0))]

output_filename2 = tempname() * ".feather"

source2 |> save(output_filename2)

try
    sink2 = load(output_filename2) |> IteratorInterfaceExtensions.getiterator |> collect

    @test source2 == sink2

    featherfile = load(output_filename2)
    @test IteratorInterfaceExtensions.isiterable(featherfile) == true
    @test TableTraits.supports_get_columns_copy_using_missing(featherfile) == true
    ff_as_cols = TableTraits.get_columns_copy_using_missing(featherfile)
    @test isequal(ff_as_cols, (Name=["John", "Sally", missing], Age=[34., missing, 34.], Children=[missing,1,0]))
finally
    GC.gc()
    GC.gc()
    # rm(output_filename2)
end

end
