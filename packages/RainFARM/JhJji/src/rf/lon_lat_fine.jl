"""
    (lon_f, lat_f) = lon_lat_fine(lon, lat,nf)

Interpolate longitude and latitude arrays (2d or 1d) `lon` and `lat` to higher resolution by a factor `nf`. 
"""
function lon_lat_fine(lon_mat, lat_mat,nf)
#using Interpolations

ns=size(lon_mat)

if(length(ns)==2)
  nlon=ns[1]; nlat=ns[2];

  xc=1:nlon
  yc=1:nlat
  xf=(0.5+1/(2*nf)):1/nf:(nlon+0.5-1/(2*nf))
  yf=(0.5+1/(2*nf)):1/nf:(nlat+0.5-1/(2*nf))
  knots=(collect(yc),collect(xc))

if VERSION >= v"0.7.0-DEV.3449"
  itplon = extrapolate(interpolate(knots, lon_mat, Gridded(Linear())), Line());
  itplat = extrapolate(interpolate(knots, lat_mat, Gridded(Linear())), Line());
else
  itplon = interpolate(knots, lon_mat, Gridded(Linear()))
  itplat = interpolate(knots, lat_mat, Gridded(Linear()))
end

  lon_f=itplon(collect(yf),collect(xf))
  lat_f=itplat(collect(yf),collect(xf))
else
  (nlat,)=size(lat_mat);
  (nlon,)=size(lon_mat);

  xc=1:nlon
  yc=1:nlat

  xf=(0.5+1/(2*nf)):1/nf:(nlon+0.5-1/(2*nf))
  yf=(0.5+1/(2*nf)):1/nf:(nlat+0.5-1/(2*nf))
  knotsx=collect(xc)
  knotsy=collect(yc)

if VERSION >= v"0.7.0-DEV.3449"
  itplon = extrapolate(interpolate((knotsx,), lon_mat, Gridded(Linear())), Line());
  itplat = extrapolate(interpolate((knotsy,), lat_mat, Gridded(Linear())), Line());
else
  itplon = interpolate((knotsx,), lon_mat, Gridded(Linear()))
  itplat = interpolate((knotsy,), lat_mat, Gridded(Linear()));
end

  lon_f=itplon(collect(xf))
  lat_f=itplat(collect(yf))
end

return lon_f, lat_f
end
