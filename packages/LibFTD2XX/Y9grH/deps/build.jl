# LibFTD2XX.jl
#
# Library installation script based on BinaryProvider LibFoo.jl example

using Libdl
using BinaryProvider

verbose = true

prefix = joinpath(@__DIR__, "usr")

if Sys.islinux()
    libnames = ["libftd2xx", "libftd2xx.1.4.4", "libftd2xx.so.1.4.8"]
    products = Product[LibraryProduct(joinpath(prefix, "release", "build"), libnames, :libftd2xx)]
end

if Sys.iswindows()
    if Sys.WORD_SIZE == 64
        libnames = ["ftd2xx64"]
        products = Product[LibraryProduct(joinpath(prefix, "amd64"), libnames, :libftd2xx)]
    else
        libnames = ["ftd2xx"]
        products = Product[LibraryProduct(joinpath(prefix, "i386"), libnames, :libftd2xx)]
    end
end

if Sys.isapple()
    libnames = ["libftd2xx.1.4.4"]
    products = Product[LibraryProduct(joinpath(prefix, "lib"), libnames, :libftd2xx)]
end



bin_prefix = "https://www.ftdichip.com/Drivers"
download_info = Dict(
    Linux(:aarch64, :glibc) => ("$bin_prefix/D2XX/Linux/libftd2xx-arm-v8-1.4.8.gz", "e353cfa94069dee6d5bba1c4d8a19b0fd2bf3db1e8bbe0c3b9534fdfaf7a55ed"),
    Linux(:armv7l, :glibc)  => ("$bin_prefix/D2XX/Linux/libftd2xx-arm-v7-hf-1.4.8.gz", "81c8556184e9532a3a19ee6915c3a43110dc208116967a4d3e159f00db5d16e1"),
    Linux(:i686, :glibc)    => ("$bin_prefix/D2XX/Linux/libftd2xx-i386-1.4.8.gz", "84c9aaf7288a154faf0e2814ba590ec965141c698b2a00bffc94d8e0c7ebeb4c"),
    Linux(:x86_64, :glibc)  => ("$bin_prefix/D2XX/Linux/libftd2xx-x86_64-1.4.8.gz", "815d880c5ec40904f062373e52de07b2acaa428e54fece98b31e6573f5d261a0"),
    MacOS(:x86_64)          => ("$bin_prefix/D2XX/MacOSX/D2XX1.4.4.dmg", "3327e646e71819a48fdbf72c8ced24ba99ad1eec1a609f0e9cbc6dbadd2285b6"),
    Windows(:i686)          => ("$bin_prefix/CDM/CDM%20v2.12.28%20WHQL%20Certified.zip", "82db36f089d391f194c8ad6494b0bf44c508b176f9d3302777c041dad1ef7fe6"),
    Windows(:x86_64)        => ("$bin_prefix/CDM/CDM%20v2.12.28%20WHQL%20Certified.zip", "82db36f089d391f194c8ad6494b0bf44c508b176f9d3302777c041dad1ef7fe6")
)

# First, check to see if we're all satisfied
if any(!satisfied(p; verbose=verbose) for p in products)
    try
        # Download and install binaries
        url, tarball_hash = choose_download(download_info)
        if Sys.islinux()
            install(url, tarball_hash, prefix=Prefix(prefix), force=true, verbose=verbose)
        elseif Sys.iswindows() || Sys.isapple()
            # Explicitly download
            tarball_path = joinpath(Prefix(prefix), "downloads", basename(url))
            download_verify(url, tarball_hash, tarball_path, force=true, verbose=verbose)
            if Sys.iswindows()
                # On windows, manuall unzip as .zip not handled well by BinaryProvider
                exe7z = joinpath(Sys.BINDIR, "7z.exe")
                isfile(exe7z) || error("7z.exe not in $(Sys.BINDIR)")
                run(`$exe7z x $tarball_path -o$prefix`)
            end
            if Sys.isapple()
                # On Mac, extract from disk image
                run(`./build_osx.sh`)
            end
        else
            throw(ArgumentError("Unsupported platform"))
        end
    catch e
        if typeof(e) <: ArgumentError
            error("Your platform $(Sys.MACHINE) is not supported by this package!")
        else
            rethrow(e)
        end
    end

end

# Finally, write out a deps.jl file
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
