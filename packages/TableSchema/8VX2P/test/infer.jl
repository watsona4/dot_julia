TABLE_MIN = """id,height,age,name,occupation
1,10.0,1,string1,2012-06-15 00:00:00
2,10.1,2,string2,2013-06-15 01:00:00
3,10.2,3,string3,2014-06-15 02:00:00
4,10.3,4,string4,2015-06-15 03:00:00
5,10.4,5,string5,2016-06-15 04:00:00
"""

TABLE_WEIRD = """
a_dict,an_array,a_geopoint,a_date,a_time
{"test":3},"[1,2,3]","45.2,26.1","2014-06-15","02:00:00"
"""

@testset "Inference of a Schema from a table" begin

    @testset "A minimal Schema" begin
        t = Table(IOBuffer(TABLE_MIN))
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "integer"
        @test s.fields[2].typed == "number"
        @test s.fields[3].typed == "integer"
        @test s.fields[4].typed == "string"
        @test s.fields[5].typed == "string" # TODO: date
    end

    @testset "Inline with minimal schema" begin
        t = Table(IOBuffer(TABLE_MIN))
        TableSchema.infer(t)
        @test t.schema.fields[1].typed == "integer"
    end

    @testset "From a weird Table" begin
        t = Table(IOBuffer(TABLE_WEIRD))
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "object"
        @test s.fields[2].typed == "array"
        @test s.fields[3].typed == "geopoint"
        @test s.fields[4].typed == "date"
        @test s.fields[5].typed == "time"
    end

    @testset "One that does not meet constraints" begin
        t = Table("../data/data_constraints.csv")
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "integer"
        @test s.fields[2].typed == "number"
        @test s.fields[3].typed == "integer"
        @test s.fields[4].typed == "string"
        @test s.fields[5].typed == "string"
    end

    @testset "From data in a basic file" begin
        t = Table("../data/data_infer.csv")
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "integer"
        @test s.fields[2].typed == "integer"
        @test s.fields[3].typed == "string"
    end

    @testset "From a UTF8 file" begin
        t = Table("../data/data_infer_utf8.csv")
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "integer"
        @test s.fields[2].typed == "integer"
        @test s.fields[3].typed == "string"
    end

    @testset "From a ISO-8859-7 file" begin
        t = Table("../data/data_infer_iso-8859-7.csv")
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "integer"
        @test s.fields[2].typed == "integer"
        @test s.fields[3].typed == "string"
    end

    @testset "From 'row limit' file" begin
        t = Table("../data/data_infer_row_limit.csv")
        tr = TableSchema.read(t, cast=false)
        s = Schema()
        TableSchema.infer(s, tr, t.headers)
        @test s.fields[1].typed == "string"
        @test s.fields[2].typed == "string"
        @test s.fields[3].typed == "string"
    end

end
