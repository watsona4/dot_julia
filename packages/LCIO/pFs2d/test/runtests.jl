using LCIO
using Test

# test iteration
LCIO.open("test.slcio") do reader
for event in reader
    mcparts = getCollection(event, "MCParticle")
    for p in mcparts
        e = getEnergy(p)
        @test e > 0
        momentum = getMomentum(p)
        if getPDG(p) != 22
            # tolerance, since we're dealing with floats
            @test getEnergy(p)^2 - sum(momentum.^2) > -1e-12
        else
            @test abs(getEnergy(p)^2 - sum(momentum.^2)) < 1e-12
        end
        parentList = getParents(p)
        for parent in parentList
            @test getEnergy(parent) > 0
        end
        #direct access
        nParents = length(parentList)
        for i = 1:nParents
            @test getEnergy(parentList[i]) > 0
        end
    end
end
end
println("First iteration successful")

# test that everything is closed and opened properly
LCIO.open("test.slcio") do reader
iEvent = 0
for event in reader
    iEvent += 1
    @test length(getCollectionNames(event)) == 23
    @test getDetectorName(event) == "sidloi3_scint1x1"
    HcalBarrelHits = getCollection(event, "HcalBarrelHits")
    @test getTypeName(HcalBarrelHits) == "LCIO.SimCalorimeterHit"
    decode = CellIDDecoder(HcalBarrelHits)
    l = length(HcalBarrelHits)
    # getNumberOfElements should not be exported
    @test l == LCIO.getNumberOfElements(HcalBarrelHits)
    iHit = 0
    for h in HcalBarrelHits
        @test 0 <= decode(h)["layer"] <= 39
        iHit += 1
    end
    # test iteration -- julia counting vs. C counting
    @test l == iHit
end
@test iEvent == length(reader)
end
println("Second iteration successful")

# test the stdhep reader
LCIO.openStdhep("test.stdhep") do reader
    iEvent = 0
    for event in reader
        iEvent += 1
        iParticle = 0
        for particle in event
            iParticle += 1
        end
        @test iParticle == length(event)
    end
    @test iEvent == length(reader)
end
println("Stdhep iteration successful")

# test creating a new file and writing out a particle
wrt = LCIO.createLCWriter()

LCIO.open(wrt, "writeTest.slcio", LCIO.WRITE_NEW)
run = LCIO.LCRunHeaderImpl()
LCIO.setRunNumber(run, 0)
LCIO.setValue(LCIO.parameters(run),"Purpose","runTest")
LCIO.setValue(LCIO.parameters(run), "intval", 1 )
LCIO.setValue(LCIO.parameters(run), "floatval", 3.14f0)
LCIO.writeRunHeader(wrt, run)
p = 5.0
pdg = -13
charge = +1.f0
mass =  0.105658f0
theta = 85. / 180.f0 * pi
for i in 1:1
    evt = LCIO.LCEventImpl()
    col = LCIO.LCCollectionVec(LCIO.MCPARTICLE)
    LCIO.setTransient(col, false)
    LCIO.setEventNumber(evt, i)
    phi = rand() * 2pi
    energy = sqrt(mass^2 + p^2)
    px = p * cos(phi) * sin(theta)
    py = p * sin(phi) * sin(theta)
    pz = p * cos(theta)
    momentum  = [ px, py, pz ]
#--------------- create MCParticle -------------------
    mcp = LCIO.MCParticleImpl()
    LCIO.setGeneratorStatus(mcp, 1)
    LCIO.setMass(mcp, mass)
    LCIO.setPDG(mcp, pdg)
    LCIO.setMomentum(mcp, momentum)
    LCIO.setCharge(mcp, charge)
    LCIO.addElement(col, mcp)
    LCIO.addCollection(evt, col, "genParticles")
    LCIO.writeEvent(wrt, evt)
end
LCIO.close(wrt)
println("WriteEvent successful")
