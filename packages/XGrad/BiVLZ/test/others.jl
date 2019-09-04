myfunc(x) = log(sum(x))

@testset "others" begin
    test_compare(myfunc; x=rand(2))
end
