
module Ditherings

using Images
export Quantise
export ZeroOne
export ZeroOne_PerChannel
export FloydSteinbergDither4Sample
export FloydSteinbergDither12Sample

function Quantise(pixel)
    shift = 4
    scale = 255.0
    r = Int64.(round(scale * (red(pixel)  )))>>shift
    g = Int64.(round(scale * (green(pixel))))>>shift
    b = Int64.(round(scale * (blue(pixel) )))>>shift
    r = Float64.((r<<shift)/scale)
    g = Float64.((g<<shift)/scale)
    b = Float64.((b<<shift)/scale)
    RGB(r,g,b)
end

function ZeroOne(pixel)
    r = red(pixel)
    g = green(pixel)
    b = blue(pixel)

    if(r + b + g >= 1.5)
        return RGB(1.0, 1.0, 1.0)
    else
        return RGB(0.0, 0.0, 0.0)
    end
end

function ZeroOne_PerChannel(pixel)
    r = red(pixel)
    g = green(pixel)
    b = blue(pixel)
    
    r= r>0.5 ? 1.0 : 0.0
    g= g>0.5 ? 1.0 : 0.0
    b= b>0.5 ? 1.0 : 0.0

    return RGB(r, g, b)

end

function FloydSteinbergDither4Sample(_img, PaletteFunction, weights=[7/16,3/16,5/16,1/16]) 
    width, height = size(_img);
    inputtype = typeof(_img)
    newimg = RGB{Float64}.(_img)

    for y in 2:height-1
        for x in 2:width-1
            oldpix = newimg[x,y]
            newpix = PaletteFunction(oldpix)
            newimg[x,y] = newpix
            quant_error = oldpix - newpix
            newimg[x+1,y  ] = newimg[x+1,y  ] + (quant_error * weights[1])
            newimg[x-1,y+1] = newimg[x-1,y+1] + (quant_error * weights[2])
            newimg[x  ,y+1] = newimg[x  ,y+1] + (quant_error * weights[3])
            newimg[x+1,y+1] = newimg[x+1,y+1] + (quant_error * weights[4])
        end
    end
    
    newimg
end

function FloydSteinbergDither12Sample(_img, PaletteFunction, weights = [0.243228, 0.0810761, 0.0417918, 0.0573652, 0.243228, 0.0573652, 0.0417918, 0.0347469, 0.0417918, 0.0810761, 0.0417918, 0.0347469]) 
    width, height = size(_img);
    inputtype = typeof(_img)
    newimg = RGB{Float64}.(_img)

    for y in 3:height-2
        for x in 3:width-2
            oldpix = newimg[x,y]
            newpix = PaletteFunction(oldpix)
            newimg[x,y] = newpix
            quant_error = oldpix - newpix
            newimg[x+1,y  ] = newimg[x+1,y  ] + (quant_error * weights[1] )
            newimg[x+2,y  ] = newimg[x+2,y  ] + (quant_error * weights[2] )
            
            newimg[x-2,y+1] = newimg[x-2,y+1] + (quant_error * weights[3] )
            newimg[x-1,y+1] = newimg[x-1,y+1] + (quant_error * weights[4] )
            newimg[x  ,y+1] = newimg[x  ,y+1] + (quant_error * weights[5] )
            newimg[x+1,y+1] = newimg[x+1,y+1] + (quant_error * weights[6] )
            newimg[x+2,y+1] = newimg[x+2,y+1] + (quant_error * weights[7] )
            
            newimg[x-2,y+2] = newimg[x-2,y+2] + (quant_error * weights[8] )
            newimg[x-1,y+2] = newimg[x-1,y+2] + (quant_error * weights[9] )
            newimg[x  ,y+2] = newimg[x  ,y+2] + (quant_error * weights[10] )
            newimg[x+1,y+2] = newimg[x+1,y+2] + (quant_error * weights[11] )
            newimg[x+2,y+2] = newimg[x+2,y+2] + (quant_error * weights[12] )
        end
    end
    
    newimg
end

end