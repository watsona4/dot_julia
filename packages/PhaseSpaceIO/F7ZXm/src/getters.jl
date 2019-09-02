module Getters
using PhaseSpaceIO: IAEAParticle, EGSParticle

FIELDNAMES = union(Set(fieldnames(IAEAParticle{0,0})),
               # Set(fieldnames(EGSParticle{Float32}))
               Set([:latch, :zlast])
              )

for field in FIELDNAMES
    @eval ($field)(p) = p.$field
    @eval export $field
end

export energy
energy(p) = E(p)*weight(p)

end
