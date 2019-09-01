@testset "ReadWrite" begin

    testdir = joinpath(@__DIR__, "data")
    files = map(x -> joinpath(testdir, x), readdir(testdir))

    for f in files
         res = featherread(f)
         columns, headers = res.columns, res.names

        ncols = length(columns)
        nrows = length(columns[1])

        temp = tempname()
        push!(temps, temp)

        featherwrite(temp, columns, headers, description=res.description, metadata=res.metadata)

         res2 = featherread(temp)
         columns2, headers2 = res2.columns, res2.names

        @test length(columns2) == ncols

        @test headers==headers2

        for (c1,c2) in zip(columns, columns2)
            @test length(c1)==nrows
            @test length(c2)==nrows
            for i = 1:nrows
                @test isequal(c1[i], c2[i])
            end
        end

    @test res.description == res2.description
    @test res.metadata == res2.metadata
    # for (col1,col2) in zip(source.ctable.columns,sink.ctable.columns)
    #     @test col1.name == col2.name
    #     @test col1.metadata_type == col2.metadata_type
    #     @test typeof(col1.metadata) == typeof(col2.metadata)
    #     @test col1.user_metadata == col2.user_metadata

    #     v1 = col1.values; v2 = col2.values
    #     @test v1.dtype == v2.dtype
    #     @test v1.encoding == v2.encoding
    #     # @test v1.offset == v2.offset # currently not python/R compatible due to wesm/feather#182
    #     @test v1.length == v2.length
    #     @test v1.null_count == v2.null_count
    #     # @test v1.total_bytes == v2.total_bytes
    # end
    end
end
