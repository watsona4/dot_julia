using Watershed

aff = rand(Float32, 124,124,12,3);

# watershed(aff)

#println("watershed ...")
#@time watershed(aff)

# @profile watershed(aff)
# Profile.print()
low = 0.1
high = 0.8
thresholds = []
dust_size = 1

watershed(aff; is_threshold_relative=true)

