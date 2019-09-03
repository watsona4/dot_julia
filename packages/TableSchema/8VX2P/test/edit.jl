@testset "Edit a descriptor" begin

    f1 = Field("width")
    f1.typed = "integer"
    f1.constraints.required = true
    f2 = Field("name")
    f2.typed = "string"
    f2.constraints.required = false

    @testset "Create and set field properties" begin
        s = Schema()
        TableSchema.add_field(s, f1)
        TableSchema.add_field(s, f2)
        @test length(s.fields) == 2
        @test s.fields[1].constraints.required
        @test !s.fields[2].constraints.required
    end

    @testset "Modify primary and foreign keys" begin
        s = Schema("../data/schema_valid_full.json")
        @test length(s.primary_key) == 4
        @test_throws SchemaError TableSchema.set_primary_key(s, "invalid")
        TableSchema.set_primary_key(s, "home_location")
        @test length(s.primary_key) == 4
        TableSchema.set_primary_key(s, "gender")
        @test length(s.primary_key) == 5
        TableSchema.set_foreign_key(s, ["home_location"], "country", ["name"])
        @test length(s.foreign_keys) == 2
        @test_throws SchemaError TableSchema.set_foreign_key(s, ["invalid"], "", ["name"])
    end

    @testset "Validate changes to the descriptor" begin
        s = Schema("../data/schema_valid_full.json")
        validate(s, true)
        @test TableSchema.is_valid(s)
        TableSchema.remove_field(s, "position_title")
        TableSchema.remove_field(s, "first_name")
        @test_throws SchemaError validate(s, true)
    end

end
