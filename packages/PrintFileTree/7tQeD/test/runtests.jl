using PrintFileTree
using Test

@testset "PrintFileTree" begin

@testset "full test" begin
    tmpdir = mktempdir()
    touch(joinpath(tmpdir, "a"))
    touch(joinpath(tmpdir, "b"))
    mkpath(joinpath(tmpdir, "c","a","a"))
    mkpath(joinpath(tmpdir, "c", "wow", "cats", "are", "so", ""))
    mkpath(joinpath(tmpdir, "c", "wow", "cats", "are", "weird"))
    touch(joinpath(tmpdir, "c", "a", "subfiles"))
    touch(joinpath(tmpdir, "c", "a", "a","subfiles"))
    mkpath(joinpath(tmpdir, "c","a","a"))
    mkpath(joinpath(tmpdir, "c","a","a"))
    touch(joinpath(tmpdir, "c", "z"))
    touch(joinpath(tmpdir, "d"))
    mkpath(joinpath(tmpdir, "e", "the", "end"))

    # Run once to make sure it doesn't crash or something.
    printfiletree(tmpdir)

    # Actually @test the output.
    output = read(`$(Base.julia_cmd()) -e "using PrintFileTree; printfiletree(raw\"$tmpdir\")"`, String)
    @test occursin(
        """$tmpdir
        ├── a
        ├── b
        ├── c
        │   ├── a
        │   │   ├── a
        │   │   │   └── subfiles
        │   │   └── subfiles
        │   ├── wow
        │   │   └── cats
        │   │       └── are
        │   │           ├── so
        │   │           └── weird
        │   └── z
        ├── d
        └── e
            └── the
                └── end

        11 directories, 6 files""",
        output)
    println(output)
end

@testset "small test" begin
    d = mktempdir()
    output = read(`$(Base.julia_cmd()) -e "using PrintFileTree; printfiletree(raw\"$d\")"`, String)
    @test occursin(
        """$d

        0 directories, 0 files""",
    output)
    println(output)
end

end
