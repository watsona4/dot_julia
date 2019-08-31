#
#  Copyright (C) 2018 Remi Imbach
#
#  This file is part of Ccluster.
#
#  Ccluster is free software: you can redistribute it and/or modify it under
#  the terms of the GNU Lesser General Public License (LGPL) as published
#  by the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.  See <http://www.gnu.org/licenses/>.
#

# @pyimport matplotlib.patches as patch

function drawBox(b::Array{fmpq,1}, color::String, opacity::Float64)
    shift = fmpq(1,2)*b[3]
    width = b[3]
    left  = b[1] - shift
    low   = b[2] - shift
    shift = shift.num/shift.den
    left  = left.num/left.den
    low   = low.num/low.den
    width = width.num/width.den
    if color=="no-fill"
        return matplotlib_patches[:Rectangle]( 
                               (left, low), 
                                width, width, 
                                fill=false, edgecolor="black",lw=2
                              )
    else
        return matplotlib_patches[:Rectangle]( 
                               (left, low ), 
                                width, width, 
                                facecolor=color, edgecolor="black", alpha=opacity 
                              )
    end
end

function drawBox(b::box, fill, color::String, opacity::Float64)
    shift = fmpq(1,2)*getWidth(b)
    width = getWidth(b)
    left  = getCenterRe(b) - shift
    low   = getCenterIm(b) - shift
    shift = shift.num/shift.den
    left  = left.num/left.den
    low   = low.num/low.den
    width = width.num/width.den
    if fill==false
        return matplotlib_patches[:Rectangle]( 
                               (left, low), 
                                width, width, 
                                fill=false, edgecolor=color, lw=0.5
                              )
    else
        return matplotlib_patches[:Rectangle]( 
                               (left, low ), 
                                width, width, 
                                facecolor=color, edgecolor="black", alpha=opacity
                              )
    end
end

function drawDisk(d::Array{fmpq,1}, color::String, opacity::Float64)
    
    radius = (d[3]).num/(d[3]).den
    cRe  = (d[1]).num/(d[1]).den
    cIm   = (d[2]).num/(d[2]).den
    if color=="no-fill"
        return matplotlib_patches[:Circle]( 
                               (cRe, cIm), 
                                radius, 
                                fill=false, edgecolor="black"
                              )
    else
        return matplotlib_patches[:Circle]( 
                               (cRe, cIm), 
                                radius, 
                                facecolor=color, edgecolor="black", alpha=opacity 
                              )
    end
end
    
function plotCcluster( disks, initBox, focus=false )
    objects = []
    
    push!(objects, drawBox(initBox,     String("no-fill"), 0.0))
    enlargedBox = [ initBox[1], initBox[2], fmpq(5,4)*initBox[3] ]
    push!(objects, drawBox(enlargedBox, String("no-fill"), 0.0))
    
    for index = 1:length(disks)
        boxestemp = drawDisk( disks[index][2], "green", 0.5 )
        push!(objects, boxestemp)
    end
    
    fig, ax = subplots()
    
    left  = initBox[1] - initBox[3]; 
    right = initBox[1] + initBox[3]; 
    lower = initBox[2] - initBox[3]; 
    upper = initBox[2] + initBox[3];
        
    if focus && length(disks)>=1
         left  = disks[1][2][1] - disks[1][2][3]
         right = disks[1][2][1] + disks[1][2][3]
         lower = disks[1][2][2] - disks[1][2][3]
         upper = disks[1][2][2] + disks[1][2][3]
         for index = 2:length(disks)
            if (disks[index][2][1] - disks[index][2][3]) < left
                left  = disks[index][2][1] - disks[index][2][3]
            end
            if (disks[index][2][1] + disks[index][2][3]) > right
                right  = disks[index][2][1] + disks[index][2][3]
            end
            if (disks[index][2][2] - disks[index][2][3]) < lower
                lower  = disks[index][2][2] - disks[index][2][3]
            end
            if (disks[index][2][2] + disks[index][2][3]) > upper
                upper  = disks[index][2][2] + disks[index][2][3]
            end
         end
    end
    
    left  = left.num/left.den
    right = right.num/right.den
    lower = lower.num/lower.den
    upper = upper.num/upper.den

    ax[:set_xlim](left, right )
    ax[:set_ylim](lower, upper)
    for index = 1:length(objects)
        ax[:add_patch](objects[index])
    end
end

function plotCcluster_subdiv( CCs, discardedBoxes, initBox, focus=false )
    objects = []
    
    push!(objects, drawBox(initBox,     String("no-fill"), 0.0))
#     enlargedBox = [ initBox[1], initBox[2], fmpq(5,4)*initBox[3] ]
#     push!(objects, drawBox(enlargedBox, String("no-fill"), 0.0))
    
    for index = 1:length(discardedBoxes)
        boxestemp = drawBox( discardedBoxes[index], false, "red", 1.0 )
        push!(objects, boxestemp)
    end
    
    for index = 1:length(CCs)
        tempBO = getComponentBox(CCs[index],box(initBox[1],initBox[2],initBox[3]))
        boxestemp = drawBox( tempBO, true, "green", 0.3 )
        push!(objects, boxestemp)
        while !isEmpty(CCs[index])
            tempBO = pop(CCs[index])
            boxestemp = drawBox( tempBO, true, "green", 1.0 )
            push!(objects, boxestemp)
        end
        
    end
    
    fig, ax = subplots()
    
    left  = initBox[1] - initBox[3]; 
    right = initBox[1] + initBox[3]; 
    lower = initBox[2] - initBox[3]; 
    upper = initBox[2] + initBox[3];
        
    if focus && length(disks)>=1
         left  = disks[1][2][1] - disks[1][2][3]
         right = disks[1][2][1] + disks[1][2][3]
         lower = disks[1][2][2] - disks[1][2][3]
         upper = disks[1][2][2] + disks[1][2][3]
         for index = 2:length(disks)
            if (disks[index][2][1] - disks[index][2][3]) < left
                left  = disks[index][2][1] - disks[index][2][3]
            end
            if (disks[index][2][1] + disks[index][2][3]) > right
                right  = disks[index][2][1] + disks[index][2][3]
            end
            if (disks[index][2][2] - disks[index][2][3]) < lower
                lower  = disks[index][2][2] - disks[index][2][3]
            end
            if (disks[index][2][2] + disks[index][2][3]) > upper
                upper  = disks[index][2][2] + disks[index][2][3]
            end
         end
    end
    
    left  = left.num/left.den
    right = right.num/right.den
    lower = lower.num/lower.den
    upper = upper.num/upper.den

    ax[:set_xlim](left, right )
    ax[:set_ylim](lower, upper)
    for index = 1:length(objects)
        ax[:add_patch](objects[index])
    end
end