"""
    sx = fitslopex(fx; kmin=1)

Return spectral slope (minus 1) of spatial spectrum `fx`.
"""
	function fitslopex(fx; kmin=1)
        kmin = Int(kmin);
        xr = collect(1:length(fx));
        x = log.(xr[kmin:end])
        y = log.(fx[kmin:end])
        sx, a = [ x[:] ones(length(x))] \ y
	sx = abs(sx)
	sx = sx-1
	return sx
	end

