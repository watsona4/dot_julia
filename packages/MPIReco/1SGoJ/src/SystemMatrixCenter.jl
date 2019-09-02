export findCenterOfDfFov

"""This function calculates the center of the DfFov of the given MPIFile bSF"""
function findCenterOfDfFov(bSF::MPIFile)
	S1 = getSF(bSF,0,2,0,1) #xdir
  S2 = getSF(bSF,2,0,0,2) #ydir
  S3 = getSF(bSF,0,0,2,3) #zdir

  center = ones(3)
  if size(S1,1) > 1
    u = floor.(Int, centerOfMass(abs.(S1)))
    x = argmin(abs.(vec((S1[(u[1]-5):(u[1]+5),u[2],u[3]]))))+u[1]-6
    y_0 = real(S1[x-1,u[2],u[3]])
    y_1 = real(S1[x+1,u[2],u[3]])
    xdiff = -y_0 / (y_1-y_0) *2
    center[1] = x#+xdiff-1
  end
  if size(S2,2) > 1
    u = floor.(Int, centerOfMass(abs.(S2)))
    x = argmin(abs.(vec((S2[u[1],(u[2]-5):(u[2]+5),u[3]]))))+u[2]-6
    y_0 = real(S2[u[1],x-1,u[3]])
    y_1 = real(S2[u[1],x+1,u[3]])
    xdiff = -y_0 / (y_1-y_0) *2
    center[2] = x#+xdiff-1
  end
  if size(S3,3) > 1
    u = floor.(Int, centerOfMass(abs.(S3)))
    x = argmin(abs.(vec((S3[u[1],u[2],(u[3]-5):(u[3]+5)]))))+u[3]-6
    y_0 = real(S3[u[1],u[2],x-1])
    y_1 = real(S3[u[1],u[2],x+1])
    xdiff = -y_0 / (y_1-y_0) *2
    center[3] = x#+xdiff-1
  end
  return center
end


function centerOfMass(data::Array{T,3}) where T
  data = abs.(data)
  maxData = maximum(data)
  data[ data .< maxData*0.5] .= 0

  lx=0
  ly=0
  lz=0
  for i3=1:size(data,3)
    for i2=1:size(data,2)
      for i1=1:size(data,1)
           lx += data[i1,i2,i3]*i1
           ly += data[i1,i2,i3]*i2
           lz += data[i1,i2,i3]*i3
       end
     end
  end
  cm = [lx/sum(data), ly/sum(data),lz/sum(data)]
  for d=1:3
    if size(data,d) == 1
      cm[d] = 1.0
    end
  end
  return cm
end
