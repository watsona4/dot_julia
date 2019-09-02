module LorentzDrudeMetals

struct LorentzDrudeMetal
    ωp::Float64
    resonances::Array{Tuple{Real,Real,Real}}
end

function Base.getindex(metal::LorentzDrudeMetal, λ::Real)
    # λ = μm, ω = eV
    ω = 1.23984193 / λ
    # Lorentz-Drude equation
    ϵ = 1
    for (fn, Γn, ωn) in metal.resonances
        ϵ += metal.ωp^2 * fn ./ (ωn^2 - ω^2 + 1im*ω*Γn)
    end
    return ϵ
end

function Base.getindex(metal::LorentzDrudeMetal, λs::AbstractArray{<:Real,1})
	return [metal[λ] for λ in λs]
end

# Parameters from 'Optical properties of metallic films for vertical-cavity optoelectronic devices', Rakić et al (1998)
Ag = LorentzDrudeMetal(9.010,[(0.845,0.048,0), (0.065,3.886,0.816), (0.124,0.452,4.481), (0.011,0.065,8.185), (0.840,0.916,9.083), (5.646,2.419,20.290)])
Al = LorentzDrudeMetal(14.98, [(0.523,0.047,0), (0.227,0.333,0.162), (0.050,0.312,1.544), (0.166,1.351,1.808), (0.030,3.382,3.473)])
Au = LorentzDrudeMetal(9.030, [(0.760,0.053,0), (0.024,0.241,0.415), (0.010,0.345,0.830), (0.071,0.870,2.969), (0.601,2.494,4.304), (4.384,2.214,13.320)])
Ti = LorentzDrudeMetal(7.290, [(0.148,0.082,0), (0.899,2.276,0.777), (0.393,2.518,1.545), (0.187,1.663,2.509), (0.001,1.762,19.430)])

export LorentzDrudeMetal

end # module
