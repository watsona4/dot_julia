@deprecate phsp_writer(args...)   iaea_writer(args...)
@deprecate Particle IAEAParticle
@deprecate PhaseSpaceIterator IAEAPhspIterator
@deprecate PhaseSpaceWriter IAEAPhspWriter
function Base.convert(::Type{ParticleType}, i::Integer) 
    @warn "convert(::Type{ParticleType}, i::Integer) is deprecated. Use ParticleType(i) instead"
    ParticleType(i)
end
