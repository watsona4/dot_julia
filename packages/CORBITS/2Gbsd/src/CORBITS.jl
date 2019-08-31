# This file seems to need to exist for Julia package manager to be happy
module CORBITS

export prob_of_transits_approx

if VERSION >= v"0.7.0-"
   using Libdl
   using Pkg
   using CORBITS
   global const LIB_CORBITS = Libdl.find_library(["libcorbits.so"],[joinpath(dirname(pathof(CORBITS)),".."),"/usr/local/lib"] ) # WARNING: Assumes can find libcorbits.so
elseif VERSION >= v"0.4.0-"
   global const LIB_CORBITS = Libdl.find_library(["libcorbits.so"],[".",joinpath(Pkg.dir(),"ExoplanetsSysSim/"),joinpath(Pkg.dir(),"CORBITS/"),"/usr/local/lib"])  # WARNING: Assumes can find libcorbits.so
else
   global const LIB_CORBITS = find_library(["libcorbits.so"],[".",joinpath(Pkg.devdir(),"ExoplanetsSysSim/"),joinpath(Pkg.devdir(),"CORBITS/"),"/usr/local/lib"])  # WARNING: Assumes can find libcorbits.so
end

# Call CORBITS's function prob_of_transits_approx_arrays(a, r_star, r, e, Omega, omega, inc, use)
# Returns a Cdouble (aka Float64)
# For documentation see https://github.com/jbrakensiek/CORBITS
function prob_of_transits_approx(a::Vector{Cdouble},r_star::Cdouble,r::Vector{Cdouble}, e::Vector{Cdouble},
                                 Omega::Vector{Cdouble}, omega::Vector{Cdouble}, inc::Vector{Cdouble}, use::Vector{Cint})
  @assert(length(a) == length(r) == length(e) == length(Omega) == length(omega)
== length(inc) >= length(use) )
  @assert(length(use) >=1 )
  num_pl = length(use)
  return ccall( (:prob_of_transits_approx_arrays, LIB_CORBITS), Cdouble,
      (Ptr{Cdouble}, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Cint),
       a, r_star, r, e, Omega, omega, inc, use, num_pl)
end



end # module

