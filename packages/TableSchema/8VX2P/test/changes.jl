TABLE_MIN = """id,height,age,name,occupation
1,10.0,1,string1,2012-06-15 00:00:00
2,10.1,2,string2,2013-06-15 01:00:00
3,10.2,3,string3,2014-06-15 02:00:00
4,10.3,4,string4,2015-06-15 03:00:00
5,10.4,5,string4,2016-06-15 04:00:00
"""

@testset "Updating and reloading schema and data" begin

    tempfile_schema = tempname()
    @info "Saving changes to $tempfile_schema"

    @testset "Cast a schema row" begin
        @warn "Not implemented"
    end

    @testset "Commit changes to a schema" begin
        t = Table(IOBuffer(TABLE_MIN))
        infer(t)
        # Check that commit saves our descriptor
        s = Schema(t.schema.descriptor)
        @test TableSchema.is_valid(s) == false
        commit(t.schema)
        s = Schema(t.schema.descriptor)
        @test TableSchema.is_valid(s) == true
        # Make some changes to the schema ...
        @test s.fields[4].name == "name"
        s.fields[4].constraints.unique = true
        s.primary_key = ["name"]
        @test TableSchema.is_valid(s) == true
        @test s.primary_key == ["name"]
        @test s.fields[4].constraints.unique
        # ... and save them
        commit(t.schema)
        save(t.schema, tempfile_schema)
        # Reload the schema from file
        s = Schema(tempfile_schema)
        t = Table(IOBuffer(TABLE_MIN), s)
        @test TableSchema.is_valid(s) == true
        @test s.primary_key == ["name"]
        @test s.fields[4].constraints.unique
        # Table is no longer valid
        @test !validate(t)
    end

end
