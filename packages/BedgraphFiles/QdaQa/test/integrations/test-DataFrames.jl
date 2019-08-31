@testset "DataFrames" begin

    using DataFrames


    # DataFrame from Vector{Bedgraph.Record}.
    df = DataFrame(Bag.records)

    @test typeof(df) == DataFrame
    @test size(df) == (9,4)

    @test df[:chrom] == Bag.chroms
    @test df[:first] == Bag.firsts
    @test df[:last] == Bag.lasts
    @test df[:value] == Bag.values

    @test DataFrame(Bag.records) == Bag.records |> DataFrame


    # DataFrame from bedGraph file.
    df2 = DataFrame(load(Bag.file))

    @test typeof(df2) == DataFrame
    @test size(df2) == (9,4)

    @test df2[:chrom] == Bag.chroms
    @test df2[:first] == Bag.firsts
    @test df2[:last] == Bag.lasts
    @test df2[:value] == Bag.values

    @test DataFrame(load(Bag.file)) == load(Bag.file) |> DataFrame


    # DataFrame from headerless bedGraph file.
    df3 = DataFrame(load(Bag.file_headerless))
    @test typeof(df3) == DataFrame
    @test size(df3) == (9,4)

    @test df3[:chrom] == Bag.chroms
    @test df3[:first] == Bag.firsts
    @test df3[:last] == Bag.lasts
    @test df3[:value] == Bag.values

    @test DataFrame(load(Bag.file_headerless)) == load(Bag.file_headerless) |> DataFrame


    # Save and load from DataFrame.
    save(Bag.tmp_output_path, df)
    @test df == load(Bag.tmp_output_path) |> DataFrame

    df |> save(Bag.tmp_output_path)
    @test df == load(Bag.tmp_output_path) |> DataFrame

end # test DataFrames
