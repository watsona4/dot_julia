# coefficients a_0, ..., a_9
let
  pdTableI = [ -0.5000000002 ;
                0.3333333343 ;
               -0.2499998565 ;
                0.1999997049 ;
               -0.1666848753 ;
                0.1428833286 ;
               -0.1241963125 ;
                0.1101687109 ;
               -0.1142650302 ;
                0.1055093006 ]

  # factorials of 0--9
  pdFactorials = [ 1; 1; 2; 6; 24; 120; 720; 5040; 40320; 362880 ]

  invSqrt2Pi = 1/sqrt(2*π)
  inv12 = 1/12
  inv360 = 1/360
  inv1260 = 1/1260

  @inline function procedureF(K::Int64, μ::Float64, s::Float64, ω::Float64,
    c0::Float64, c1::Float64, c2::Float64, c3::Float64)
    ## 1. Poisson probabilities
    px::Float64 = 0.0
    py::Float64 = 0.0
    if K < 10
      px = -μ
      py = μ^K/pdFactorials[K+1]
    else
      KSq::Float64 = K*K
      KCubed::Float64 = K*KSq
      KFived::Float64 = KCubed * KSq
      δ::Float64 = inv12/K - inv360/KCubed + inv1260/KFived
      V::Float64 = (μ-K)/K
      if abs(V) > 0.25
        px = K*log(1+V) - μ + K - δ
      else
        ws::Float64 = 0.0
        Vj::Float64 = 1.0
        for j = 0:9
          ws += pdTableI[j+1]*Vj
          Vj *= V
        end
        px = K*V*V*ws - δ
      end
      py = 1/sqrt(2*π*K)
    end
    ## 2. Discrete normal probabilities
    X::Float64 = (K - μ + 0.5)/s
    XSq::Float64 = X*X
    fx::Float64 = -0.5*XSq ## typo in paper omits minus sign!
    fy::Float64 = ω*(((c3*XSq + c2)*XSq + c1)*XSq + c0)
    return px, py, fx, fy
  end

  inv24 = 1/24
  inv7 = 1/7

  @inline function caseA(μ::Float64, rng::RNG) where RNG <: AbstractRNG
    s::Float64 = sqrt(μ)
    d::Float64 = 6*μ*μ
    L::Int64 = floor(Int64, μ - 1.1484)
    ## Normal sample
    G::Float64 = μ + s*randn(rng)
    U::Float64 = 0.0
    K::Int64 = 0
    if G >= 0
      K = floor(Int64, G)
      ## Immediate acceptance
      if K >= L return K end
      U = rand(rng)
      ## Squeeze acceptance
      if d*U >= (μ - K)^3 return K end
    end
    ## Preparations for Q and H
    ω::Float64 = invSqrt2Pi/s
    b1::Float64 = inv24/μ
    b2::Float64 = 0.3*b1*b1
    c3::Float64 = inv7*b1*b2
    c2::Float64 = b2 - 15*c3
    c1::Float64 = b1 - 6*b2 + 45*c3
    c0::Float64 = 1 - b1 + 3*b2 - 15*c3
    c::Float64 = 0.1069/μ
    px::Float64 = 0.0
    py::Float64 = 0.0
    fx::Float64 = 0.0
    fy::Float64 = 0.0
    if G >= 0
      px, py, fx, fy = procedureF(K, μ, s, ω, c0, c1, c2, c3)
      ## Quotient acceptance
      if fy*(1-U) <= py*exp(px-fx) return K end
    end
    ## Double exponential sample
    while (true)
      E::Float64 = randexp(rng)
      U = 2*rand(rng) - 1
      T::Float64 = 1.8 + E*sign(U)
      if T <= -0.6744
        continue
      end
      K = floor(Int64, μ + s*T)
      px, py, fx, fy = procedureF(K, μ, s, ω, c0, c1, c2, c3)
      ## Hat acceptance
      if c*abs(U) <= py*exp(px+E) - fy*exp(fx+E)
        return K
      end
    end
  end

  ## modification: no table, just inversion.
  @inline function caseB(μ::Float64, rng::RNG) where RNG <: AbstractRNG
    p::Float64 = exp(-μ)
    q::Float64 = p
    U::Float64 = rand(rng)
    K::Int64 = 0
    while U > q
      K += 1
      p *= μ/K
      q += p
    end
    return K
  end

  ## The algorithm from
  ## Ahrens, J.H. and Dieter, U., 1982. Computer generation of Poisson deviates
  ## from modified normal distributions. ACM Transactions on Mathematical
  ## Software (TOMS), 8(2), pp. 163-179.
  ## This is suitable when μ changes every invocation. Modifications or
  ## alternative algorithms should be used for the case where many Poisson
  ## variates are required for the same μ
  global @inline function samplePoisson(μ::Float64,
      rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
    if μ >= 10.0
      return caseA(μ, rng)
    else
      return caseB(μ, rng)
    end
  end
end
