## If Rois are given as an array of indices
function FluorescentSerie(img::AxisArray,rois::Array{Array{Int64,1},1},summaryFunc::Function=sum)
    nt = nimages(img)
    ax = timeaxis(img)
    results = zeros(nt,length(rois))
    for i in eachindex(rois)
        for j in 1:nt
            results[j,i] = summaryFunc(img[ax(j)][rois[i]])
        end
    end
    AxisArray(results,ax,Axis{:ROI}(1:length(rois)))
end

# Constructing from a ROI image and the raw data
function FluorescentSerie(rawImage::AxisArray,roiIm::AbstractArray{Int64},summaryFunc::Function=sum)
    size_spatial(rawImage) != size(roiIm) ? error("ROI image has a different size than the data") :
    rois = Array{Array{Int64,1},1}(maximum(roiIm))
    for i in 1:maximum(roiIm)
        rois[i] = findall(roiIm.==i)
    end
    FluorescentSerie(rawImage,rois,summaryFunc)
end
