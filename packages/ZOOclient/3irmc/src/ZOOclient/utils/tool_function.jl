function zoolog(text)
    println("[zooclient] $text")
end

function rand_uniform(rng, lower, upper)
    return rand(rng, Float64) * (upper - lower) + lower
end


function convert_time(second)
    sec = second
    hour = Int64(floor(sec / 3600))
    sec = sec - hour * 3600
    min = Int64(floor(sec / 60))
    sec = Int64(round(sec - min * 60))
    # return "%02d:%02d:%02d" hour min sec
    return "$(hour):$(min):$(sec)"
end

function mydistance(x, y)
    dis = 0
    for i in 1:length(x)
        dis += (x[i] - y[i])^2
    end
    return sqrt(dis)
end
