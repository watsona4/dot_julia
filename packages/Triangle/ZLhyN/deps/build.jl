using BinDeps

isfile("deps.jl") && rm("deps.jl")

@BinDeps.setup
    libtriangle = library_dependency("libtriangle", aliases = ["libtriangle.dylib"], runtime = true)

    rootdir = BinDeps.depsdir(libtriangle)
    srcdir = joinpath(rootdir, "src")
    prefix = joinpath(rootdir, "usr")
    libdir = joinpath(prefix, "lib")
    headerdir = joinpath(prefix, "include")

    if Sys.iswindows()
        libfile = joinpath(libdir, "libtriangle.dll")
        arch = "x86"
        if Sys.WORD_SIZE == 64
            arch = "x64"
        end
        @build_steps begin
            FileRule(libfile, @build_steps begin
                 BinDeps.run(@build_steps begin
                    ChangeDirectory(srcdir)
                    `cmd /c compile.bat all $arch`
                    `cmd /c copy libtriangle.dll $libfile`
                    `cmd /c copy triangle.h $headerdir`
                    `cmd /c copy tricall.h $headerdir`
                    `cmd /c copy commondefine.h $headerdir`
                    `cmd /c compile.bat clean $arch`
            end) end) end

        provides(Binaries, URI(libfile), libtriangle)
    else 
        libname = "libtriangle.so"
        if Sys.isapple()
            libname = "libtriangle.dylib"
        end
        libfile = joinpath(libdir, libname)
        provides(BinDeps.BuildProcess, (@build_steps begin
                    FileRule(libfile, @build_steps begin
                        BinDeps.ChangeDirectory(srcdir)
                        `make clean`
                        `make`
                        `cp libtriangle.so $libfile`
                        `cp triangle.h $headerdir/`
                        `cp tricall.h $headerdir/`
                        `cp commondefine.h $headerdir/`
                        `make clean`
                    end)
                end), libtriangle)
    end

@BinDeps.install Dict(:libtriangle => :libtriangle)
