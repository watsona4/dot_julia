using DifferenceLists
using Test

@test collect(dl(1, 2, 3)) == [1,2,3]
@test collect(dl()) == []
@test collect(dl(1)) == [1]
@test collect(dl(1, dl(2, 3), 4)) == [1, dl(2, 3), 4]
@test collect(todl([1, 2, 3])) == [1, 2, 3]
@test collect(push(push(dl(7, 8, 9), 1), 2)) == [7,8,9,1,2]
@test collect(pushfirst(pushfirst(dl(7, 8, 9), 2), 1)) == [1, 2, 7, 8, 9]
@test collect(concat(dl(1, 2), dl(3, 4))) == [1,2,3,4]
@test collect(dl(1, 2)(dl(3, 4), dl(5, 6, 7))) == [1, 2, 3, 4, 5, 6, 7]
