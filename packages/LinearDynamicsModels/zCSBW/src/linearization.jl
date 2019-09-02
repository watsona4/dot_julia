struct ZeroOrderHoldLinearization{Dx,Du,T,TA<:SMatrix{Dx,Dx},TB<:SMatrix{Dx,Du},Tc<:SVector{Dx}}
    dt::T
    A::TA
    B::TB
    c::Tc
end
struct FirstOrderHoldLinearization{Dx,Du,T,TA<:SMatrix{Dx,Dx},TB0<:SMatrix{Dx,Du},TBf<:SMatrix{Dx,Du},Tc<:SVector{Dx}}
    dt::T
    A::TA
    B0::TB0
    Bf::TBf
    c::Tc
end

for (Tx, Tu) in ((:(StaticVector{Dx}), :(StaticVector{Du})),    # needed to avoid method ambiguity
                 (:(SVector{Dx}),      :(SVector{Du})))
    @eval function linearize(f::LinearDynamics{Dx,Du}, x::$Tx, u::$Tu;
                             keep_state_dims=:, keep_control_dims=:) where {Dx,Du}
        keep_state_dims === (:) && keep_control_dims === (:) && return f
        X, U = keep_state_dims, keep_control_dims
        Ã, B̃ = f.A[X,X], f.B[X,U]
        f̃, x̃, ũ = f(x,u)[X], x[X], u[U]
        LinearDynamics(Ã, B̃, f̃ - Ã*x̃ - B̃*ũ)
    end
end
function linearize(f::ZeroOrderHoldLinearization{Dx,Du}, x::StaticVector{Dx}, SC::StepControl{Du};
                   keep_state_dims=:, keep_control_dims=:) where {Dx,Du}
    @assert f.dt == SC.t
    keep_state_dims === (:) && keep_control_dims === (:) && return f
    X, U = keep_state_dims, keep_control_dims
    Ã, B̃ = f.A[X,X], f.B[X,U]
    f̃, x̃, ũ = f(x,SC)[X], x[X], SC.u[U]
    ZeroOrderHoldLinearization(f.dt, Ã, B̃, f̃ - Ã*x̃ - B̃*ũ)
end
function linearize(f::FirstOrderHoldLinearization{Dx,Du}, x::StaticVector{Dx}, RC::RampControl{Du};
                   keep_state_dims=:, keep_control_dims=:) where {Dx,Du}
    @assert f.dt == RC.t
    keep_state_dims === (:) && keep_control_dims === (:) && return f
    X, U = keep_state_dims, keep_control_dims
    Ã, B̃0, B̃f = f.A[X,X], f.B0[X,U], f.Bf[X,U]
    f̃, x̃, ũ0, ũf = f(x,RC)[X], x[X], RC.u0[U], RC.uf[U]
    FirstOrderHoldLinearization(f.dt, Ã, B̃0, B̃f, f̃ - Ã*x̃ - B̃0*ũ0 - B̃f*ũf)
end

for (Tx, TSC) in ((:(StaticVector{Dx}), :(StepControl{Du})),    # needed to avoid method ambiguity
                  (:(SVector{Dx}),      :(StepControl{Du,<:Any,<:SVector{Du}})))
    @eval function linearize(f::LinearDynamics{Dx,Du}, x::$Tx, SC::$TSC;
                             keep_state_dims=:, keep_control_dims=:) where {Dx,Du}
        X, U = keep_state_dims, keep_control_dims
        B, u = f.B[:,U], SC.u[U]
        eᴬᵗ, ∫eᴬᵗB = integrate_expAt_B(f.A, B, SC.t)
        _  , ∫eᴬᵗc = integrate_expAt_B(f.A, f.B*SC.u - B*u + f.c, SC.t)
        linearize(ZeroOrderHoldLinearization(SC.t, eᴬᵗ, ∫eᴬᵗB, ∫eᴬᵗc), x, StepControl(SC.t, u),
                  keep_state_dims=keep_state_dims)
    end
end
for (Tx, TRC) in ((:(StaticVector{Dx}), :(RampControl{Du})),    # needed to avoid method ambiguity
                  (:(SVector{Dx}),      :(RampControl{Du,<:Any,<:SVector{Du},<:SVector{Du}})))
    @eval function linearize(f::LinearDynamics{Dx,Du}, x::$Tx, RC::$TRC;
                             keep_state_dims=:, keep_control_dims=:) where {Dx,Du}
        if keep_control_dims === (:)
            u0, uf = RC.u0, RC.uf
            eᴬᵗ, ∫eᴬᵗB, ∫eᴬᵗBtdt⁻¹ = integrate_expAt_Bt_dtinv(f.A, f.B, RC.t)
            _  , ∫eᴬᵗc = integrate_expAt_B(f.A, f.c, RC.t)
            A  = eᴬᵗ
            B0 = ∫eᴬᵗBtdt⁻¹
            Bf = ∫eᴬᵗB - ∫eᴬᵗBtdt⁻¹
            c  = ∫eᴬᵗc
        else
            X, U = keep_state_dims, keep_control_dims
            B, u0, uf = f.B[:,U], RC.u0[U], RC.uf[U]
            b0 = f.B*RC.u0 - B*u0
            bf = f.B*RC.uf - B*uf
            B̂, û0, ûf = [B (bf - b0)], [u0; 0], [uf; 1]
            eᴬᵗ, ∫eᴬᵗB̂, ∫eᴬᵗB̂tdt⁻¹ = integrate_expAt_Bt_dtinv(f.A, B̂, RC.t)
            _  , ∫eᴬᵗc = integrate_expAt_B(f.A, f.c + b0, RC.t)
            B̂0 = ∫eᴬᵗB̂tdt⁻¹
            B̂f = ∫eᴬᵗB̂ - ∫eᴬᵗB̂tdt⁻¹
            A  = eᴬᵗ
            B0 = B̂0[:,SUnitRange(1,length(U))]
            Bf = B̂f[:,SUnitRange(1,length(U))]
            c  = ∫eᴬᵗc + B̂f[:,end]
        end
        linearize(FirstOrderHoldLinearization(RC.t, A, B0, Bf, c), x, RampControl(RC.t, u0, uf),
                  keep_state_dims=keep_state_dims)
    end
end

function linearize(f::DifferentialDynamics, x::State, u::Control; keep_state_dims=:, keep_control_dims=:)
    linearize(f, SVector(x...), SVector(u...),
              keep_state_dims=keep_state_dims, keep_control_dims=keep_control_dims)
end
function linearize(f::DifferentialDynamics, x::SVector, u::SVector;
                   keep_state_dims=:, keep_control_dims=:)
    A = ForwardDiff.jacobian(y -> f(y, u), x)    # TODO: incorporate state/control reduction before differentiating
    B = ForwardDiff.jacobian(w -> f(x, w), u)
    linearize(LinearDynamics(A, B, f(x,u) - A*x - B*u), x, u,
              keep_state_dims=keep_state_dims, keep_control_dims=keep_control_dims)
end

function linearize(f::DifferentialDynamics, x::StaticVector, SC::StepControl;
                   keep_state_dims=:, keep_control_dims=:)
    linearize(f, SVector(x), StepControl(SC.t, SVector(SC.u)),
              keep_state_dims=keep_state_dims, keep_control_dims=keep_control_dims)
end
function linearize(f::DifferentialDynamics, x::SVector, SC::StepControl{<:Any,<:Any,<:SVector};
                   keep_state_dims=:, keep_control_dims=:)
    A = ForwardDiff.jacobian(y -> propagate(f, y, SC), x)
    B = ForwardDiff.jacobian(w -> propagate(f, x, StepControl(SC.t, w)), SC.u)
    linearize(ZeroOrderHoldLinearization(SC.t, A, B, propagate(f, x, SC) - A*x - B*SC.u), x, SC,
              keep_state_dims=keep_state_dims, keep_control_dims=keep_control_dims)
end

function linearize(f::DifferentialDynamics, x::StaticVector, RC::RampControl;
                   keep_state_dims=:, keep_control_dims=:)
    linearize(f, SVector(x), RampControl(RC.t, SVector(RC.u0), SVector(RC.uf)),
              keep_state_dims=keep_state_dims, keep_control_dims=keep_control_dims)
end
function linearize(f::DifferentialDynamics, x::SVector, RC::RampControl{<:Any,<:Any,<:SVector,<:SVector};
                   keep_state_dims=:, keep_control_dims=:)
    A  = ForwardDiff.jacobian(y -> propagate(f, y, RC), x)
    B0 = ForwardDiff.jacobian(w -> propagate(f, x, RampControl(RC.t, w, RC.uf)), RC.u0)
    Bf = ForwardDiff.jacobian(w -> propagate(f, x, RampControl(RC.t, RC.u0, w)), RC.uf)
    linearize(FirstOrderHoldLinearization(RC.t, A, B0, Bf, propagate(f, x, RC) - A*x - B0*RC.u0 - Bf*RC.uf), x, RC,
              keep_state_dims=keep_state_dims, keep_control_dims=keep_control_dims)
end

function (f::ZeroOrderHoldLinearization{Dx,Du})(x::StaticVector{Dx}, SC::StepControl{Du}) where {Dx,Du}
    @assert f.dt == SC.t
    f.A*x + f.B*SC.u + f.c
end
function (f::FirstOrderHoldLinearization{Dx,Du})(x::StaticVector{Dx}, RC::RampControl{Du}) where {Dx,Du}
    @assert f.dt == RC.t
    f.A*x + f.B0*RC.u0 + f.Bf*RC.uf + f.c
end
(f::FirstOrderHoldLinearization{Dx,Du})(x::StaticVector{Dx}, SC::StepControl{Du}) where {Dx,Du} = f(RampControl(SC))
