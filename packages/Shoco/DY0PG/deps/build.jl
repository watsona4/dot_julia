Sys.iswindows() && error("The Shoco C library does not support Windows")

using BinaryProvider

const verbose = "--verbose" in ARGS
const prefix = Prefix(get(filter(!isequal("verbose"), ARGS), 1, joinpath(@__DIR__, "usr")))
products = [LibraryProduct(prefix, ["libshoco"], :libshoco)]

bin_prefix = "https://github.com/ararslan/ShocoBuilder/releases/download/v0.1.0"

downloads = Dict(
    FreeBSD(:x86_64) =>
        ("$bin_prefix/Shoco.v0.1.0.x86_64-unknown-freebsd11.1.tar.gz",
         "d6b192c4e965659cac273e499a586fa4f2094de141dac3dfd192e636f7a3c2ee"),
    Linux(:aarch64, :glibc) =>
        ("$bin_prefix/Shoco.v0.1.0.aarch64-linux-gnu.tar.gz",
         "d44588e4268f36aafa05ae9a1e2c40386d0289955c4fc192663c2d857ca2663c"),
    Linux(:aarch64, :musl) =>
        ("$bin_prefix/Shoco.v0.1.0.aarch64-linux-musl.tar.gz",
         "c21ca1c265e28adec6f5e4fd630892b1f64283987bbf3170ddddece3fbe2abf8"),
    Linux(:armv7l, :glibc, :eabihf) =>
        ("$bin_prefix/Shoco.v0.1.0.arm-linux-gnueabihf.tar.gz",
         "96a21441085150c4cfcb31e4a943e5fcf8055ddcca005c364a44efaa734d7937"),
    Linux(:armv7l, :musl, :eabihf) =>
        ("$bin_prefix/Shoco.v0.1.0.arm-linux-musleabihf.tar.gz",
         "7d55f6370dad1c7e38aff06675690913156daebe45c9eb53b913f6123ab70ad6"),
    Linux(:i686, :glibc) =>
        ("$bin_prefix/Shoco.v0.1.0.i686-linux-gnu.tar.gz",
         "0d8a07d3ae4070765284ef0b2c8d3a830c17875db3b6833550163e2f64c3cf6a"),
    Linux(:i686, :musl) =>
        ("$bin_prefix/Shoco.v0.1.0.i686-linux-musl.tar.gz",
         "b0b2af8b972a1a5d6afa50acc67c7a08d6b83c5ca745cc6408c10aab293ca878"),
    Linux(:powerpc64le, :glibc) =>
        ("$bin_prefix/Shoco.v0.1.0.powerpc64le-linux-gnu.tar.gz",
         "f55a47099cd38b0ad613f71990c94fd9beeb1e45704844b1615df4b910f7cfdc"),
    Linux(:x86_64, :glibc) =>
        ("$bin_prefix/Shoco.v0.1.0.x86_64-linux-gnu.tar.gz",
         "17de1ab56a576e458632c19aec5e0e3031f988730f7208944a9b13620f38902a"),
    Linux(:x86_64, :musl) =>
        ("$bin_prefix/Shoco.v0.1.0.x86_64-linux-musl.tar.gz",
         "e8207c469fa6e0ddcc80d9123bc642f5719e804c5ae1683264af9e184a4c0c23"),
    MacOS(:x86_64) =>
        ("$bin_prefix/Shoco.v0.1.0.x86_64-apple-darwin14.tar.gz",
         "0d6f1985638accdc55c95906e2f7c646f283dd7bb996448f5a90433b74f9f75f"),
)

unsatisfied = any(p->!satisfied(p, verbose=verbose), products)

if haskey(downloads, platform_key())
    url, hash = downloads[platform_key()]
    if unsatisfied || !isinstalled(url, hash, prefix=prefix)
        install(url, hash, prefix=prefix, force=true, verbose=verbose)
    end
elseif unsatisfied
    error("Your platform ($(triplet(platform_key()))) is not supported")
end

write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
