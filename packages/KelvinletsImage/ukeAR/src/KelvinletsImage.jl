module KelvinletsImage

    include("triangleInterpolator.jl")
    using Images, ProgressMeter, ImageView, LinearAlgebra
    export KelvinletsObject, grab, scale, pinch, makeVideo
    
    struct KelvinletsObject
        a::Float64
        b::Float64
        c::Float64
        sizeX::Int64
        sizeY::Int64
        image::AbstractArray{RGB{N0f8}, 2}
        function KelvinletsObject(image::AbstractArray{RGB{N0f8}, 2},
                                  ν::Float64,
                                  μ::Float64
                )::KelvinletsObject

            a = 1 / (4pi * μ)
            b = a / (4(1 - ν))
            c = 2 / (3a- 2b)

            sizeY, sizeX = size(image)

            new(a, b, c, sizeX, sizeY, image)
        end
    end

    function __applyVariation__(object::KelvinletsObject,
                                pressurePoint::Array{Int64},
                                variationFunction::Function,
                                retardationFunction::Function
            )::Array{RGB{N0f8}, 2}

        allΔ = zeros(object.sizeY, object.sizeX, 2)
        for i=1:object.sizeY
            for j=1:object.sizeX
                Δ = variationFunction([i, j])

                dx1 = j
                dx2 = object.sizeX - j
                dy1 = i
                dy2 = object.sizeY - i

                dx = min(dx1, dx2)
                dy = min(dy1, dy2)

                y = 2(object.sizeY/2 - dy)/object.sizeY
                x = 2(object.sizeX/2 - dx)/object.sizeX

                Δ[1] *= retardationFunction(y)
                Δ[2] *= retardationFunction(x)

                Δ += [i, j]

                allΔ[i, j, 1] = Δ[1]
                allΔ[i, j, 2] = Δ[2]
            end
        end
        return __interpolateVariation__(object, allΔ)
    end

    function __interpolateVariation__(object::KelvinletsObject,
                                      allΔ::Array{Float64, 3}
            )::Array{RGB{N0f8}, 2}

        interpImg = fill(RGB(0, 0, 0), object.sizeY, object.sizeX)
        
        rasterize = function(A, B, C)
            colorA = object.image[A[1], A[2]]
            colorB = object.image[B[1], B[2]]
            colorC = object.image[C[1], C[2]]
            triangleInterpolator.rasterizationBBOX(interpImg,
                            [allΔ[A[1], A[2], 1], allΔ[A[1], A[2], 2]],
                            [allΔ[B[1], B[2], 1], allΔ[B[1], B[2], 2]],
                            [allΔ[C[1], C[2], 1], allΔ[C[1], C[2], 2]],
                            colorA, colorB, colorC
            )
        end
        
        for i=1:object.sizeY-1
          for j=1:object.sizeX-1
            rasterize([i, j], [i, j+1], [i+1, j+1])
            rasterize([i, j], [i+1, j], [i+1, j+1])
          end
        end
        return interpImg
    end

    function grab(object::KelvinletsObject,
                  x0::Array{Int64},
                  force::Array{Float64},
                  ϵ::Float64
            )::Array{RGB{N0f8}, 2}

        grabFunc = function(x::Array{Int64})
            
                           r = x - x0
            rLength = norm(r)
            rϵ = sqrt(rLength^2 + ϵ^2)
            kelvinState = (((object.a - object.b)/rϵ) * I +
                            (object.b / rϵ^3) * r * r' +
                            (object.a / 2) * (ϵ^2 / rϵ^3) * I)
            object.c * ϵ * kelvinState * force
        end
        
        retardationFunc = α -> (cos(π * α) + 1) / 2
        return __applyVariation__(object, x0, grabFunc, retardationFunc)
    end

    function scale(object::KelvinletsObject,
                   x0::Array{Int64},
                   force::Float64,
                   ϵ::Float64
            )::Array{RGB{N0f8}, 2}

        scaleFunc = function(x::Array{Int64})
            
            r = x - x0
            rLength = norm(r)
            rϵ = sqrt(rLength^2 + ϵ^2)

            return (2 * object.b - object.a) *
                   ( (1 / rϵ^2) +
                   ((ϵ^2)) / (2 * (rϵ^4))) *
                   (force * r)
        end
        
        retardationFunc = α -> (cos(π * α) + 1) / 2
        return __applyVariation__(object, x0, scaleFunc, retardationFunc)
    end

    function pinch(object::KelvinletsObject,
                   x0::Array{Int64},
                   force::Array{Float64, 2},
                   ϵ::Float64
            )::Array{RGB{N0f8}, 2}

        pinchFunc = function(x::Array{Int64})
            
            r = x - x0
            rLength = norm(r)
            rϵ = sqrt(rLength^2 + ϵ^2)
            return  -2 * object.a * ((1 / rϵ^2) +
                    (ϵ^2 / rϵ^4)) * force * r +
                    4 * object.b * ((1 / rϵ^2) * force -
                    (1 / rϵ^4) * (r' * force * r) * I) * r
        end
        
        retardationFunc = α -> (cos(π * α) + 1) / 2
        return __applyVariation__(object, x0, pinchFunc, retardationFunc)
    end

    function makeVideo(object::KelvinletsObject,
                       kelvinletsFunction::Function,
                       x0::Array{Int64},
                       force,
                       ϵ::Float64,
                       frames::Int64
        )::Array{RGB{N0f8},3}
        
        if typeof(force) == Float64
            var = range(0, stop=force, length=frames)
        else    
            var = range(fill(0, size(force)), stop=force, length=frames)    
        end
        
        video = Array{RGB{N0f8}}(undef, object.sizeY, object.sizeX, frames)
        @showprogress for i=1:frames
            video[:,:,i] = kelvinletsFunction(object, x0, var[i], ϵ)
        end
        imshow(video)
        return video
    end
end
