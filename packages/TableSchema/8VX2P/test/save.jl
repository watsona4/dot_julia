TABLE_MIN = """id,height,age,name,occupation
1,10.0,1,string1,2012-06-15 00:00:00
2,10.1,2,string2,2013-06-15 01:00:00
3,10.2,3,string3,2014-06-15 02:00:00
4,10.3,4,string4,2015-06-15 03:00:00
5,10.4,5,string4,2016-06-15 04:00:00
"""

@testset "Saving schema and data" begin

    tempfile_schema = tempname()
    tempfile_data = tempname()
    @debug "Saving schema to $tempfile_schema"
    @debug "Saving data to $tempfile_data"

    @testset "Save schema to a target file" begin
        t = Table(IOBuffer(TABLE_MIN))
        infer(t)
        save(t.schema, tempfile_schema)
        s = Schema(tempfile_schema)
        @test TableSchema.is_valid(s) == true
    end

    @testset "Read schema back in and validate" begin
        s = Schema(tempfile_schema)
        @test TableSchema.is_valid(s) == true
        t = Table(IOBuffer(TABLE_MIN), s)
        @test validate(t)
    end

    @testset "Save and reopen table data" begin
        t = Table(IOBuffer(TABLE_MIN))
        infer(t)
        save(t, tempfile_data)
        save(t.schema, tempfile_schema)
        # Reload data and check the schema
        s = Schema(tempfile_schema)
        t2 = Table(tempfile_data, s)
        @test validate(t2)
    end

end
