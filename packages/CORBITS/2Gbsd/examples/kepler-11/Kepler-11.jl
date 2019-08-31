# Test comparison for Kepler-11 example
const DAYS_IN_YEAR = 365.2425
const SR_TO_AU = 0.0046491;   #  /* http://en.wikipedia.org/wiki/Solar_radius */
if VERSION >= v"0.7"
  using Pkg, Libdl
  #global const LIB_CORBITS = Libdl.find_library(["libcorbits.so"],[".",joinpath(Pkg.devdir(),"CORBITS")])
  global const LIB_CORBITS = Libdl.find_library(["libcorbits.so"],[joinpath(dirname(pathof(CORBITS)),"..")])
else
  global const LIB_CORBITS = Libdl.find_library(["libcorbits.so"],[".","..","../..","/usr/local/lib"])
end

# Radius and Mass of Kepler-11 from kepler.nasa.gov
R11 = 1.10;
M11 = 0.95;
# Periods hardwired rather than from file
P = [ 10.30375, 13.02502, 22.68719, 31.99590, 46.68876, 74.34319, 118.37774 ]
use = ones(Cint,length(P))
use[6] = 0 
a = cbrt.((P./DAYS_IN_YEAR).^2 .* M11)
r_star = R11 * SR_TO_AU
r = zeros(length(P))
e = zeros(length(P))
omega = zeros(length(P))
inc = zeros(length(P))
Omega = zeros(length(P))

function prob_of_transits_approx(a::Vector{Cdouble},r_star::Cdouble,r::Vector{Cdouble}, e::Vector{Cdouble}, 
                                 Omega::Vector{Cdouble}, omega::Vector{Cdouble}, inc::Vector{Cdouble}, use::Vector{Cint})
  @assert(length(a) == length(r) == length(e) == length(Omega) == length(omega) == length(inc) == length(use) )
  @assert(length(a) >=1 )
  local num_pl = length(a)
  return ccall( (:prob_of_transits_approx_arrays, LIB_CORBITS), Cdouble, 
      (Ptr{Cdouble}, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Cint), 
       a, r_star, r, e, Omega, omega, inc, use, num_pl)
end

      
function rand_Rayleigh(sigma::Real)
    # // inverse CDF based on http://en.wikipedia.org/wiki/Rayleigh_distribution
    return sqrt(-2.0*log(rand()) * sigma^2);
end

function prob( sigma_i::Cdouble )
  local sum = 0.0
  local NTRIALS = 10000
  for i in 1:NTRIALS
    #sum_k = 0.0
    for k in 1:length(P)
      for j in 1:length(P)
        inc[j] = rand_Rayleigh(sigma_i) * pi/180.0
        Omega[j] = 2pi*rand()
        use[j] = (k!=j) ? 1 : 0
      end # j
      val = prob_of_transits_approx(a,r_star,r,e,Omega,omega,inc,use)
      sum += val
    end # k
  end # i 
  sum /= NTRIALS
  return sum
end # prob


# Print outputs for comparison to C++ version on Kepler-11 example
#for i in linspace(0.0,6.0,61)
for i in range(0.0,stop=6.0,length=61)
   curp = prob(i *sqrt(2.0/pi) )
   print(i, ' ', curp, '\n')
end


