using Test

testlist = [
    ("rootfunction.jl", "Root Function Tests"),
    ("operationpoint.jl", "Operation Point Tests"),
]

@testset "$desc" for (file, desc) in testlist
    @time include(file)
end
