function plotModel(m,plotting::Bool=false,includeMeshInfo::Bool=false,Msh = [],cutPad::Int64 = 0,limits = [],filename="")

if limits!=[]
	vmin = limits[1];
	vmax = limits[2];
else
	vmin = minimum(m);
	vmax = maximum(m);
end

limits = tuple([vmax,vmin]...);
if cutPad >= 0
	m,Msh = cutAbsorbingLayer(m,Msh,cutPad);
end
if plotting
	if length(size(m))==2
		T = m';
		imshow(T, clim = limits); colorbar();
		if includeMeshInfo
			Omega = Msh.domain;
			tics = 0:2:floor(Int64,Omega[2])
			xticks(linspace(0,size(m,1)*tics[end]/Omega[2],length(tics)),tics);
			xlabel("Lateral distance (km)");
			tics = 0:floor(Int64,Omega[4])
			# println(tics)
			# println(linspace(0,size(m,2)*tics[end]/Omega[4],length(tics)))
			yticks(linspace(0,size(m,2)*tics[end]/Omega[4],length(tics)),tics);
			ylabel("Depth (km)")
		end
		if filename != ""
			# title(filename[1:end-4],fontsize = 11);
			savefig(string(filename[1:end-4],".png"));
		end
	elseif length(size(m))==3
		lin = zeros(Int64,16);
		v = m;
		for k=1:16
			lin[k] = convert(Int64,round(k*(size(m,2)/16)));
		end
		for k=1:16
			subplot(4,4,k)
			pic = reshape(v[:,lin[k],:],size(m,1),size(m,3))';
			imshow(pic,clim = limits); title(string("frame",lin[k]));colorbar()
		end
		if filename != ""
			# title(filename[1:end-4],fontsize = 11);
			savefig(string(filename[1:end-4],".png"));
		end
	end
end
end