import DataFrames
import ModelSanitizer
import Test

struct Bar{T}
    x::T
end

x1 = [[[], [], [1]], [[], 10, 3, 4], [], [], [8], [1]]
x2 = [[], [[8], [1], [1], [], Bar([[[[[11, [12]]]], [[5], [7, 2]]]])], [], [8], [], []]
x3 = [[], [], [[DataFrames.DataFrame(:x => [6])]], [], 9, [], [[], [], [[[], [[4, 1]]]]]]

data = ModelSanitizer.Data[ModelSanitizer.Data(x1),
                           ModelSanitizer.Data(x2),
                           ModelSanitizer.Data(x3)]

elements = ModelSanitizer._elements(data)

Test.@test 1 in elements.v
Test.@test 2 in elements.v
Test.@test 3 in elements.v
Test.@test 4 in elements.v
Test.@test 5 in elements.v
Test.@test 6 in elements.v
Test.@test 7 in elements.v
Test.@test 8 in elements.v
Test.@test 9 in elements.v
Test.@test 10 in elements.v
Test.@test 11 in elements.v
Test.@test 12 in elements.v

Test.@test ModelSanitizer._how_many_elements_occur_in_this_array(elements, []) == 0
Test.@test ModelSanitizer._how_many_elements_occur_in_this_array(elements, [0]) == 0
Test.@test ModelSanitizer._how_many_elements_occur_in_this_array(elements, [0, 1]) == 1
Test.@test ModelSanitizer._how_many_elements_occur_in_this_array(elements, [0, 2, 4]) == 2
Test.@test ModelSanitizer._how_many_elements_occur_in_this_array(elements, [1, 3, 5, 0]) == 3

ModelSanitizer._elements_indexable_with_check_assigned!(Any[], [1, 2, 3])
ModelSanitizer._elements_indexable_with_check_assigned!(Any[], Bar(0))
ModelSanitizer._elements_indexable_without_check_assigned!(Any[], [1, 2, 3])
ModelSanitizer._elements_indexable_without_check_assigned!(Any[], Bar(0))

ModelSanitizer._is_iterable(::Type{<:Bar}) = true
ModelSanitizer._elements_iterable!(Any[], Bar(0))

ModelSanitizer._has_isassigned(::Type{<:Bar}) = true
ModelSanitizer._is_indexable(::Type{<:Bar}) = false
ModelSanitizer._elements_indexable!(Any[], Bar(0))
