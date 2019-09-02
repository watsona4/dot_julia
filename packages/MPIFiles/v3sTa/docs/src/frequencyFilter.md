# Frequency Filter

A frequency filter can be calculated using the function
```julia
function filterFrequencies(f::MPIFile;
                           SNRThresh=-1,
                           minFreq=0, maxFreq=rxBandwidth(f),
                           recChannels=1:rxNumChannels(f),
                           sortBySNR=false,
                           numUsedFreqs=-1,
                           stepsize=1,
                           maxMixingOrder=-1,
                           sortByMixFactors=false)
```
Usually one will apply an SNR threshold `SNRThresh > 1.5` and a `minFreq` that
is larger than the excitation frequencies. The frequencies are specified in Hz.
Also useful is the opportunity to select specific receive channels by specifying
`recChannels`.

The return value of `filterFrequencies` is of type `Vector{Int64}` and can be directly
passed to `getMeasurements`, `getMeasurementsFD`, and `getSystemMatrix`.
