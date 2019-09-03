DESCRIPTOR_MIN = Dict("fields" => [
    Dict( "name" => "id" ),
    Dict( "name" => "height", "type" => "integer" )
])

DESCRIPTOR_MAX = Dict(
    "fields" => [
        Dict( "name" => "id", "type" => "string",
            "constraints" => Dict( "required" => true )
        ),
        Dict( "name" => "height", "type" => "number" ),
        Dict( "name" => "age", "type" => "integer" ),
        Dict( "name" => "name", "type" => "string" ),
        Dict( "name" => "occupation", "type" => "string" )
    ],
    "primaryKey" => [ "id" ],
    "foreignKeys" => [ Dict(
        "fields" => [ "name" ],
        "reference" => Dict(
            "resource" => "",
            "fields" => [ "id" ]
        )
    ) ],
    "missingValues" => ["", "-", "null"]
)

@testset "Read a Table Schema descriptor" begin

    @testset "Minimal from dictionary" begin
        s = Schema(DESCRIPTOR_MIN)
        @test length(s.fields) == 2
        f1 = s.fields[1]
        @test f1.name == "id"
        @test f1.typed == "string"
        f2 = s.fields[2]
        @test f2.typed == "integer"
        @test !f2.constraints.required
    end

    @testset "Parsed from a JSON string" begin
        s = Schema("../data/schema_valid_infer.json")
        @test length(s.fields) == 2
        @test s.fields[1].name == "id"
        @test !s.fields[2].constraints.required
    end

    @testset "Full descriptor from JSON" begin
        s = Schema("../data/schema_valid_full.json")
        @test length(s.fields) == 15
        @test length(s.primary_key) == 4
    end

    @testset "Missing values and constraints" begin
        s = Schema("../data/schema_valid_missing.json")
        @test length(s.fields) == 5
        @test length(s.primary_key) == 1
        @test length(s.missing_values) == 3
        @test s.fields[1].constraints.required
        @test !(s.fields[1].constraints.unique)
    end

end

@testset "Field value casting" begin
    import TableSchema: cast_by_type, cast_value, cast_row, CastError

    @testset "Cast functions" begin
        @test cast_by_type(Nothing, "any", "", Dict()) == Nothing

        @test cast_by_type(true, "boolean", "", Dict())
        @test cast_by_type("true", "boolean", "", Dict())
        @test isa(cast_by_type("", "boolean", "", Dict()), CastError)

        @test cast_by_type(123, "integer", "", Dict()) == 123
        @test cast_by_type("123", "integer", "", Dict()) == 123
        @test isa(cast_by_type("a", "integer", "", Dict()), CastError)

        @test cast_by_type(123, "number", "", Dict()) == 123.0
        @test cast_by_type("12.3", "number", "", Dict()) == 12.3
        @test isa(cast_by_type("a", "number", "", Dict()), CastError)

        @test cast_by_type("{\"a\":1}", "object", "", Dict()) == Dict("a"=>1)
        @test isa(cast_by_type("[\"a\",1]", "object", "", Dict()), CastError)

        @test cast_by_type(123, "string", "", Dict()) == "123"
        @test cast_by_type("123", "string", "", Dict()) == "123"
        @test isa(cast_by_type([1,2], "string", "", Dict()), CastError)
    end

    @testset "Cast row" begin
        s = Schema(DESCRIPTOR_MAX)
        source = ["string", "10.2", "1", "string", "string"]
        target = ["string", 10.2, 1, "string", "string"]
        @test cast_value(s.fields[1], "test", false) == "test"
        @test cast_row(s, source, false, false) == target
    end

    @testset "Cast row too short or long" begin
        s = Schema(DESCRIPTOR_MAX)
        source = ["string", "10.2", "1", "string"]
        @test_throws CastError cast_row(s, source, false, false)
        source = ["string", "10.2", "1", "string", "string", "string"]
        @test_throws CastError cast_row(s, source, false, false)
    end

    @testset "Cast row incorrect type" begin
        s = Schema(DESCRIPTOR_MAX)
        source = ["string", "notedecimal", "1", [1,2], "string"]
        @test_throws CastError cast_row(s, source, false, false)
        try
            cast_row(s, source, false, false)
        catch e
            if isa(e, CastError)
                @test length(e.errors) == 2
            else
                throw(e)
            end
        end
    end
end
