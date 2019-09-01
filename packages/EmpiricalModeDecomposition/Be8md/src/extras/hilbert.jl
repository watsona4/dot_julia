"""
    hilbert_transform(signal::Vector{Float64})

Compute the Hilbert transform using the DFT approximation.
"""
function hilbert_transform(signal::Vector{Float64})
    fourier = AbstractFFTs.fft(signal)
    n = length(fourier)
    h = zeros(n)

    for i in eachindex(h)
        if i == 1 || i == (n/2)+1
            h[i] = 1
        elseif 2 <= i <= (n/2)
            h[i] = 2
        else
            h[i] == 0
        end
    end

    dtft_hilbert = fourier .* h
    return AbstractFFTs.ifft(dtft_hilbert)
end

"""
    compute_instantaneous(signal::Vector{Float64}, imfs::Array{Float64, 2})

Return the instantaneous energy and instantaneous frequencies of the IMFS in the signal.
"""
function compute_instantaneous(signal::Vector{Float64}, imfs::Matrix{Float64})
    n = length(signal)
    analytic_signal = zeros(n)
    theta = zeros(n)
    imf_inst_energy = zeros(n, size(imfs, 1))
    imf_inst_freq = zeros(n, size(imfs, 1))
    r = zeros(n)
    time = collect(1:n)

    for j=1:size(imfs, 1)
        analytic_signal = signal + im*hilbert_transform(imfs[:, j])

        for i in eachindex(analytic_signal)
            theta[i] = angle(analytic_signal[i])
            imf_inst_energy[i, j] = abs2(analytic_signal[i])
        end

        spl = Spline1D(time, theta)

        g = x -> ForwardDiff.gradient(spl, time)


        for i in eachindex(analytic_signal)
            imf_inst_freq[i, j] = g(time[i])
        end
    end

    return imf_inst_energy, imf_inst_freq
end

"""
    hht(signal::Vector{Float64}, s::EMDSetting)

Return the instantaneous energies and frequencies of the IMFS computed via the
Hilbert-Huang transform with EMD settings specified.
"""
function hht(signal::Vector{Float64}, s::EMDSetting)
    imfs = emd(signal, s)
    return compute_instantaneous(input, imfs)
end

"""
    hht(signal::Vector{Float64}, s::EEMDSetting)

Return the instantaneous energies and frequencies of the IMFS computed via the
Hilbert-Huang transform with EEMD settings specified.
"""
function hht(signal::Vector{Float64}, s::EEMDSetting)
    imfs = eemd(signal, s)
    return compute_instantaneous(input, imfs)
end
