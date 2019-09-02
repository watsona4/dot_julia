abstract type AbstractOS end
abstract type Unix <: AbstractOS end
abstract type BSD <: Unix end

abstract type Windows <: AbstractOS end
abstract type MacOS <: BSD end
abstract type Linux <: BSD end

if Sys.iswindows()
    const LIBRARY_EXT = "dll"
    const DEPS = "windows"
elseif Sys.islinux()
    const LIBRARY_EXT = "so"
    const DEPS = "linux"
elseif Sys.isapple()
    const LIBRARY_EXT = "dylib"
    const DEPS = "apple"
else
    error("Unknown operating system. Cannot use HELICS.jl")
end

function extract(filename, directory)

   if Sys.iswindows()
       home = (Base.VERSION < v"0.7-") ? JULIA_HOME : Sys.BINDIR
       success(`$home/7z x $filename -y -o$directory`)
       filename = joinpath(directory, basename(filename)[1:end-4])
       success(`$home/7z x $filename -y -ttar -o$directory`)
   else
       success(`tar -xvf $filename -C $directory`)
   end

end

function get_libraries(url=String, libraries::Vector{String}=String[], deps=DEPS)
    filename = "tmp.tar.bz2"
    filename = joinpath(@__DIR__, filename) |> abspath
    Base.download(url, filename)
    directory = joinpath(@__DIR__, "output") |> abspath
    mkpath(directory)
    extract(filename, directory)
    rm(filename, force=true)

    if length(libraries) == 0
        for library_name in readdir(directory)
            if endswith(library_name, ".$LIBRARY_EXT")
                push!(libraries, library_name)
            end
        end
    end

    for library_name in libraries
        source = joinpath(directory, library_name)
        target = joinpath(@__DIR__, deps, basename(library_name))
        cp(source, target, force=true, follow_symlinks=true)
    end

    rm(directory, force=true, recursive=true)

end

function Base.download(::Type{MacOS})

    mkpath(joinpath(@__DIR__, DEPS))

    url = "https://anaconda.org/gmlc-tdc/helics/2.0.0/download/osx-64/helics-2.0.0-py37h0a44026_0.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libhelicsSharedLib.dylib"]
                          )
                 )

    url = "https://anaconda.org/anaconda/libboost/1.67.0/download/osx-64/libboost-1.67.0-hebc422b_4.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libboost_filesystem.dylib", "libboost_program_options.dylib", "libboost_system.dylib"]
                          )
                 )

    url = "https://anaconda.org/anaconda/libsodium/1.0.16/download/osx-64/libsodium-1.0.16-h3efe00b_0.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libsodium.23.dylib"]
                          )
                 )

    url = "https://anaconda.org/anaconda/zeromq/4.3.1/download/osx-64/zeromq-4.3.1-h0a44026_3.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libzmq.5.dylib"]
                          )
                 )

    println("Success")

end

function Base.download(::Type{Linux})

    mkpath(joinpath(@__DIR__, DEPS))

    url = "https://anaconda.org/gmlc-tdc/helics/2.0.0/download/linux-64/helics-2.0.0-py37hf484d3e_0.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libhelicsSharedLib.so"]
                          )
                 )

    url = "https://anaconda.org/anaconda/libboost/1.67.0/download/linux-64/libboost-1.67.0-h46d08c1_4.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libboost_filesystem.so", "libboost_program_options.so", "libboost_system.so",
                            "libboost_filesystem.so.1.67.0", "libboost_program_options.so.1.67.0", "libboost_system.so.1.67.0"]
                          )
                 )

    url = "https://anaconda.org/anaconda/libsodium/1.0.16/download/linux-64/libsodium-1.0.16-h1bed415_0.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libsodium.so.23"]
                          )
                 )

    url = "https://anaconda.org/anaconda/zeromq/4.3.1/download/linux-64/zeromq-4.3.1-he6710b0_3.tar.bz2"
    get_libraries(url, map(
                           x -> joinpath("lib", x),
                           ["libzmq.so.5", "libzmq.so.5.2.1"]
                          )
                 )

    println("Success")
end

function Base.download(::Type{Windows})

    mkpath(joinpath(@__DIR__, DEPS))

    if typeof(1) === Int64
        BIT = "64"
    else
        BIT = "32"
    end

    url = "https://anaconda.org/gmlc-tdc/helics/2.0.0/download/win-$BIT/helics-2.0.0-py37h6538335_0.tar.bz2"
    get_libraries(url, ["Library/lib/helicsSharedLib.lib", "Library/bin/helicsSharedLib.dll"])

    url = "https://anaconda.org/anaconda/libboost/1.67.0/download/win-$BIT/libboost-1.67.0-hd9e427e_4.tar.bz2"
    get_libraries(url, vcat(
                            map(
                           x -> joinpath("Library/lib", x),
                           ["libboost_filesystem-vc140-mt-x$BIT-1_67.lib", "libboost_program_options-vc140-mt-x$BIT-1_67.lib", "libboost_system-vc140-mt-x$BIT-1_67.lib"]
                          ),
                            map(
                           x -> joinpath("Library/bin", x),
                           ["boost_filesystem-vc140-mt-x$BIT-1_67.dll", "boost_program_options-vc140-mt-x$BIT-1_67.dll", "boost_system-vc140-mt-x$BIT-1_67.dll"]
                          )
                    )
                )

    url = "https://anaconda.org/anaconda/libsodium/1.0.16/download/win-$BIT/libsodium-1.0.16-h9d3ae62_0.tar.bz2"
    get_libraries(url, ["Library/lib/libsodium.lib", "Library/bin/libsodium.dll"])

    url = "https://anaconda.org/anaconda/zeromq/4.3.1/download/win-$BIT/zeromq-4.3.1-h33f27b4_3.tar.bz2"
    get_libraries(url, vcat(
                            map(
                           x -> joinpath("Library/lib", x),
                           ["libzmq.lib", "libzmq-mt-4_3_1.lib", "libzmq-mt-s-4_3_1.lib"]
                          ),
                            map(
                           x -> joinpath("Library/bin", x),
                           ["libzmq.dll", "libzmq-mt-4_3_1.dll"]
                          ),
                        )
                 )

    println("Success")
end


if Sys.iswindows()
    os = Windows
elseif Sys.isapple()
    os = MacOS
else
    os = Linux
end

download(os)
