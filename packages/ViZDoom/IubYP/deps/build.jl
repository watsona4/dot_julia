using BinaryProvider
using CxxWrap

const tarball_url = "https://github.com/mwydmuch/ViZDoom/archive/1.1.6.tar.gz"
const tarball_hash = "c127b97dec3365acbd0ff036b4011fc46c48df49b8fa984bc47acfb9303f7db3"
const deps_dir = @__DIR__
const build_dir = joinpath(@__DIR__, "usr")
const vizdoom_dir = joinpath(build_dir, "ViZDoom-1.1.6")
const verbose = "--verbose" in ARGS

install(tarball_url, tarball_hash; prefix=Prefix(build_dir), force=true, verbose=verbose)

# replace old wrapper
run(`rm -rf $(joinpath(vizdoom_dir, "src", "lib_julia"))`)
run(`cp -r $(joinpath(deps_dir, "lib_julia")) $(joinpath(vizdoom_dir, "src"))`)

const JLCxx_DIR = get(ENV, "JLCXX_DIR", joinpath(dirname(CxxWrap.jlcxx_path), "cmake", "JlCxx"))
const cmake_cmd = `cmake -DJlCxx_DIR=$(JLCxx_DIR) -DBUILD_JULIA=ON -DJulia_EXECUTABLE=$(joinpath(Sys.BINDIR, "julia")) .`
@info cmake_cmd
cd(() -> run(cmake_cmd), vizdoom_dir)
cd(() -> run(`make`), vizdoom_dir)