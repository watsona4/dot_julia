const defdir = joinpath(dirname(@__FILE__), "..", "datasets")

function getmovielensdata(dir)
	mkpath(dir)
	path = download("http://files.grouplens.org/datasets/movielens/ml-100k.zip")
	run(unpack_cmd(path,dir,".zip", ""))
end

function getmovielensdata1m(dir)
	mkpath(dir)
	path = download("http://files.grouplens.org/datasets/movielens/ml-1m.zip")
	run(unpack_cmd(path,dir,".zip", ""))
end

"""
    MovieLens()::Persa.Dataset

Return MovieLens 100k dataset.
"""
function MovieLens()::Persa.Dataset
	filename = "$(defdir)/ml-100k/u.data"

	isfile(filename) || getmovielensdata(defdir)

	file = CSV.read(filename, delim = '	',
	                      header = [:user, :item, :rating, :timestamp],
	                      allowmissing = :none)

	return Persa.Dataset(file)
end

"""
    MovieLens1M()::Persa.Dataset

Return MovieLens 1M dataset.
"""
function MovieLens1M()::Persa.Dataset
    filename = "$(defdir)/ml-1m/ratings.dat"

    isfile(filename) || getmovielensdata1m(defdir)

    file = CSV.read(filename, delim = "::",
							header = [:user, :item, :rating, :timestamp],
							allowmissing = :all)

    df = DataFrame()

	df[:user] = convert(Array{Int}, file[:user])
	df[:item] = convert(Array{Int}, file[:item])
	df[:item] = labelencode(labelmap(df[:item]), df[:item])
	df[:rating] = convert(Array{Int}, file[:rating])
	df[:timestamp] = convert(Array{Int}, file[:timestamp])

    return Persa.Dataset(df)
end
