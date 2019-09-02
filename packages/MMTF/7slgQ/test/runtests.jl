module TestMMTF

using Test
using MMTF

@testset "Codecs - Decoding Test" begin
    #runlengthdecode
    test_data = Int32[15,3,100,2,111,4,10000,6]
    output_data = Int32[15,15,15,100,100,111,111,111,111,10000,10000,10000,10000,10000,10000]
    eval_data = MMTF.runlengthdecode(test_data)
    @test eval_data==output_data

    #deltadecode
    test_data = Int32[15,3,100,-1,11,4]
    output_data = Int32[15,18,118,117,128,132]
    eval_data = MMTF.deltadecode(test_data)
    @test eval_data==output_data

    #deltarecursivefloatdecode
    test_data =  UInt8[0x7f,0xff,0x44,0xab,0x01,0x8f,0xff,0xca]
    output_data = Float32[50.346, 50.745, 50.691]
    eval_data = MMTF.deltarecursivefloatdecode(test_data,1000)
    @test eval_data==output_data

    #runlengthfloatdecode
    test_data = UInt8[ 0x00,0x00,0x00,0x64,0x00,0x00,0x00,0x03]
    output_data = Float32[1.00,1.00,1.00]
    eval_data = MMTF.runlengthfloatdecode(test_data,100)
    @test eval_data==output_data

    #runlengthdeltaintdecode
    test_data = UInt8[ 0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x07]
    output_data = Int32[1,2,3,4,5,6,7]
    eval_data = MMTF.runlengthdeltaintdecode(test_data)
    @test eval_data==output_data

    #runlengthchardecode
    test_data = UInt8[ 0x00,0x00,0x00,0x41,0x00,0x00,0x00,0x04]
    output_data = Char['A','A','A','A']
    eval_data = MMTF.runlengthchardecode(test_data)
    @test eval_data==output_data

    #stringdecode
    test_data = UInt8[0x42, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x43, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00]
    output_data = String["B","A","C","A","A","A"]
    eval_data = MMTF.stringdecode(test_data)
    @test eval_data==output_data

    #intdecode
    test_data = UInt8[0x07, 0x06, 0x06, 0x07, 0x07]
    output_data = Int8[7,6,6,7,7]
    eval_data = MMTF.intdecode(test_data)
    @test eval_data==output_data

    #fourbyteintdecode
    test_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    output_data = Int32[1, 131073, 0, 2]
    eval_data = MMTF.fourbyteintdecode(test_data)
    @test eval_data==output_data
end

@testset "Codecs - Encoding Test" begin
    #runlengthencode
    output_data = Int32[15,3,100,2,111,4,10000,6]
    test_data = Int32[15,15,15,100,100,111,111,111,111,10000,10000,10000,10000,10000,10000]
    eval_data = MMTF.runlengthencode(test_data)
    @test eval_data==output_data

    #deltaencode
    output_data = Int32[15,3,100,-1,11,4]
    test_data = Int32[15,18,118,117,128,132]
    eval_data = MMTF.deltaencode(test_data)
    @test eval_data==output_data
    
    #deltarecursivefloatencode
    output_data = UInt8[0x7f, 0xff, 0x44, 0xab, 0x01, 0x8f, 0xff, 0xca]
    test_data = Float32[50.346, 50.745, 50.691]
    eval_data = MMTF.deltarecursivefloatencode(test_data,1000)
    @test eval_data==output_data

    #runlengthfloatencode
    output_data = UInt8[0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x03]
    test_data = Float32[1.00,1.00,1.00]
    eval_data = MMTF.runlengthfloatencode(test_data,100)
    @test eval_data==output_data

    #runlengthdeltaintencode
    output_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x07]
    test_data = Int32[1,2,3,4,5,6,7]
    eval_data = MMTF.runlengthdeltaintencode(test_data)
    @test eval_data==output_data

    #runlengthcharencode
    output_data = UInt8[0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x04]
    test_data = Char['A','A','A','A']
    eval_data = MMTF.runlengthcharencode(test_data)
    @test eval_data==output_data

    #stringencode
    output_data = UInt8[0x42, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x43, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00]
    test_data = String["B","A","C","A","A","A"]
    eval_data = MMTF.stringencode(test_data)
    @test eval_data==output_data

    #intencode
    output_data = UInt8[0x07, 0x06, 0x06, 0x07, 0x07]
    test_data = Int8[7,6,6,7,7]
    eval_data = MMTF.intencode(test_data)
    @test eval_data==output_data

    #fourbyteintencode
    output_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    test_data = Int32[1, 131073, 0, 2]
    eval_data = MMTF.fourbyteintencode(test_data)
    @test eval_data==output_data
end

@testset "Converters Test" begin
    #Bytes to 1 byte ints
    test_data = UInt8[0x07, 0x06, 0x06, 0x07, 0x07]
    output_data = Int8[7,6,6,7,7]
    eval_data = MMTF.ints(test_data,1)
    @test eval_data==output_data

    #Bytes to 2 byte ints
    test_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    output_data = Int16[0,1,2,1,0,0,0,2]
    eval_data = MMTF.ints(test_data,2)
    @test eval_data==output_data

    #Bytes to 4 byte ints
    test_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    output_data = Int32[1, 131073, 0, 2]
    eval_data = MMTF.ints(test_data,4)
    @test eval_data==output_data

    #Floats to ints
    test_data = Float32[10.001,100.203,124.542]
    output_data = Int32[10001,100203,124542]
    eval_data = MMTF.ints(test_data,1000)
    @test eval_data==output_data

    #Ints to floats
    output_data= Float32[10.001,100.203,124.542]
    test_data = Int32[10001,100203,124542]
    eval_data = MMTF.floats(test_data,1000)
    @test eval_data==output_data

    #Ints to bytes
    output_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    test_data = Int32[1, 131073, 0, 2]
    eval_data = MMTF.bytes(test_data)
    @test eval_data==output_data

    #Ints to Chars
    test_data = Int32[66,63,67]
    output_data = Char['B', '?','C']
    eval_data = MMTF.chars(test_data)
    @test eval_data==output_data

    #decodechainlist
    test_data = UInt8[0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00]
    output_data = String["A", "A","A","A","A","A"]
    eval_data = MMTF.decodechainlist(test_data)
    @test eval_data==output_data

    #encodechainlist
    output_data = UInt8[0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00]
    test_data = String["A", "A","A","A","A","A"]
    eval_data = MMTF.encodechainlist(test_data)
    @test eval_data==output_data

    #recursiveindexdecode
    test_data = Int16[1,420,32767,0,120,-32768,0,32767,2000]
    output_data = Int32[1,420,32767,120,-32768,34767]
    eval_data = MMTF.recursiveindexdecode(test_data)
    @test eval_data==output_data

    #recursiveindexencode
    output_data = Int16[1,420,32767,0,120,-32768,0,32767,2000]
    test_data = Int32[1,420,32767,120,-32768,34767]
    eval_data = MMTF.recursiveindexencode(test_data)
    @test eval_data==output_data
end

@testset "Utils Test" begin
    #parseheader
    test_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    codec,length,param,bytearray = MMTF.parseheader(test_data)
    @test codec==1
    @test length==131073
    @test param==0
    @test size(bytearray,1)==4

    #addheader
    test_data = UInt8[0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02]
    codec=1
    length=131073
    param=0
    bytearray=UInt8[0x00, 0x00, 0x00, 0x02]
    eval_data = MMTF.addheader(bytearray,codec,length,param) 
    @test eval_data==test_data
end

@testset "Round Trip Test" begin
id_list = [
    #
    "1a1q",
    # // Just added to check
    "9pti",
    # // An entity that has no chain
    "2ja5",
    # // A couple of examples of multiple disulpgide bonds being formed.
    "3zxw",
    "1nty",
    # // A weird residue case
    "2eax",
    # // A Deuterated Structure
    "4pdj",
    # // Weird bioassembly
    "4a1i",
    # // Multi model structure
    "1cdr",
    # // Another weird structure
    "3zyb",
    # //Standard structure
    "4cup",
    # // Weird NMR structure
    "1o2f",
    # // B-DNA structure
    "1bna",
    # // DNA structure
    "4y60",
    # // Sugar structure
    "1skm",
    # // Calpha atom is missing (not marked as calpha)
    "1lpv",
    # // NMR structure with multiple models - one of which has chain missing
    "1msh",
    # // No ATOM records just HETATM records (in PDB). Opposite true for MMCif. It's a D-Peptide.
    "1r9v",
    # // Biosynthetic protein
    "5emg",
    # // Micro heterogenity
    "4ck4",
    # // Ribosome
    "4v5a",
    # // Negative residue numbers
    "5esw",
    # // A tiny example case
    "3njw",
    # // A GFP example with weird seqres records
    "1ema"]

    for pdbid in id_list
        println("PDB ID - ",pdbid)
        data_in = MMTF.fetchmmtf(pdbid)
        MMTF.writemmtf(data_in,"$(pdbid).mmtf")
        data_rt = MMTF.parsemmtf("$(pdbid).mmtf")
        @test data_in==data_rt
    end
end
end