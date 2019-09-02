module triangleInterpolator
    using Images
    export rasterizationBBOX

    function pointLine(x::Float64,
                       y::Float64,
                       line::Array{Float64},
                       linex::Float64,
                       liney::Float64
            )::Float64
        return line[2]*x - line[1]*y - line[2]*linex + line[1]*liney
    end

    function swap_points(ax::Float64,
                         ay::Float64,
                         bx::Float64,
                         by::Float64,
                         colorA::RGB{N0f8},
                         colorB::RGB{N0f8}
            )::Tuple{Float64, Float64, Float64, Float64, RGB{N0f8}, RGB{N0f8}}
        buf_x = ax
        buf_y = ay
        ax = bx
        ay = by
        bx = buf_x
        by = buf_y

        colorBuf = colorA
        colorA = colorB
        colorB = colorBuf
        
        return ax, ay, bx, by, colorA, colorB
    end
    function validate_entry(ax::Float64,
                            ay::Float64,
                            bx::Float64,
                            by::Float64,
                            cx::Float64,
                            cy::Float64,
                            colorA::RGB{N0f8},
                            colorB::RGB{N0f8},
                            colorC::RGB{N0f8}
            )::Tuple{Float64, Float64, Float64, Float64, Float64, Float64, RGB{N0f8}, RGB{N0f8}, RGB{N0f8}}
        ab = [bx-ax, by-ay]
        bc = [cx-bx, cy-by]
        ca = [ax-cx, ay-cy]

        if pointLine(cx, cy, ab, ax, ay) < 0
            ax, ay, cx, cy, colorA, colorC = swap_points(ax, ay, cx, cy, colorA, colorC)

        elseif pointLine(ax, ay, bc, bx, by) < 0
            ax, ay, bx, by, colorA, colorB = swap_points(ax, ay, bx, by, colorA, colorB)

        elseif pointLine(bx, by, ca, cx, cy) < 0
            bx, by, cx, cy, colorB, colorC = swap_points(bx, by, cx, cy, colorB, colorC)
        end

        ax, ay, bx, by, cx, cy, colorA, colorB, colorC
    end
    function interpolateColors(position::Array{Float64},
                               ax::Float64,
                               ay::Float64,
                               bx::Float64,
                               by::Float64,
                               cx::Float64,
                               cy::Float64,
                               colorA::RGB{N0f8},
                               colorB::RGB{N0f8},
                               colorC::RGB{N0f8}
            )::RGB{N0f8}
        ab = [bx-ax, by-ay]
        bc = [cx-bx, cy-by]
        ca = [ax-cx, ay-cy]

        i, j = position

        alpha = pointLine(j, i, bc, bx, by) / pointLine(ax, ay, bc, bx, by)
        beta = pointLine(j, i, ca, cx, cy) / pointLine(bx, by, ca, cx, cy)
        phi = pointLine(j, i, ab, ax, ay) / pointLine(cx, cy, ab, ax, ay)

        return alpha * colorA + beta * colorB + phi * colorC
    end
    function setupBBOX(A::Array{Float64},
                       B::Array{Float64},
                       C::Array{Float64},
                       maxX::Int64,
                       maxY::Int64
            )::NTuple{4, Float64}
        maxHeight = max(A[1], B[1], C[1])
        minHeight = min(A[1], B[1], C[1])
        if maxHeight > maxY
            maxHeight = maxY
        end
        if minHeight < 1
            minHeight = 1
        end
        maxWidth = max(A[2], B[2], C[2])
        minWidth = min(A[2], B[2], C[2])
        if maxWidth > maxX
            maxWidth = maxX
        end
        if minWidth < 1
                minWidth = 1
        end
        return maxHeight, minHeight, maxWidth, minWidth
    end
    function rasterizationBBOX(img::Array{RGB{N0f8}, 2},
                               A::Array{Float64}, 
                               B::Array{Float64},
                               C::Array{Float64},
                               colorA::RGB{N0f8},
                               colorB::RGB{N0f8},
                               colorC::RGB{N0f8}
            )

        maxHeight, minHeight, maxWidth, minWidth = setupBBOX(A, B, C, size(img)[2], size(img)[1])
        ax, ay, bx, by, cx, cy = A[2], A[1], B[2], B[1], C[2], C[1]
        ax, ay, bx, by, cx, cy, colorA, colorB, colorC = validate_entry(ax, ay, bx, by, cx, cy, colorA, colorB, colorC)

        ab = [bx-ax, by-ay]
        bc = [cx-bx, cy-by]
        ca = [ax-cx, ay-cy]

        for i=floor(Int, minHeight):ceil(Int, maxHeight)
            for j=floor(Int, minWidth):ceil(Int, maxWidth)
                floatj = Float64(j)
                floati = Float64(i)
                alpha = pointLine(floatj, floati, bc, bx, by)
                beta = pointLine(floatj, floati, ca, cx, cy)
                phi = pointLine(floatj, floati, ab, ax, ay)

                if beta >= 0 && alpha >= 0 && phi >= 0
                    img[i, j] = interpolateColors([floati, floatj], ax, ay, bx, by, cx, cy, colorA, colorB, colorC)
                end
            end
        end
    end
end