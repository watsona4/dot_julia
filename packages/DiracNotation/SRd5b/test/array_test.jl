@testset "Float" begin
    Random.seed!(0)
    ket = rand(4)
    bra = ket'
    ρ = rand(4,4)

    DiracNotation.reset_properties()
    @test sprint(dirac, ket) == "|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩+0.177329|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket)) == "|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩+0.177329|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ket)) == "|ψ⟩ = 0.8236475079774124|00⟩+0.9103565379264364|01⟩+0.16456579813368521|10⟩+0.17732884646626457|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2])) == "|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩+0.177329|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2], header=true)) == "4-element Array{Float64,1}\n|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩+0.177329|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2], "ϕ")) == "|ϕ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩+0.177329|11⟩\n"


    DiracNotation.set_properties(newline=true)
    @test sprint(dirac, ket) == "|ψ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩\n     +0.177329|11⟩\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket)) == "|ψ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩\n     +0.177329|11⟩\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ket)) == "|ψ⟩ = 0.8236475079774124|00⟩\n     +0.9103565379264364|01⟩\n     +0.16456579813368521|10⟩\n     +0.17732884646626457|11⟩\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2])) == "|ψ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩\n     +0.177329|11⟩\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2], "ϕ")) == "|ϕ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩\n     +0.177329|11⟩\n     "

    DiracNotation.reset_properties()
    DiracNotation.set_properties(precision=2)
    @test sprint(dirac, ket) == "|ψ⟩ = 0.82|00⟩+0.91|01⟩+0.16|10⟩+0.18|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket)) == "|ψ⟩ = 0.82|00⟩+0.91|01⟩+0.16|10⟩+0.18|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ket)) == "|ψ⟩ = 0.82|00⟩+0.91|01⟩+0.16|10⟩+0.18|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2])) == "|ψ⟩ = 0.82|00⟩+0.91|01⟩+0.16|10⟩+0.18|11⟩\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2], "ϕ")) == "|ϕ⟩ = 0.82|00⟩+0.91|01⟩+0.16|10⟩+0.18|11⟩\n"

    DiracNotation.reset_properties()
    DiracNotation.set_properties(displayall=false, numhead=3)
    sprint(dirac, ket) == "|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩ +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>true), ket)) == "|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩ +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>false), ket)) == "|ψ⟩ = 0.8236475079774124|00⟩+0.9103565379264364|01⟩+0.16456579813368521|10⟩ +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2])) == "|ψ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩ +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2], "ϕ")) == "|ϕ⟩ = 0.823648|00⟩+0.910357|01⟩+0.164566|10⟩ +...\n"

    DiracNotation.reset_properties()
    DiracNotation.set_properties(displayall=false, numhead=3, newline=true)
    @test sprint(dirac, ket) == "|ψ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩ +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket)) == "|ψ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩ +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ket)) == "|ψ⟩ = 0.8236475079774124|00⟩\n     +0.9103565379264364|01⟩\n     +0.16456579813368521|10⟩ +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2])) == "|ψ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩ +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ket, [2,2], "ϕ")) == "|ϕ⟩ = 0.823648|00⟩\n     +0.910357|01⟩\n     +0.164566|10⟩ +...\n"


    DiracNotation.reset_properties()
    @test sprint(dirac, bra) == "⟨ψ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10|+0.177329⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra)) == "⟨ψ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10|+0.177329⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), bra)) == "⟨ψ| = 0.8236475079774124⟨00|+0.9103565379264364⟨01|+0.16456579813368521⟨10|+0.17732884646626457⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2])) == "⟨ψ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10|+0.177329⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2], "ϕ")) == "⟨ϕ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10|+0.177329⟨11|\n"

    DiracNotation.set_properties(newline=true)
    @test sprint(dirac, bra) == "⟨ψ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10|\n     +0.177329⟨11|\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra)) == "⟨ψ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10|\n     +0.177329⟨11|\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>false), bra)) == "⟨ψ| = 0.8236475079774124⟨00|\n     +0.9103565379264364⟨01|\n     +0.16456579813368521⟨10|\n     +0.17732884646626457⟨11|\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2])) == "⟨ψ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10|\n     +0.177329⟨11|\n     "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2], "ϕ")) == "⟨ϕ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10|\n     +0.177329⟨11|\n     "

    DiracNotation.reset_properties()
    DiracNotation.set_properties(precision=2)
    @test sprint(dirac, bra) == "⟨ψ| = 0.82⟨00|+0.91⟨01|+0.16⟨10|+0.18⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra)) == "⟨ψ| = 0.82⟨00|+0.91⟨01|+0.16⟨10|+0.18⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), bra)) == "⟨ψ| = 0.82⟨00|+0.91⟨01|+0.16⟨10|+0.18⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2])) == "⟨ψ| = 0.82⟨00|+0.91⟨01|+0.16⟨10|+0.18⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2], "ϕ")) == "⟨ϕ| = 0.82⟨00|+0.91⟨01|+0.16⟨10|+0.18⟨11|\n"

    DiracNotation.reset_properties()
    DiracNotation.set_properties(displayall=false, numhead=3)
    sprint(dirac, bra) == "⟨ψ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10| +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>true), bra)) == "⟨ψ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10| +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>false), bra)) == "⟨ψ| = 0.8236475079774124⟨00|+0.9103565379264364⟨01|+0.16456579813368521⟨10| +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2])) == "⟨ψ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10| +...\n"
    sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2], "ϕ")) == "⟨ϕ| = 0.823648⟨00|+0.910357⟨01|+0.164566⟨10| +...\n"

    DiracNotation.reset_properties()
    DiracNotation.set_properties(displayall=false, numhead=3, newline=true)
    @test sprint(dirac, bra) == "⟨ψ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra)) == "⟨ψ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), bra)) == "⟨ψ| = 0.8236475079774124⟨00|\n     +0.9103565379264364⟨01|\n     +0.16456579813368521⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2])) == "⟨ψ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), bra, [2,2], "ϕ")) == "⟨ϕ| = 0.823648⟨00|\n     +0.910357⟨01|\n     +0.164566⟨10| +...\n"


    DiracNotation.reset_properties()
    @test sprint(dirac, ρ) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|+0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|+0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|+0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ)) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|+0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|+0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|+0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ρ)) == "ρ = 0.278880109331201|00⟩⟨00|+0.3618283907762174|00⟩⟨01|+0.26003585026904785|00⟩⟨10|+0.5758873948500367|00⟩⟨11|+0.20347655804192266|01⟩⟨00|+0.9732164043865108|01⟩⟨01|+0.910046541351011|01⟩⟨10|+0.8682787096942046|01⟩⟨11|+0.042301665932029664|10⟩⟨00|+0.5858115517433242|10⟩⟨01|+0.16703619444214968|10⟩⟨10|+0.9677995536192001|10⟩⟨11|+0.06826925550564478|11⟩⟨00|+0.5392892841426182|11⟩⟨01|+0.6554484126999125|11⟩⟨10|+0.7676903325581188|11⟩⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2])) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|+0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|+0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|+0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2], header=true)) == "4×4 Array{Float64,2}\nρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|+0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|+0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|+0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2], "ϕ")) == "ϕ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|+0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|+0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|+0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n"

    DiracNotation.reset_properties()
    DiracNotation.set_properties(newline=true)
    @test sprint(dirac, ρ) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|\n   +0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|\n   +0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|\n   +0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n   "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ)) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|\n   +0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|\n   +0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|\n   +0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n   "
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ρ)) == "ρ = 0.278880109331201|00⟩⟨00|+0.3618283907762174|00⟩⟨01|+0.26003585026904785|00⟩⟨10|+0.5758873948500367|00⟩⟨11|\n   +0.20347655804192266|01⟩⟨00|+0.9732164043865108|01⟩⟨01|+0.910046541351011|01⟩⟨10|+0.8682787096942046|01⟩⟨11|\n   +0.042301665932029664|10⟩⟨00|+0.5858115517433242|10⟩⟨01|+0.16703619444214968|10⟩⟨10|+0.9677995536192001|10⟩⟨11|\n   +0.06826925550564478|11⟩⟨00|+0.5392892841426182|11⟩⟨01|+0.6554484126999125|11⟩⟨10|+0.7676903325581188|11⟩⟨11|\n   "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2])) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|\n   +0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|\n   +0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|\n   +0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n   "
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2], "ϕ")) == "ϕ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10|+0.575887|00⟩⟨11|\n   +0.203477|01⟩⟨00|+0.973216|01⟩⟨01|+0.910047|01⟩⟨10|+0.868279|01⟩⟨11|\n   +0.0423017|10⟩⟨00|+0.585812|10⟩⟨01|+0.167036|10⟩⟨10|+0.9678|10⟩⟨11|\n   +0.0682693|11⟩⟨00|+0.539289|11⟩⟨01|+0.655448|11⟩⟨10|+0.76769|11⟩⟨11|\n   "

    DiracNotation.reset_properties()
    DiracNotation.set_properties(displayall=false, numhead=3)
    @test sprint(dirac, ρ) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ)) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>false), ρ)) == "ρ = 0.278880109331201|00⟩⟨00|+0.3618283907762174|00⟩⟨01|+0.26003585026904785|00⟩⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2])) == "ρ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10| +...\n"
    @test sprint(io -> dirac(IOContext(io, :compact=>true), ρ, [2,2], [2,2], "ϕ")) == "ϕ = 0.27888|00⟩⟨00|+0.361828|00⟩⟨01|+0.260036|00⟩⟨10| +...\n"

end # testset "Float64"

DiracNotation.reset_properties()
@testset "Int" begin
    @test sprint(dirac, [1,0]) == "|ψ⟩ = |0⟩\n"
    @test sprint(dirac, [0,1]) == "|ψ⟩ = |1⟩\n"
    @test sprint(dirac, [1,1]) == "|ψ⟩ = |0⟩+|1⟩\n"
    @test sprint(dirac, [1,-1]) == "|ψ⟩ = |0⟩-|1⟩\n"
    @test sprint(dirac, [-1,1]) == "|ψ⟩ = -|0⟩+|1⟩\n"
    @test sprint(dirac, [-1,-1]) == "|ψ⟩ = -|0⟩-|1⟩\n"
    @test sprint(dirac, [2,3]) == "|ψ⟩ = 2|0⟩+3|1⟩\n"
    @test sprint(dirac, [-2,3]) == "|ψ⟩ = -2|0⟩+3|1⟩\n"
    @test sprint(dirac, [2,-3]) == "|ψ⟩ = 2|0⟩-3|1⟩\n"
    @test sprint(dirac, [-2,-3]) == "|ψ⟩ = -2|0⟩-3|1⟩\n"
    @test sprint(dirac, [1 0; 0 0]) == "ρ = |0⟩⟨0|\n"
    @test sprint(dirac, [0 1; 0 0]) == "ρ = |0⟩⟨1|\n"
    @test sprint(dirac, [0 0; 1 0]) == "ρ = |1⟩⟨0|\n"
    @test sprint(dirac, [0 0; 0 1]) == "ρ = |1⟩⟨1|\n"
    @test sprint(dirac, ones(Int, 2,2)) == "ρ = |0⟩⟨0|+|0⟩⟨1|+|1⟩⟨0|+|1⟩⟨1|\n"
    Random.seed!(0)
    @show rho = rand(-4:4, 2, 2)
    @test sprint(dirac, rho) == "ρ = -4|0⟩⟨0|+|0⟩⟨1|-2|1⟩⟨0|-4|1⟩⟨1|\n"
    rho[4] = 0
    @test sprint(dirac, rho) == "ρ = -4|0⟩⟨0|+|0⟩⟨1|-2|1⟩⟨0|\n"


    # sprint(dirac, [1,0])
    # sprint(dirac, [0,1])
    # sprint(dirac, [1,1])
    # sprint(dirac, [1,-1])
    # sprint(dirac, [-1,1])
    # sprint(dirac, [-1,-1])
    # sprint(dirac, [2,3])
    # sprint(dirac, [-2,3])
    # sprint(dirac, [2,-3])
    # sprint(dirac, [-2,-3])
    #
    # sprint(dirac, [1 0; 0 0])
    # sprint(dirac, [0 1; 0 0])
    # sprint(dirac, [0 0; 1 0])
    # sprint(dirac, [0 0; 0 1])
    # sprint(dirac, ones(Int, 2,2))
    #
    # Random.seed!(0)
    # @show rho = rand(-4:4, 2, 2)
    # sprint(dirac, rho)
    # rho[4] = 0
    # sprint(dirac, rho)

end # testset "Int"


@testset "Complex" begin

    @test sprint(dirac, Complex{Int}[1,0]) == "|ψ⟩ = |0⟩\n"
    @test sprint(dirac, Complex{Int}[0, 1]) == "|ψ⟩ = |1⟩\n"
    @test sprint(dirac, Complex{Int}[1, 1]) == "|ψ⟩ = |0⟩+|1⟩\n"
    @test sprint(dirac, Complex{Int}[1,1]) == "|ψ⟩ = |0⟩+|1⟩\n"
    @test sprint(dirac, Complex{Int}[1,-1]) == "|ψ⟩ = |0⟩-|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1,1]) == "|ψ⟩ = -|0⟩+|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1,-1]) == "|ψ⟩ = -|0⟩-|1⟩\n"
    @test sprint(dirac, Complex{Int}[1im,1im]) == "|ψ⟩ = im|0⟩+im|1⟩\n"
    @test sprint(dirac, Complex{Int}[1im,-1im]) == "|ψ⟩ = im|0⟩-im|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1im,1im]) == "|ψ⟩ = -im|0⟩+im|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1im,-1im]) == "|ψ⟩ = -im|0⟩-im|1⟩\n"
    @test sprint(dirac, Complex{Int}[1+1im,1+1im]) == "|ψ⟩ = (1+im)|0⟩+(1+im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[1+1im,1-1im]) == "|ψ⟩ = (1+im)|0⟩+(1-im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[1-1im,1+1im]) == "|ψ⟩ = (1-im)|0⟩+(1+im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[1-1im,1-1im]) == "|ψ⟩ = (1-im)|0⟩+(1-im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1+1im,-1+1im]) == "|ψ⟩ = (-1+im)|0⟩+(-1+im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1+1im,-1-1im]) == "|ψ⟩ = (-1+im)|0⟩+(-1-im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1-1im,-1+1im]) == "|ψ⟩ = (-1-im)|0⟩+(-1+im)|1⟩\n"
    @test sprint(dirac, Complex{Int}[-1-1im,-1-1im]) == "|ψ⟩ = (-1-im)|0⟩+(-1-im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1,0]) == "|ψ⟩ = |0⟩\n"
    @test sprint(dirac, Complex{Float64}[0, 1]) == "|ψ⟩ = |1⟩\n"
    @test sprint(dirac, Complex{Float64}[1, 1]) == "|ψ⟩ = |0⟩+|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1,1]) == "|ψ⟩ = |0⟩+|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1,-1]) == "|ψ⟩ = |0⟩-|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1,1]) == "|ψ⟩ = -|0⟩+|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1,-1]) == "|ψ⟩ = -|0⟩-|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1im,1im]) == "|ψ⟩ = im|0⟩+im|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1im,-1im]) == "|ψ⟩ = im|0⟩-im|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1im,1im]) == "|ψ⟩ = -im|0⟩+im|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1im,-1im]) == "|ψ⟩ = -im|0⟩-im|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1+1im,1+1im]) == "|ψ⟩ = (1.0+im)|0⟩+(1.0+im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1+1im,1-1im]) == "|ψ⟩ = (1.0+im)|0⟩+(1.0-im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1-1im,1+1im]) == "|ψ⟩ = (1.0-im)|0⟩+(1.0+im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[1-1im,1-1im]) == "|ψ⟩ = (1.0-im)|0⟩+(1.0-im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1+1im,-1+1im]) == "|ψ⟩ = (-1.0+im)|0⟩+(-1.0+im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1+1im,-1-1im]) == "|ψ⟩ = (-1.0+im)|0⟩+(-1.0-im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1-1im,-1+1im]) == "|ψ⟩ = (-1.0-im)|0⟩+(-1.0+im)|1⟩\n"
    @test sprint(dirac, Complex{Float64}[-1-1im,-1-1im]) == "|ψ⟩ = (-1.0-im)|0⟩+(-1.0-im)|1⟩\n"
    Random.seed!(0)
    @show x = rand(-4:4, 2,2) + im*rand(-4:4, 2,2)
    @test sprint(dirac, x) == "ρ = (-4-4im)|0⟩⟨0|+(1+4im)|0⟩⟨1|+(-2-im)|1⟩⟨0|+(-4+3im)|1⟩⟨1|\n"
    x[4] = 0
    @test sprint(dirac, x) == "ρ = (-4-4im)|0⟩⟨0|+(1+4im)|0⟩⟨1|+(-2-im)|1⟩⟨0|\n"
    x = randn(Complex{Float64}, 2,2)
    @test sprint(dirac, x) == "ρ = (-0.539384+0.281063im)|0⟩⟨0|+(-0.132634-1.1365im)|0⟩⟨1|+(0.573909-0.24491im)|1⟩⟨0|+(-1.75419+1.60954im)|1⟩⟨1|\n"

    # sprint(dirac, Complex{Int}[1,0])
    # sprint(dirac, Complex{Int}[0, 1])
    # sprint(dirac, Complex{Int}[1, 1])
    # sprint(dirac, Complex{Int}[1,1])
    # sprint(dirac, Complex{Int}[1,-1])
    # sprint(dirac, Complex{Int}[-1,1])
    # sprint(dirac, Complex{Int}[-1,-1])
    # sprint(dirac, Complex{Int}[1im,1im])
    # sprint(dirac, Complex{Int}[1im,-1im])
    # sprint(dirac, Complex{Int}[-1im,1im])
    # sprint(dirac, Complex{Int}[-1im,-1im])
    # sprint(dirac, Complex{Int}[1+1im,1+1im])
    # sprint(dirac, Complex{Int}[1+1im,1-1im])
    # sprint(dirac, Complex{Int}[1-1im,1+1im])
    # sprint(dirac, Complex{Int}[1-1im,1-1im])
    # sprint(dirac, Complex{Int}[-1+1im,-1+1im])
    # sprint(dirac, Complex{Int}[-1+1im,-1-1im])
    # sprint(dirac, Complex{Int}[-1-1im,-1+1im])
    # sprint(dirac, Complex{Int}[-1-1im,-1-1im])
    #
    # sprint(dirac, Complex{Float64}[1,0])
    # sprint(dirac, Complex{Float64}[0, 1])
    # sprint(dirac, Complex{Float64}[1, 1])
    # sprint(dirac, Complex{Float64}[1,1])
    # sprint(dirac, Complex{Float64}[1,-1])
    # sprint(dirac, Complex{Float64}[-1,1])
    # sprint(dirac, Complex{Float64}[-1,-1])
    # sprint(dirac, Complex{Float64}[1im,1im])
    # sprint(dirac, Complex{Float64}[1im,-1im])
    # sprint(dirac, Complex{Float64}[-1im,1im])
    # sprint(dirac, Complex{Float64}[-1im,-1im])
    # sprint(dirac, Complex{Float64}[1+1im,1+1im])
    # sprint(dirac, Complex{Float64}[1+1im,1-1im])
    # sprint(dirac, Complex{Float64}[1-1im,1+1im])
    # sprint(dirac, Complex{Float64}[1-1im,1-1im])
    # sprint(dirac, Complex{Float64}[-1+1im,-1+1im])
    # sprint(dirac, Complex{Float64}[-1+1im,-1-1im])
    # sprint(dirac, Complex{Float64}[-1-1im,-1+1im])
    # sprint(dirac, Complex{Float64}[-1-1im,-1-1im])
    # Random.seed!(0)
    # @show x = rand(-4:4, 2,2) + im*rand(-4:4, 2,2)
    # sprint(dirac, x)

end # testset "Complex"
