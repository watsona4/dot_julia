
function stacked_spectrum!(dobs)
	D=rfft(dobs,1) # perform rfft
	window=zeros(size(D,1))        
	nr=size(dobs,2)        
	# stack the spectrum of data        
	for j in 1:nr                
		for i in eachindex(window)
			window[i] += (abs2(D[i,j]))
		end
	end        
	rmul!(window,inv(maximum(abs,window)))
	window = 10. * log10.(window)        
	return Float64.(DSP.Util.rfftfreq((size(dobs,1)))), window
end


