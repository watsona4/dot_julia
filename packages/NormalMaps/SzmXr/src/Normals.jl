module Normals

using Images
using LinearAlgebra
## Helpers
############

function ToArray(texel)
    [texel.r, texel.g, texel.b] 
end

function ToRGB(texel)
    RGB(texel[1], texel[2], texel[3])
end

function RGBSum(_in)
    _in.r + _in.g + _in.b 
end

function IdentitySpaceMapping(_rgb)
    _rgb
end

function ToNormalSpace(_rgb)
    col = [ (_rgb[1]+1.0)*0.5,  (_rgb[2]+1.0)*0.5,  (_rgb[3]+1.0)*0.5]
end

# Normal data helper functions
export IdentitySpaceMapping, ToNormalSpace
export RGBSum
export ToRGB, ToArray

### Generate Normal Map From Height/Colour
###########################################

function NormalGen_Sobel(_img; filter=[-0.5, 0, 0.5], SpaceMapping=ToNormalSpace)
    width, height = size(_img);
    oldimg        = RGB{Float64}.(_img)
    newimg        = copy(RGB{Float64}.(_img))
    bounds        = Int64.(floor(length(filter)/2))
    
    for y in 1:height
        for x in 1:width   
            xsum   = 0.0   
            ysum   = 0.0
            count = 1
            for s in -bounds:bounds
                if(x+s>=1 && x+s<=width)
                    xsum = xsum +  (filter[count] * ( RGBSum( oldimg[x+s, y   ] ) / 3.0 ))   
                end
                
                if(y+s>=1 && y+s<=height)
                    ysum = ysum +  (filter[count] * ( RGBSum( oldimg[x, y+s   ] ) / 3.0 ))
                end
                count = count+1         
            end 
            
            col = SpaceMapping([ xsum, ysum, 1.0])
            col = normalize(col)
            newimg[x,y] = RGB( col[1], col[2], col[3])
        end
    end
    newimg
end
NormalGen = NormalGen_Sobel

# Normal generation functions
export NormalGen_Sobel, NormalGen

## Merging Normal Maps
#######################

## Based on RNM from https://blog.selfshadow.com/publications/blending-in-detail/
function NormalBlend_RNM(_n1, _n2; ToNormalFunc=ToNormalSpace )
    n1 = _n1 .* [  2.0,   2.0,  2.0]  .+ [ -1.0, -1.0,   0.0]
    n2 = _n2 .* [ -2.0,  -2.0,  2.0]  .+ [  1.0,  1.0,  -1.0]
    n  = n1*dot(n1, n2)/n1[3] - n2;
    ToNormalFunc(normalize(n))
end

# Precondition: Assert that input normals are stored packed in 0-1 range by: (xyz + 1.0) * 0.5
function BlendNormalsRNM(inputOne, inputTwo; BlendFunc=NormalBlend_RNM)
    width, height = size(inputOne);
    newimg = copy(RGB{Float64}.(inputOne))
    inputOneF = RGB{Float64}.(inputOne)
    inputTwoF = RGB{Float64}.(inputTwo)
    
    for y in 1:height
        for x in 1:width
            texelOne = ToArray(inputOneF[x,y])
            texelTwo = ToArray(inputTwoF[x,y])

            texelOut = BlendFunc(texelOne, texelTwo)
            newimg[x,y] = ToRGB( texelOut )
        end
    end
    
    newimg
end

export NormalBlend_RNM, BlendNormalsRNM

end # module
