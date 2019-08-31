macro vl_str(content)
    return VLSpec{:plot}(JSON.parse(content))
end

macro vg_str(content)
    return VGSpec(JSON.parse(content))
end
