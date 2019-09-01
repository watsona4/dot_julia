using DatasetsCF
using Persa
using DataFrames

datasets = [DatasetsCF.MovieLens,
            DatasetsCF.MovieTweeting,
            DatasetsCF.CiaoDVD,
            DatasetsCF.FilmTrust,
            DatasetsCF.YahooMusic,
            DatasetsCF.LastFM]
######
ds = datasets[5]()

hist = Persa.histogram(ds)
df = DataFrame()

df[:rating] = Array{eltype(ds.preferences)}(size(ds.preferences))
df[:a] = Array{Int}(size(ds.preferences))
df[:b] = Array{Float64}(size(ds.preferences))

i = 1

for rating in sort(ds.preferences.possibles)

    df[:rating][i] = rating
    df[:a][i] = hist[rating]
    i = i + 1
end

df[:b] = df[:a] ./ sum(df[:a])

df[:rating]
df[:a]
df[:b]

##############
datasets
ds = datasets[5]()

hist_user = zeros(Int, ds.users)
hist_item = zeros(Int, ds.items)

for (u, v, r) in ds
    hist_user[u] = hist_user[u] + 1
    hist_item[v] = hist_item[v] + 1
end

sort!(hist_user, rev = true)
sort!(hist_item, rev = true)
###
factor = convert(Int, round(length(hist_user) / 200))

open("t.txt", "w") do f
    write(f, "n\tcount\n")
    for i=1:length(hist_user)
        if i % factor == 1
            write(f, "$i\t$(hist_user[i])\n")
        end
    end
 end

###
factor = convert(Int, round(length(hist_item) / 200))

open("t.txt", "w") do f
    write(f, "n\tcount\n")
    for i=1:length(hist_item)
        if i % factor == 1
            write(f, "$i\t$(hist_item[i])\n")
        end
    end
 end

#####
ds = datasets[3]()
sort!(ds.file, cols = :timestamp)
ds.file[:timestamp]

moments = Dict{Int, Int}()

times = unique(ds.file[:timestamp])

for i=1:length(times)
    moments[times[i]] = 0
end

for i=1:length(ds.file[:timestamp])
    moments[ds.file[:timestamp][i]] += 1
end

moments2 = hcat([keys(moments)...], [values(moments)...])


moments2_sorted = sortrows(moments2)

moments2_sorted[:,1] = moments2_sorted[:,1] .- moments2_sorted[1,1]

factor = convert(Int, round(size(moments2_sorted)[1] / 200))

open("t.txt", "w") do f
    write(f, "n\tcount\n")
    for i=1:size(moments2_sorted)[1]
        if i % factor == 1
            write(f, "$(moments2_sorted[i,1])\t$(sum(moments2_sorted[1:i,2]) ./ length(ds))\n")
        end
    end
 end



###############
sort!(ds.file, cols = :timestamp)
ds.file[:timestamp]

times = unique(ds.file[:timestamp])

qnt = collect(1:length(times))

for i=1:length(times)
    repeats = length(find(r->r==times[i], ds.file[:timestamp]))
    if repeats > 1
        qnt[i] = qnt[i] + repeats - 1
    end
end

times = times .- times[1]

################
using PyPlot
ds = datasets[1]()
sort!(ds.file, cols = :timestamp)
ds.file[:timestamp] = ds.file[:timestamp] .- ds.file[:timestamp][1]

moments = Dict{Int, Array{Int}}()

times = unique(ds.file[:timestamp])

for i=1:length(times)
    moments[times[i]] = Array{Int}(0)
end

for (u,v,r,t) in ds
    push!(moments[t], u)
end

moments2 = Array{Tuple{Int, Int, Int}}(0)

for i=1:length(times)
    users = moments[times[i]]
    for j=1:length(unique(users))
        push!(moments2, (times[i], users[j], length(find(r->r==users[j], users))))
        println(length(find(r->r==users[j], users)))
    end
end

x = Array{Int}(length(moments2))
y = Array{Int}(length(moments2))
z = Array{Int}(length(moments2))

for i=1:length(moments2)
    x[i] = moments2[i][1]
    y[i] = moments2[i][2]
    z[i] = moments2[i][3]
end


###
moments = hcat(ds.file[:user], ds.file[:timestamp])
moments[:,2] = moments[:,2] .- moments[1,2]

select = find(r->r in [1:10...], y)
select = (length(x)-1000):length(x)
###
scatter(x[select], y[select], s = z[select].*25, alpha = 0.5)

for i=1:10
    plot(x[select], repeat([i], inner = length(x[select])))
end

grid("on")
title("MovieLens")
xlabel("Tempo")
ylabel("Usuário")
