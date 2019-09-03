TABLE_CAST = """id,height,age,name,occupation
1.1,10,1,string1,2012
"""

@testset "Read a Table from file" begin

    @testset "Basic data reading" begin
        t = Table("../data/data_types.csv")
        trs = TableSchema.read(t, cast=false)
        # check the headers
        @test length(t.headers) == 5
        HEIGHT_COLUMN = 2
        @test t.headers[HEIGHT_COLUMN] == "height"
        # check the number of rows
        @test length(trs[:,1]) == 5
        # check the bottom left index
        @test trs[5,1] == 5
        # iterate over the rows
        @test sum([ row[HEIGHT_COLUMN] for row in t ]) == 51
        # no schema, hence exception
        @test_throws TableValidationException validate(t)
    end

    @testset "Passing an IO buffered file" begin
        t = Table()
        t.schema = Schema("../data/schema_valid_missing.json")
        @test TableSchema.is_valid(t.schema)
        f = readdlm("../data/data_types.csv", ',')
        tr = TableSchema.read(t, data=f)
        @test validate(t)
    end

    @testset "With schema validation" begin
        s = Schema("../data/schema_valid_missing.json")
        t = Table("../data/data_types.csv", s)
        @test validate(t)
        t2 = Table("../data/data_constraints.csv", s)
        @test !validate(t2)
        @test length(t2.errors) == 2
    end

    @testset "With row casting" begin
        s = Schema("../data/schema_valid_missing.json")
        t = Table(IOBuffer(TABLE_CAST), s)
        tr = TableSchema.read(t)
        @test TableSchema.is_valid(t.schema)
        @test isa(tr[1,1], String)
        @test isa(tr[1,2], Float64)
    end

    @testset "Remote data and schema reading" begin
        t = Table("https://raw.githubusercontent.com/frictionlessdata/tableschema-jl/master/data/data_types.csv")
        trs = TableSchema.read(t, cast=false)
        # check the headers
        @test length(t.headers) == 5
        @test t.headers[2] == "height"
        # validate from remote schema
        t.schema = Schema("https://raw.githubusercontent.com/frictionlessdata/tableschema-jl/master/data/schema_valid_missing.json")
        @test validate(t)
    end

end
