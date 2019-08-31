using BinDeps
using Compat
import Compat.Sys

@BinDeps.setup

freetype = library_dependency("freetype", aliases = ["libfreetype", "libfreetype-6"])
fontconfig = library_dependency("fontconfig", aliases = ["libfontconfig-1", "libfontconfig", "libfontconfig.so.1"], depends = [freetype])


if Sys.isapple()
    using Homebrew
    provides(Homebrew.HB, "freetype", freetype, os = :Darwin)
    FONTCONFIG_FILE = joinpath(Homebrew.prefix(), "etc", "fonts", "fonts.conf")
    provides(Homebrew.HB, "fontconfig", fontconfig, os = :Darwin, onload="const FONTCONFIG_FILE = \"$FONTCONFIG_FILE\"\n")
end

if Sys.iswindows()
    using WinRPM
    provides(WinRPM.RPM, "libfreetype6", freetype, os = :Windows)
    provides(WinRPM.RPM, "fontconfig", fontconfig, os = :Windows)
end

# System Package Managers
provides(AptGet,
    Dict(
        "libfontconfig1" => fontconfig
    ))

provides(Yum,
    Dict(
        "fontconfig" => fontconfig
    ))

provides(Zypper,
    Dict(
        "libfontconfig" => fontconfig
    ))

provides(Sources,
    Dict(
        URI("http://download.savannah.gnu.org/releases/freetype/freetype-2.4.11.tar.gz") => freetype,
        URI("http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.2.tar.gz") => fontconfig
    ))

xx(t...) = (Sys.iswindows() ? t[1] : (Sys.islinux() || length(t) == 2) ? t[2] : t[3])

provides(BuildProcess,
    Dict(
        Autotools(libtarget = xx("objs/.libs/libfreetype.la","libfreetype.la")) => freetype,
        Autotools(libtarget = "src/libfontconfig.la") => fontconfig
    ))

@BinDeps.install Dict(:fontconfig => :jl_libfontconfig)
