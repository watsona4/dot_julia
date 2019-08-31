using Libdl

oldwdir = pwd()

@show CCLUSTER_VERSION = "master"

pkgdir = dirname(dirname(@__FILE__))
wdir = joinpath(pkgdir, "deps")
vdir = joinpath(pkgdir, "local")
# NemoLibsDir = joinpath(pkgdir, "../../packages/Nemo/9nu4c/deps/usr")
NemoLibsDir = Base.find_package("Nemo")
NemoLibsDir = Base.Filesystem.dirname(NemoLibsDir)
NemoLibsDir = Base.Filesystem.dirname(NemoLibsDir)
NemoLibsDir = joinpath( NemoLibsDir, "deps/usr" )

if Sys.isapple() && !("CC" in keys(ENV))
   ENV["CC"] = "clang"
   ENV["CXX"] = "clang++"
end

if !ispath(vdir)

    mkdir(vdir)

    if !ispath(joinpath(vdir, "lib"))
        mkdir(joinpath(vdir, "lib"))
    end
else
    println("Deleting old $vdir")
    rm(vdir, force=true, recursive=true)
    mkdir(vdir)
    mkdir(joinpath(vdir, "lib"))
end

LDFLAGS = "-Wl,-rpath,$vdir/lib -Wl,-rpath,\$\$ORIGIN/../share/julia/site/v$(VERSION.major).$(VERSION.minor)/Nemo/local/lib"
DLCFLAGS = "-fPIC -fno-common"

# INSTALL CCLUSTER #temp

cd(wdir)

function download_dll(url_string, location_string)
   try
      run(`curl -o $(location_string) -L $(url_string)`)
   catch
      download(url_string, location_string)
   end
end

cd(wdir)

if !Sys.iswindows()
  println("Cloning Ccluster ... ")
  try
    run(`git clone https://github.com/rimbach/Ccluster.git`)
    cd(joinpath("$wdir", "Ccluster"))
    run(`git checkout $CCLUSTER_VERSION`)
    cd(wdir)
  catch
    if ispath(joinpath("$wdir", "Ccluster"))
      #open(`patch -R --forward -d arb -r -`, "r", open("../deps-PIE-ftbfs.patch"))
      cd(joinpath("$wdir", "Ccluster"))
      run(`git fetch`)
      run(`git checkout $CCLUSTER_VERSION`)
      cd(wdir)
    end
  end
# #   open(`patch --forward -d arb -r -`, "r", open("../deps-PIE-ftbfs.patch"))
  println("DONE")
end

cd(wdir)

if Sys.iswindows()
    if Int == Int32
        println("No binaries for 32 bits windows yet ... ")
    else
        println("downloading binaries ... ")
#         download_dll("https://cims.nyu.edu/~imbach/libs/libgmp-10.dll", joinpath(vdir, "lib", "libgmp-10.dll"))
#         download_dll("https://cims.nyu.edu/~imbach/libs/libmpfr-6.dll", joinpath(vdir, "lib", "libmpfr-6.dll"))
#         download_dll("https://cims.nyu.edu/~imbach/libs/libflint-13.dll", joinpath(vdir, "lib", "libflint-13.dll"))
#         download_dll("https://cims.nyu.edu/~imbach/libs/libarb-2.dll", joinpath(vdir, "lib", "libarb-2.dll"))
        download_dll("https://cims.nyu.edu/~imbach/libs/libccluster.dll", joinpath(vdir, "lib", "libccluster.dll"))
        try
            run(`ln -sf $NemoLibsDir\\bin\\libflint-13.dll $vdir\\lib\\libflint-13.dll`)
        catch
            cp(joinpath(NemoLibsDir, "bin", "libflint-13.dll"), joinpath(vdir, "lib", "libflint-13.dll"), remove_destination=true)
        end
        try
            run(`ln -sf $NemoLibsDir\\bin\\libarb.dll $vdir\\lib\\libarb-2.dll`)
        catch
            cp(joinpath(NemoLibsDir, "bin", "libarb.dll"), joinpath(vdir, "lib", "libarb-2.dll"), remove_destination=true)
        end
    end
    println("DONE")
else
    println("Building Ccluster ... ")
    cd(joinpath("$wdir", "Ccluster"))
    withenv("LD_LIBRARY_PATH"=>"$vdir/lib", "LDFLAGS"=>LDFLAGS) do
      run(`./configure --prefix=$vdir --disable-static --enable-shared --disable-pthread --with-flint=$NemoLibsDir --with-arb=$NemoLibsDir`)
      run(`make -j4`)
      run(`make install`)
    end
    println("DONE")
end

push!(Libdl.DL_LOAD_PATH, joinpath(vdir, "lib"))

cd(oldwdir)

#TODO
