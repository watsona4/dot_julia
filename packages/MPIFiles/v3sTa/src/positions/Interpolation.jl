function getInterpolator(A::AbstractArray{T,3}, grid::RegularGridPositions) where T

  tmp = ( size(A,1)==1 ? NoInterp() : BSpline(Linear()),
          size(A,2)==1 ? NoInterp() : BSpline(Linear()),
          size(A,3)==1 ? NoInterp() : BSpline(Linear()) )

  itp = extrapolate(interpolate(A, tmp), 0.0)
  sitp = scale(itp, range(grid,1), range(grid,2), range(grid,3))
  return sitp
end

function interpolate(A::AbstractArray{T,3}, origin::RegularGridPositions,
                        target::RegularGridPositions) where T

  sitp = getInterpolator(A, origin)
  N = target.shape
  AInterp = zeros(eltype(A), N[1], N[2], N[3])
  rx, ry, rz = range(target,1), range(target,2), range(target,3)

  return _interpolate_inner(AInterp,N,sitp,rx,ry,rz)
end

function _interpolate_inner(AInterp,N,sitp,rx,ry,rz)
  for nz=1:N[3]
    for ny=1:N[2]
      for nx=1:N[1]
        AInterp[nx,ny,nz] = sitp(rx[nx],ry[ny],rz[nz])
      end
    end
  end

  return AInterp
end
