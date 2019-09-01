# This file contains promotion rules that perhaps do not warrant
# explicity documentation. The basic idea is to have Quantities of
# DutyCycles of Measurements or of primitive types.

# promote NoDimNum to CoherentDutyCycle
Base.promote_rule(::Type{V1}, ::Type{CoherentDutyCycle{T,U,V2}}) where {
    V1<:NoDimNum,T<:Number,U<:Real,V2<:NoDimNum
} = CoherentDutyCycle{T,U,promote_type(V1,V2)}
# promote NoDimNum to IncoherentDutyCycle
Base.promote_rule(::Type{V1}, ::Type{IncoherentDutyCycle{T,U,V2}}) where {
    V1<:NoDimNum,T<:Number,U<:Real,V2<:NoDimNum
} = IncoherentDutyCycle{T,U,promote_type(V1,V2)}

# promote Unitful.Quantity of NoDimNum to Unitful.Quantities of
# DutyCycle
#Base.promote_rule(
#    ::Type{Quantity{QT,QD,QU}},
#    ::Type{Quantity{DutyCycle{T,U,V},QD2,QU2}}
#) where {
#    QT<:NoDimNum,QD,QU,T<:Number,U<:Real,V<:NoDimNum,QD2,QU2
#} = Quantity{DutyCycle{T,U,promote_type(QT, V)}}

# promote CoherentDutyCycle to CoherentDutyCycle
function Base.promote_rule(
    ::Type{CoherentDutyCycle{T1,U1,V1}},
    ::Type{CoherentDutyCycle{T2,U2,V2}}
) where {
    T1<:Number,U1<:Real,V1<:NoDimNum,
    T2<:Number,U2<:Real,V2<:NoDimNum
}
    T = promote_type(T1, T2)
    U = promote_type(U1, U2)
    V = promote_type(V1, V2)
    return CoherentDutyCycle{T,U,V}
end
# promote CoherentDutyCycle to IncoherentDutyCycle (WARNING: This
# incurs loss of phase information but appears to be necessary to
# e.g. add an incoherent and a coherent DutyCycle)
function Base.promote_rule(
    ::Type{IncoherentDutyCycle{T1,U1,V1}},
    ::Type{CoherentDutyCycle{T2,U2,V2}}
) where {
    T1<:Number,U1<:Real,V1<:NoDimNum,
    T2<:Number,U2<:Real,V2<:NoDimNum
}
    T = promote_type(T1, T2)
    U = promote_type(U1, U2)
    V = promote_type(V1, V2)
    return IncoherentDutyCycle{T,U,V}
end
# promote IncoherentDutyCycle to IncoherentDutyCycle
function Base.promote_rule(
    ::Type{IncoherentDutyCycle{T1,U1,V1}},
    ::Type{IncoherentDutyCycle{T2,U2,V2}}
) where {
    T1<:Number,U1<:Real,V1<:NoDimNum,
    T2<:Number,U2<:Real,V2<:NoDimNum
}
    T = promote_type(T1, T2)
    U = promote_type(U1, U2)
    V = promote_type(V1, V2)
    return IncoherentDutyCycle{T,U,V}
end
