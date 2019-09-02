import DataFrames
import ModelSanitizer
import Test

a = DataFrames.DataFrame()

a[:x] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
a[:y] = [10, 20, 30, 40, 50, 60, 70, 80, 90]
a[:z] = [100, 200, 300, 400, 500, 600, 700, 800, 900]

Test.@test a[1, :x] == 1
Test.@test a[2, :x] == 2
Test.@test a[3, :x] == 3
Test.@test a[4, :x] == 4
Test.@test a[5, :x] == 5
Test.@test a[6, :x] == 6
Test.@test a[7, :x] == 7
Test.@test a[8, :x] == 8
Test.@test a[9, :x] == 9

Test.@test a[1, :y] == 10
Test.@test a[2, :y] == 20
Test.@test a[3, :y] == 30
Test.@test a[4, :y] == 40
Test.@test a[5, :y] == 50
Test.@test a[6, :y] == 60
Test.@test a[7, :y] == 70
Test.@test a[8, :y] == 80
Test.@test a[9, :y] == 90

Test.@test a[1, :z] == 100
Test.@test a[2, :z] == 200
Test.@test a[3, :z] == 300
Test.@test a[4, :z] == 400
Test.@test a[5, :z] == 500
Test.@test a[6, :z] == 600
Test.@test a[7, :z] == 700
Test.@test a[8, :z] == 800
Test.@test a[9, :z] == 900

ModelSanitizer.sanitize!(ModelSanitizer.Model(a), ModelSanitizer.Data(a))

for column in names(a)
    Test.@test all(a[:, column] .== 0)
end

Test.@test a[1, :x] == 0
Test.@test a[2, :x] == 0
Test.@test a[3, :x] == 0
Test.@test a[4, :x] == 0
Test.@test a[5, :x] == 0
Test.@test a[6, :x] == 0
Test.@test a[7, :x] == 0
Test.@test a[8, :x] == 0
Test.@test a[9, :x] == 0

Test.@test a[1, :y] == 0
Test.@test a[2, :y] == 0
Test.@test a[3, :y] == 0
Test.@test a[4, :y] == 0
Test.@test a[5, :y] == 0
Test.@test a[6, :y] == 0
Test.@test a[7, :y] == 0
Test.@test a[8, :y] == 0
Test.@test a[9, :y] == 0

Test.@test a[1, :z] == 0
Test.@test a[2, :z] == 0
Test.@test a[3, :z] == 0
Test.@test a[4, :z] == 0
Test.@test a[5, :z] == 0
Test.@test a[6, :z] == 0
Test.@test a[7, :z] == 0
Test.@test a[8, :z] == 0
Test.@test a[9, :z] == 0
