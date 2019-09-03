module RNGPool

import Random123.Threefry4x

const RNG = Threefry4x{UInt64, 20}

let
  engines::Vector{RNG} = Vector{RNG}(undef, 0)
  global function getRNG()
    @inbounds return engines[Threads.threadid()]
  end
  global function getRNG(i::Int64)
    @inbounds return engines[i]
  end
  global function setRNGs(v::Int64)
    Threads.@threads for i = 1:length(engines)
      seed = (0,0,0,v+i)
      @inbounds engines[Threads.threadid()] = Threefry4x(seed)
    end
  end
  ## happens at runtime to avoid false sharing
  global function initializeRNGs()
    engines = Vector{RNG}(undef, Threads.nthreads())
    Threads.@threads for i = 1:length(engines)
      @inbounds engines[Threads.threadid()] = Threefry4x()
    end
  end
end

function __init__()
  initializeRNGs()
end

export RNG, getRNG, setRNGs

end
