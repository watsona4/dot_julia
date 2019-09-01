function Netflix()::Persa.CFDataset
  filename = "$(defdir)/netflix/netflix.csv"
  file = readtable(filename, separator = ',', header = false)


  df = DataFrame()

  df[:user] = labelencode(labelmap(file[:,1]), file[:,1])
  df[:item] = file[:,2]
  df[:rating] = file[:,3]

  return Persa.Dataset(df)
end

function MovieTweeting()::Persa.TimeCFDataset
  filename = "$(defdir)/Movie-Tweeting-200k/ratings.dat"
  file = readtable(filename, separator = ':', header = false)

  df = DataFrame()

  df[:user] = file[:,1]
  df[:item] = labelencode(labelmap(file[:,2]), file[:,2])
  df[:rating] = file[:,3]
  df[:timestamp] = file[:,4]

  return Persa.Dataset(df)
end

function MovieTweeting10k()::Persa.TimeCFDataset
  filename = "$(defdir)/mt-snapshot-10k/ratings.dat"
  file = readtable(filename, separator = ':', header = false)

  df = DataFrame()

  df[:user] = file[:,1]
  df[:item] = labelencode(labelmap(file[:,2]), file[:,2])
  df[:rating] = file[:,3]
  df[:timestamp] = file[:,4]

  return Persa.Dataset(df)
end

function CiaoDVD()::Persa.TimeCFDataset
  filename = "$(defdir)/CiaoDVD/movie-ratings.txt"
  file = readtable(filename, separator = ',', header = false)

  df = DataFrame()

  df[:user] = file[:,1]
  df[:item] = file[:,2]
  df[:rating] = file[:,5]
  df[:timestamp] = convert(Array{Int}, Dates.datetime2unix.(Dates.DateTime(file[:,6])))

  return Persa.Dataset(df)
end

function FilmTrust()::Persa.CFDataset
  filename = "$(defdir)/FilmTrust/ratings.txt"
  file = readtable(filename, separator = ' ', header = false)

  df = DataFrame()

  df[:user] = file[:,1]
  df[:item] = file[:,2]
  df[:rating] = file[:,3]

  return Persa.Dataset(df)
end

function YahooMusic()::Persa.CFDataset
  filename = "$(defdir)/yahoo-music-r3/ymusic-r3-dummy-time.dat"
  file = readtable(filename, separator = ' ', header = false)

  df = DataFrame()

  df[:user] = file[:,1]
  df[:item] = file[:,2]
  df[:rating] = file[:,3]

  return Persa.Dataset(df)
end

function LastFM()::Persa.CFDataset
  filename = "$(defdir)/lastfm/last_fm.dat"
  file = readtable(filename, separator = ',', header = false)

  df = DataFrame()

  df[:user] = labelencode(labelmap(file[:,1]), file[:,1])
  df[:item] = labelencode(labelmap(file[:,2]), file[:,2])
  df[:rating] = file[:,3]

  return Persa.Dataset(df)
end
