function K_DKGQ(elm::Quad)::Matrix{Float64}
    return K_GQ12(elm)+K_DKQ(elm)
end
