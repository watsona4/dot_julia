import ModelSanitizer
import Test

a = Any[1, 2, 3, 4]
Test.@test eltype(a) == Any
Test.@test eltype(a) != Int
a_fixed = ModelSanitizer._fix_vector_type(a)
Test.@test eltype(a_fixed) != Any
Test.@test eltype(a_fixed) == Int

Test.@test !ModelSanitizer._compare(1.0, missing)
Test.@test !ModelSanitizer._compare(missing, 2.0)
Test.@test !ModelSanitizer._compare(missing, missing)
