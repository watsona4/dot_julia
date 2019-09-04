# Test data are generated using abelfunctions and Sage 8.6

ϵ = 1e-3

@testset "Genus 1" begin
    z = [0.85746943+0.30772689im];
    τ = [0.63443932+0.49919024im];
    Y = imag(τ);
    x = real(z);
    y = convert(Array{Float64}, imag(z));
    Yinv = inv.(Y);
    y0 = Yinv.*y;
    R = RiemannMatrix(τ, siegel=false);
    @test Theta.oscillatory_part(R, x, y0, [0]) ≈ -0.257+0.197im atol=ϵ
    @test theta(z, R) ≈ -0.466+0.358im atol=ϵ
    @test theta(z, R, derivs=[[1]]) ≈ 1.724+9.922im atol=ϵ
    @test theta(z, R, derivs=[[1],[1]]) ≈ 67.973-10.642im atol=ϵ
    @test theta(z, R, char=[[1],[0]]) ≈ -1.770-1.225im atol=ϵ
    @test theta(z, R, char=[[1],[1]]) ≈ -1.669+0.298im atol=ϵ
    @test theta(z, R, char=[[1],[0]], derivs=[[1]]) ≈ -2.368+6.931im atol=ϵ
    @test theta(z, R, char=[[1],[1]], derivs=[[1]]) ≈ -0.488+6.871im atol=ϵ
    @test symplectic_transform(siegel_transform(τ)[1], τ) ≈ siegel_transform(τ)[2]
end

@testset "Genus 2" begin
    z = [0.81149300+0.27027128im; 0.77132834+0.26619567im];
    τ = [0.71106237+1.20021283im 0.57281731+0.89762698im; 0.57281731+0.89762698im 0.22079146+0.68617488im];
    Y = imag(τ);
    x = real(z);
    y = convert(Array{Float64}, imag(z));
    Yinv = inv(Y);
    y0 = Yinv*y
    R = RiemannMatrix(τ, siegel=false);
    @test Theta.oscillatory_part(R, x, y0, [0,0]) ≈ 0.5894+0.3593im atol=ϵ
    @test theta(z, R) ≈ 1.700489+1.03657im atol=ϵ
    @test theta(z, R, derivs=[[1,0]]) ≈ -13.73322+34.5327im atol=ϵ
    @test theta(z, R, derivs=[[0,1]]) ≈ 14.71768-51.3656im atol=ϵ
    @test theta(z, R, derivs=[[1,0], [1,0]]) ≈ -1859.654+898.206im atol=ϵ
    @test theta(z, R, derivs=[[1,0], [0,1]]) ≈ 2533.2922-1397.9940im atol=ϵ
    @test theta(z, R, char=[[1,0],[1,1]]) ≈ -5.91176+4.90798im atol=ϵ
    @test theta(z, R, char=[[1,0],[0,1]]) ≈ -0.68197+0.13723im atol=ϵ
    @test theta(z, R, char=[[1,0],[1,1]], derivs=[[1,0]]) ≈ -33.55188-104.14870im atol=ϵ
    @test theta(z, R, char=[[1,0],[0,1]], derivs=[[0,1]]) ≈ 20.42986+95.749276im atol=ϵ
    @test symplectic_transform(siegel_transform(τ)[1], τ) ≈ siegel_transform(τ)[2]
end


@testset "Genus 3" begin
    z = [0.76394595+0.5283701im; 0.03744967+0.0898654im; 0.65786408+0.77005086im];
    τ = [0.85625765+1.13705995im 0.14147041+0.43763364im 0.64991508+1.07829521im; 0.14147041+0.43763364im 0.28765738+0.60567227im 0.27742587+0.38069182im; 0.64991508+1.07829521im 0.27742587+0.38069182im 0.23093880+1.81289325im];
    Y = imag(τ);
    x = real(z);
    y = convert(Array{Float64}, imag(z));
    Yinv = inv(Y);
    y0 = Yinv*y
    R = RiemannMatrix(τ, siegel=false);
    @test Theta.oscillatory_part(R, x, y0, [0,0,0]) ≈ 0.11045-0.28985im atol=ϵ
    @test theta(z, R) ≈ 0.34318-0.900595im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0]]) ≈ -11.647091+6.51591im atol=ϵ
    @test theta(z, R, derivs=[[0,1,0]]) ≈ 5.57557-4.17216im atol=ϵ
    @test theta(z, R, derivs=[[0,0,1]]) ≈ 3.68145+1.71192im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0], [1,0,0]]) ≈ 7.8837+62.5345im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0], [0,1,0]]) ≈ -9.2622-32.7841im atol=ϵ
    @test theta(z, R, derivs=[[0,0,1], [0,0,1]]) ≈ 9.8031-19.6301im atol=ϵ
    @test theta(z, R, char=[[0,0,1],[0,1,1]]) ≈ -1.345015+0.31343im atol=ϵ
    @test theta(z, R, char=[[1,1,0],[0,1,0]]) ≈ 1.039441-0.95682im atol=ϵ
    @test theta(z, R, char=[[0,0,1],[0,1,1]], derivs=[[0,1,0]]) ≈ 4.045043+3.521485im atol=ϵ
    @test symplectic_transform(siegel_transform(τ)[1], τ) ≈ siegel_transform(τ)[2]
end

@testset "Genus 4" begin
    z = [0.04134584+0.40910551im; 0.20972589+0.90269823im; 0.39996195+0.42432923im; 0.73063375+0.49945621im];
    τ = [0.95870734+0.73587725im 0.22092477+0.76863646im 0.53877459+0.87577267im 0.68177023+0.867436im; 0.22092477+0.76863646im 0.98812562+1.79674905im 0.54859032+1.10626215im 0.63310305+1.30158981im; 0.53877459+0.87577267im 0.54859032+1.10626215im 0.50173043+1.27729044im 0.49163557+1.33147334im; 0.68177023+0.867436im 0.63310305+1.30158981im 0.49163557+1.33147334im 0.35312207+1.60745975im];
    Y = imag(τ);
    x = real(z);
    y = convert(Array{Float64}, imag(z));
    Yinv = inv(Y);
    y0 = Yinv*y
    R = RiemannMatrix(τ, siegel=false);
    @test Theta.oscillatory_part(R, x, y0, [0,0,0,0]) ≈ -1.35525+1.05162im atol=ϵ
    @test theta(z, R) ≈ -8.24515+6.39791im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0,0]]) ≈ 62.08697+26.90192im atol=ϵ
    @test theta(z, R, derivs=[[0,1,0,0]]) ≈ 21.74519+37.036989im atol=ϵ
    @test theta(z, R, derivs=[[0,0,1,0]]) ≈ -75.17050+14.28415im atol=ϵ
    @test theta(z, R, derivs=[[0,0,0,1]]) ≈ 32.02015-36.54835im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0,0], [1,0,0,0]]) ≈ -133.4336-555.3991im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0,0], [0,1,0,0]]) ≈ 4.08109-225.3261im atol=ϵ
    @test theta(z, R, derivs=[[0,1,0,0], [0,0,1,0]]) ≈ 132.01459+365.6160im atol=ϵ
    @test theta(z, R, derivs=[[0,0,0,1], [0,0,0,1]]) ≈ 89.8953-145.9657im atol=ϵ
    @test theta(z, R, char=[[0,1,0,1],[0,1,0,0]]) ≈ 15.51204+1.32669im atol=ϵ
    @test theta(z, R, char=[[0,1,0,0],[0,0,0,1]]) ≈ 1.852505-1.75216im atol=ϵ
    @test theta(z, R, char=[[0,1,0,1],[0,1,0,0]], derivs=[[0,0,1,0]]) ≈ 28.8916+90.992105im atol=ϵ
    @test symplectic_transform(siegel_transform(τ)[1], τ) ≈ siegel_transform(τ)[2]
end

@testset "Genus 5" begin
    z = [0.76931119+0.61774429im; 0.74693159+0.23398854im; 0.68457901+0.49648231im; 0.59332210+0.25122584im; 0.02494457+0.27172437im];
    τ = [0.17012929+3.36021399im 0.42793573+1.65263414im 0.55503983+2.1393021im 0.49182605+2.17345553im 0.93865305+1.81009273im; 0.42793573+1.65263414im 0.87402978+1.33203047im 0.53489381+0.68238397im 0.57601957+1.20509707im 0.50028888+1.11605622im; 0.55503983+2.1393021im 0.53489381+0.68238397im 0.21882206+2.28319153im 0.74421992+1.51352273im 0.41855281+0.87400937im; 0.49182605+2.17345553im 0.57601957+1.20509707im 0.74421992+1.51352273im 0.51070570+1.62305859im 0.52380319+1.15073893im; 0.93865305+1.81009273im 0.50028888+1.11605622im 0.41855281+0.87400937im 0.52380319+1.15073893im 0.79948032+1.38925759im];
    Y = imag(τ);
    x = real(z);
    y = convert(Array{Float64}, imag(z));
    Yinv = inv(Y);
    y0 = Yinv*y
    R = RiemannMatrix(τ, siegel=false);
    @test Theta.oscillatory_part(R, x, y0, [0,0,0,0,0]) ≈ -0.13999-0.20302im atol=ϵ
    @test theta(z, R) ≈ -0.43584-0.632066im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0,0,0]]) ≈ -16.240575+7.856723im atol=ϵ
    @test theta(z, R, derivs=[[0,1,0,0,0]]) ≈ 14.447895+1.37822im atol=ϵ
    @test theta(z, R, derivs=[[0,0,1,0,0]]) ≈ 14.232547+0.23889im atol=ϵ
    @test theta(z, R, derivs=[[0,0,0,1,0]]) ≈ -5.509064-15.47362im atol=ϵ
    @test theta(z, R, derivs=[[0,0,0,0,1]]) ≈ 0.796003+6.15536im atol=ϵ
    @test theta(z, R, derivs=[[1,0,0,0,0], [1,0,0,0,0]]) ≈ 150.0687+120.7466im atol=ϵ
    @test theta(z, R, derivs=[[0,0,1,0,0], [0,0,0,1,0]]) ≈ -33.6935+132.9402im atol=ϵ
    @test theta(z, R, derivs=[[0,0,1,0,0], [0,1,0,0,0]]) ≈ -15.0943-138.2480im atol=ϵ
    @test theta(z, R, derivs=[[0,0,0,1,0], [0,0,0,1,0]]) ≈ 330.7400-145.8428im atol=ϵ
    @test theta(z, R, derivs=[[0,0,0,0,1], [0,1,0,0,0]]) ≈ 127.4712+47.0716im atol=ϵ
    @test theta(z, R, char=[[0,1,0,1,1],[0,1,1,0,0]]) ≈ 1.03805-0.46603im atol=ϵ
    @test theta(z, R, char=[[1,1,1,0,1],[0,1,1,1,0]]) ≈ -1.41336+4.24756im atol=ϵ
    @test theta(z, R, char=[[1,1,1,0,1],[0,1,1,1,0]], derivs=[[1,0,0,0,0]]) ≈ -1.49522 + 5.56114im atol=ϵ
    @test symplectic_transform(siegel_transform(τ)[1], τ) ≈ siegel_transform(τ)[2]
end



@testset "Azygetic" begin
    @test check_azygetic([[[1,0,1,0], [1,0,1,0]], [[0,0,0,1], [1,0,0,0]], [[0,0,1,1], [1,0,1,1]]]) == true
end


