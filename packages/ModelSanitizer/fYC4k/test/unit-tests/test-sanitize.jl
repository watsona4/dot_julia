import ModelSanitizer
import Test

struct Foo end

Test.@test ModelSanitizer._get_property(Foo(), :a) isa Nothing
Test.@test !ModelSanitizer._is_iterable(typeof(1.0))
Test.@test !ModelSanitizer._is_iterable(typeof('a'))
Test.@test !ModelSanitizer._is_iterable(Foo)
Test.@test !ModelSanitizer._is_indexable(typeof(1.0))
Test.@test !ModelSanitizer._is_indexable(typeof('a'))
Test.@test !ModelSanitizer._is_indexable(Foo)

ModelSanitizer._sanitize_indexable_with_check_assigned!([1,2,3], ModelSanitizer.Data[], ModelSanitizer._DataElements(0))
ModelSanitizer._sanitize_indexable_with_check_assigned!(Foo(), ModelSanitizer.Data[], ModelSanitizer._DataElements(0))
ModelSanitizer._sanitize_indexable_without_check_assigned!([1,2,3], ModelSanitizer.Data[], ModelSanitizer._DataElements(0))
ModelSanitizer._sanitize_indexable_without_check_assigned!(Foo(), ModelSanitizer.Data[], ModelSanitizer._DataElements(0))

ModelSanitizer._is_iterable(::Type{<:Foo}) = true
ModelSanitizer._sanitize_iterable!(Foo(), ModelSanitizer.Data[], ModelSanitizer._DataElements(0))

ModelSanitizer._has_isassigned(::Type{<:Foo}) = true
ModelSanitizer._sanitize_indexable!(Foo(), ModelSanitizer.Data[], ModelSanitizer._DataElements(0))
