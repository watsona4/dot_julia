ds = cf.MovieLens()
@test ds.users == 943
@test ds.items == 1682
@test length(ds.preferences.possibles) == 5
@test ds.preferences.min == 1
@test ds.preferences.max == 5

ds = cf.FilmTrust()
@test ds.users == 1508
@test ds.items == 2071
@test length(ds.preferences.possibles) == 8
@test ds.preferences.min == 0.5
@test ds.preferences.max == 4.0

ds = cf.CiaoDVD()
@test ds.users == 17615
@test ds.items == 16121
@test length(ds.preferences.possibles) == 5
@test ds.preferences.min == 1
@test ds.preferences.max == 5

ds = cf.MovieTweeting()
@test ds.users == 25011
@test ds.items == 14732
@test length(ds.preferences.possibles) == 11
@test ds.preferences.min == 0
@test ds.preferences.max == 10
