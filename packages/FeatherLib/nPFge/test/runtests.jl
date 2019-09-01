using FeatherLib, Missings, Dates, CategoricalArrays, Random, Arrow
using Test

temps = []

@testset "FeatherLib" begin

include("test_readwrite.jl")
include("test_arrow.jl")

GC.gc(); GC.gc()
for t in temps
    try
        rm(t)
    catch
        GC.gc()
        try
            rm(t)
        catch
        end
    end
end

# issue #34
# data = DataFrame(A=Union{Missing, String}[randstring(10) for i ∈ 1:100], B=rand(100))
# data[2, :A] = missing
# Feather.write("testfile.feather", data)
# dfo = Feather.read("testfile.feather")
# @test size(Data.schema(dfo)) == (100, 2)
# GC.gc();
# rm("testfile.feather")

# @testset "PythonRoundtrip" begin
# try
#     println("Generate a test.feather file from python...")
#     run(`docker cp runtests.py feathertest:/home/runtests.py`)
#     run(`docker exec feathertest python /home/runtests.py`)

#     println("Read test.feather into julia...")
#     run(`docker cp feathertest:/home/test.feather test.feather`)
#     df = Feather.read("test.feather")

#     dts = [Dates.DateTime(2016,1,1), Dates.DateTime(2016,1,2), Dates.DateTime(2016,1,3)]

#     @test df[:Autf8][:] == ["hey","there","sailor"]
#     @test df[:Abool][:] == [true, true, false]
#     @test df[:Acat][:] == categorical(["a","b","c"])  # these violate Arrow standard by using Int8!!
#     @test df[:Acatordered][:] == categorical(["d","e","f"])  # these violate Arrow standard by using Int8!!
#     @test convert(Vector{Dates.DateTime}, df[:Adatetime][:]) == dts
#     @test isequal(df[:Afloat32][:], [1.0, missing, 0.0])
#     @test df[:Afloat64][:] == [Inf,1.0,0.0]

#     df_ = Feather.read("test.feather"; use_mmap=false)

#     println("Writing test2.feather from julia...")
#     Feather.write("test2.feather", df)
#     df2 = Feather.read("test2.feather")

#     @test df2[:Autf8][:] == ["hey","there","sailor"]
#     @test df2[:Abool][:] == [true, true, false]
#     @test df2[:Acat][:] == categorical(["a","b","c"])  # these violate Arrow standard by using Int8!!
#     @test df2[:Acatordered][:] == categorical(["d","e","f"])  # these violate Arrow standard by using Int8!!
#     @test convert(Vector{Dates.DateTime}, df2[:Adatetime][:]) == dts
#     @test isequal(df2[:Afloat32][:], [1.0, missing, 0.0])
#     @test df2[:Afloat64][:] == [Inf,1.0,0.0]

#     println("Read test2.feather into python...")
#     @test (run(`docker cp test2.feather feathertest:/home/test2.feather`); true)
#     @test (run(`docker cp runtests2.py feathertest:/home/runtests2.py`); true)
#     @test (run(`docker exec feathertest python /home/runtests2.py`); true)
# finally
#     run(`docker stop feathertest`)
#     run(`docker rm feathertest`)
#     rm("test.feather")
#     rm("test2.feather")
# end

# end

end
