# These functions are still WIP

function noise_model(freq_hz, fknee_hz, rms, alpha)
    rms * (1 + fknee_hz / freq_hz)^alpha
end

function baseline_spectrum(freq_hz, baseline_period_s)
    while false
        
    end
end
