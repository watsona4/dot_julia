##### Beginning of file

import Test # stdlib

Test.@test( isdir(PredictMDExtra.package_directory()) )

Test.@test( isdir(PredictMDExtra.package_directory("ci")) )

Test.@test( isdir(PredictMDExtra.package_directory("ci", "travis")) )

Test.@test( isdir(PredictMDExtra.package_directory(TestModuleA)) )

Test.@test( isdir(PredictMDExtra.package_directory(TestModuleB)) )

Test.@test( isdir( PredictMDExtra.package_directory(
            TestModuleB, "directory2",
            ) ) )

Test.@test( isdir( PredictMDExtra.package_directory(
            TestModuleB, "directory2", "directory3",
            ) ) )

Test.@test_throws(
    ErrorException,
    PredictMDExtra.package_directory(TestModuleC),
    )

##### End of file
