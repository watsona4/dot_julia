function quote_string(str::AbstractString)::AbstractString
    repr(str)[2:end-1]
end



function runcmd(args::Cmd; wrap=identity)::Vector{String}
    julia = Base.julia_cmd()
    dbftp = joinpath("..", "bin", "dbftp.jl")
    lines = String[]
    cmd = `$julia $dbftp $args`
    open(wrap(cmd)) do io
        skipcount = 0
        for line in eachline(io)
            if skipcount > 0
                skipcount -= 1
                continue
            elseif startswith(line, "Julia Dropbox client")
                skipcount = 1
                continue
            elseif startswith(line, "Info: ") || startswith(line, "\rInfo: ")
                continue
            else
                push!(lines, line)
            end
        end
    end
    lines
end



@testset "Command version" begin
    lines = runcmd(`version`)
    @test length(lines) == 1
    m = match(r"^Version\s+(.*)", lines[1])
    @test m !== nothing
    version = VersionNumber(m.captures[1])
end



@testset "Option --verbose" begin
    lines = runcmd(`--verbose version`)
    @test length(lines) == 1
    m = match(r"^Version\s+(.*)", lines[1])
    @test m !== nothing
    version = VersionNumber(m.captures[1])
end



@testset "Option --debug" begin
    lines = runcmd(`--debug version`)
    @test length(lines) == 1
    m = match(r"^Version\s+(.*)", lines[1])
    @test m !== nothing
    version = VersionNumber(m.captures[1])
end



@testset "Command account" begin
    lines = runcmd(`account`)
    @test length(lines) == 1
    m = match(r"^Account: Name:\s+", lines[1])
    @test m !== nothing
end



@testset "Command du" begin
    lines = runcmd(`du`)
    @test length(lines) == 2
    m = match(r"^allocated:\s+(.*)", lines[1])
    @test m !== nothing
    m = match(r"^used:\s+(.*)", lines[2])
    @test m !== nothing
end



@testset "Command mkdir" begin
    lines = runcmd(`mkdir $folder`)
    @test length(lines) == 0
end



@testset "Command put" begin
    mktempdir() do dir
        filename = joinpath(dir, "hello")
        content = "Hello, World!\n"
        write(filename, content)
        lines = runcmd(`put $filename $folder`)
        @test length(lines) == 0

        lines = runcmd(`put $filename $folder/hello1`)
        @test length(lines) == 0

        # Upload same file again
        lines = runcmd(`put $filename $folder/hello1`)
        @test length(lines) == 0

        # Upload different file with same name
        filename1 = joinpath(dir, "hello1")
        content1 = "Hello, World 1!\n"
        write(filename1, content1)
        lines = runcmd(`put $filename1 $folder/hello1`)
        @test length(lines) == 0

        filename2 = joinpath(dir, "hello2")
        content2 = "Hello, World 2!\n"
        write(filename2, content2)
        lines = runcmd(`put $filename2 $folder/hello2`)
        @test length(lines) == 0

        dirname = joinpath(dir, "dir")
        mkdir(dirname)
        filename3 = joinpath(dirname, "hello3")
        content3 = "Hello, World 3!\n"
        write(filename3, content3)
        lines = runcmd(`put $dirname $folder`)
        @test length(lines) == 0
    end
end



@testset "Command cmp" begin
    mktempdir() do dir
        filename = joinpath(dir, "hello")
        content = "Hello, World!\n"
        write(filename, content)
        lines = runcmd(`cmp $filename $folder`)
        @test length(lines) == 0

        filename1 = joinpath(dir, "hello1")
        content1 = "Hello, World 1!\n"
        write(filename1, content1)
        lines = runcmd(`cmp $filename1 $folder/hello1`)
        @test length(lines) == 0

        lines = runcmd(`cmp $filename $folder/hello2`; wrap=ignorestatus)
        @test length(lines) == 1
        quoted_filename = quote_string(filename)
        @test lines[1] == "$quoted_filename: File size differs"

        filename2 = joinpath(dir, "hello2")
        content2 = "Hello, World 2!\n"
        write(filename2, content2)
        lines = runcmd(`cmp $filename2 $folder/hello2`)
        @test length(lines) == 0

        # TODO: compare recursively
        dirname = joinpath(dir, "dir")
        mkdir(dirname)
        filename3 = joinpath(dirname, "hello3")
        content3 = "Hello, World 3!\n"
        write(filename3, content3)
        lines = runcmd(`cmp $filename3 $folder/dir/hello3`)
        @test length(lines) == 0
    end
end



@testset "Command ls" begin
    lines = runcmd(`ls $folder`)
    @test lines == ["dir",
                    "hello",
                    "hello1",
                    "hello2",
                    ]

    lines = runcmd(`ls -R $folder`)
    @test lines == [".",
                    "dir",
                    "dir/hello3",
                    "hello",
                    "hello1",
                    "hello2",
                    ]

    lines = runcmd(`ls -l $folder`)
    @test length(lines) == 4
    @test startswith(lines[1], "d    ")
    @test startswith(lines[2], "- 14 ")
    @test startswith(lines[3], "- 16 ")
    @test startswith(lines[4], "- 16 ")
    @test endswith(lines[1], " dir")
    @test endswith(lines[2], " hello")
    @test endswith(lines[3], " hello1")
    @test endswith(lines[4], " hello2")
end



@testset "Command get" begin
    mktempdir() do dir
        filename = joinpath(dir, "hello")
        lines = runcmd(`get $folder/hello $dir`)
        @test length(lines) == 0
        content = read(filename, String)
        @test content == "Hello, World!\n"

        filename1 = joinpath(dir, "hello1")
        lines = runcmd(`get $folder/hello1 $filename1`)
        @test length(lines) == 0
        content = read(filename1, String)
        @test content == "Hello, World 1!\n"

        filename2 = joinpath(dir, "hello2")
        lines = runcmd(`get $folder/hello2 $filename2`)
        @test length(lines) == 0
        content2 = read(filename2, String)
        @test content2 == "Hello, World 2!\n"

        # TODO: download recursively
        dirname = joinpath(dir, "dir")
        mkdir(dirname)
        filename3 = joinpath(dirname, "hello3")
        lines = runcmd(`get $folder/dir/hello3 $filename3`)
        @test length(lines) == 0
        content3 = read(filename3, String)
        @test content3 == "Hello, World 3!\n"
    end
end



@testset "Command rm" begin
    lines = runcmd(`rm $folder`)
    @test length(lines) == 0
end
