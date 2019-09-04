using Test
using VisualDL
using PyCall
@pyimport visualdl as vdl

train_logger = VisualDLLogger("tmp", 1, "train")
test_logger = as_mode(train_logger, "test")


for i in 1:3
    with_logger(train_logger) do
        @log_scalar s0=(i,i)
    end

    with_logger(test_logger) do
        @log_scalar s1=(i, -i)
    end
end

set_caption(train_logger, :s0, "This is caption of s0")
set_caption(test_logger, :s1, "This is caption of s1")

save(train_logger)
save(test_logger)

@testset "Test VisualDLLogger" begin
    reader = vdl.LogReader("tmp")

    @test reader[:modes]() == ["train", "test"]

    reader[:mode]("train")
    @test reader[:tags]("scalar") == ["s0"]
    s = reader[:scalar]("s0")
    @test s[:caption]() == "This is caption of s0"
    @test s[:ids]() == [1, 2, 3]
    @test s[:records]() == [1, 2, 3]

    reader[:mode]("test")
    @test reader[:tags]("scalar") == ["s1"]
    s = reader[:scalar]("s1")
    @test s[:ids]() == [1, 2, 3]
    @test s[:records]() == [-1, -2, -3]
end

rm("tmp"; recursive=true)