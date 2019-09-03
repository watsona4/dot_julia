@testset "Validating a Schema descriptor" begin

    @testset "Read in from JSON" begin
        s = Schema("../data/schema_valid_infer.json")
        @test length(s.fields) == 2
        @test s.fields[1].name == "id"
        @test !s.fields[2].constraints.required
        @test TableSchema.is_valid(s) == true
    end

    @testset "Created from scratch" begin
        f = Field("width")
        f.typed = "integer"
        f.constraints.required = true
        s = Schema()
        TableSchema.add_field(s, f)
        @test length(s.fields) == 1
        @test s.fields[1].constraints.required
        @test_throws SchemaError validate(s, true)
    end

    @testset "Check primary foreign keys" begin
        s = Schema("../data/schema_valid_full.json")
        @test length(s.primary_key) == 4
        @test length(s.foreign_keys) == 1
    end

    @testset "Handle schema errors" begin
        @test_throws SchemaError Schema("../data/schema_invalid_empty.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_wrong_type.json", true)
        s = Schema("../data/schema_invalid_multiple_errors.json")
        @test !(TableSchema.is_valid(s))
        @test length(s.errors) == 5
    end

    @testset "Invalid foreign keys in schema" begin
        @test_throws SchemaError Schema("../data/schema_invalid_fk_string.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_fk_array.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_fk_array_string.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_fk_array_string_ref.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_fk_array_wrong_number.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_fk_no_reference.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_fk_string_array_ref.json", true)
    end

    @testset "Invalid primary key in schema" begin
        @test_throws SchemaError Schema("../data/schema_invalid_pk_string.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_pk_array.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_pk_is_wrong_type.json", true)
        @test_throws SchemaError Schema("../data/schema_invalid_pk_no_fields.json", true)
    end

    @testset "Detailed validation errors" begin
        # TODO see https://github.com/frictionlessdata/tableschema-py/blob/c7b2125108d82029dab7bf6a31c894497837a6ac/tests/test_validate.py#L98
        s = Schema("../data/schema_invalid_pk_string.json")
        @test !(TableSchema.is_valid(s))
        @test length(s.errors) == 1
        @test s.errors[1].key == "identifier"
    end

end
@testset "Validating Table data with Schema" begin

    @testset "Check constraints" begin
        s = Schema("../data/schema_valid_missing.json")
        t = Table("../data/data_types.csv")
        tr = TableSchema.read(t, cast=false)
        @test s.fields[1].constraints.required
        @test TableSchema.checkrow(s.fields[1], tr[1,1])
        @test TableSchema.checkrow(s.fields[2], tr[2,2])
        @test TableSchema.checkrow(s.fields[3], tr[3,3])
        @test_throws ConstraintError TableSchema.checkrow(s.fields[1], "")
    end

    @testset "Schema constraint errors" begin
        s = Schema("../data/schema_valid_missing.json")
        t = Table("../data/data_constraints.csv", s)
        @test !(validate(t))
        @test length(t.errors) > 0
        @test t.errors[2].message == "unique"
        @test t.errors[2].field.name == "name"
        @test t.errors[1].message == "required"
        @test t.errors[1].field.name == "id"
    end

end
