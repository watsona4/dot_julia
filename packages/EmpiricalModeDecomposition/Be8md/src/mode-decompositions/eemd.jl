## Settings Struct

"Store the settings required for performing EEMD."
struct EEMDSetting
    "EMD Setting"
    emd_setting::EMDSetting
    "Ensemble Size"
    ensemble_size::Int64
    "Noise Strength"
    noise_strength::Float64
    "Seed"
    rng_seed::Int

    function EEMDSetting(n::Int64, num_siftings::Int64, s_num::Int64, m::Int64,
                       ensemble_size::Int64, noise_strength::Float64, rng_seed::Int=0) 
	    if ensemble_size < 1
            throw(DomainError("Invalid Ensemble Size for EEMD"))
	    elseif noise_strength < 0
            throw(DomainError("Invalid Noise Strength for EMD"))
	    elseif ensemble_size == 1 && noise_strength > 0
            throw(DomainError("Noise Added to EMD"))
    	elseif ensemble_size > 1 && noise_strength == 0
            throw(DomainError("No Noise Added to EEMD"))
        end

        new(EMDSetting(n, num_siftings, s_num, m), ensemble_size, noise_strength, rng_seed)
    end
end


## Main Function

"""
    eemd(input::Vector{Float64}, s::EEMDSetting)

Return the IMFs computed by EEMD given the settings.
"""
function eemd(input::Vector{Float64}, s::EEMDSetting)
    n = length(input)

    if (n == 0)
        throw(DomainError("Invalid size of input"))
    end

    if s.noise_strength != 0
        noise_sigma = std(input)*s.noise_strength
    else
        noise_sigma = zero(s.noise_strength)
    end

    output = zeros(n, s.emd_setting.m)
    rng = Normal(0.0, 1.0)

    for en_i=1:s.ensemble_size
        inp = zeros(n)
	    
        if s.noise_strength == 0.0
            inp = deepcopy(input)
	    else
            Random.seed!(s.rng_seed + en_i)
            rng = Normal(0.0, noise_sigma)
		    
            for i=1:n
                inp[i] += input[i] + rand(rng)
		    end
	    end

        output += emd(inp, s.emd_setting)
    end

    if s.ensemble_size != 1
        output *= 1.0/float(s.ensemble_size)
    end

    return output
end
