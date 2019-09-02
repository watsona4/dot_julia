using Test, LazyWAVFiles, WAV

d = mktempdir()
a,b = randn(Float32,10), randn(Float32,10)
WAV.wavwrite(a, joinpath(d,"f1.wav"), Fs=8000)
WAV.wavwrite(b, joinpath(d,"f2.wav"), Fs=8000)

df = DistributedWAVFile(d)
@test df[1] == a[1]
@test df[1:2] == a[1:2]
@test df[1:10] == a
@test df[:] == [a;b]
@test df[9:11] == [a[9:end];b[1]]
@test df[[1,3,5]] == a[[1,3,5]]
@test df[[1,3,5,12]] == [a[[1,3,5]];b[2]]


@test size(df) == (20,)
@test length(df) == 20
@test length(df.files[1]) == 10
@test_nowarn display(df)
@test_nowarn display(df.files[1])

@test ndims(df.files[1]) == 1
