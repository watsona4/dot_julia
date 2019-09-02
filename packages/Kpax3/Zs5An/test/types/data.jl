# This file is part of Kpax3. License is MIT.

function test_data_exceptions()
  f = "../build/test"

  @test_throws Kpax3.KFASTAError Kpax3.NucleotideData(Kpax3.KSettings("data/read_empty_file.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.NucleotideData(Kpax3.KSettings("data/read_no_id_char.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.NucleotideData(Kpax3.KSettings("data/read_no_1st_seq.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.NucleotideData(Kpax3.KSettings("data/read_no_nth_seq.fasta", f))

  @test_throws Kpax3.KFASTAError Kpax3.NucleotideData(Kpax3.KSettings("data/read_utf8_id.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.NucleotideData(Kpax3.KSettings("data/read_utf8_seq.fasta", f))

  @test_throws Kpax3.KFASTAError Kpax3.AminoAcidData(Kpax3.KSettings("data/read_empty_file.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.AminoAcidData(Kpax3.KSettings("data/read_no_id_char.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.AminoAcidData(Kpax3.KSettings("data/read_no_1st_seq.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.AminoAcidData(Kpax3.KSettings("data/read_no_nth_seq.fasta", f))

  @test_throws Kpax3.KFASTAError Kpax3.AminoAcidData(Kpax3.KSettings("data/read_utf8_id.fasta", f))
  @test_throws Kpax3.KFASTAError Kpax3.AminoAcidData(Kpax3.KSettings("data/read_utf8_seq.fasta", f))

  @test_throws Kpax3.KCSVError Kpax3.CategoricalData(Kpax3.KSettings("data/read_empty_file.csv", f))
  @test_throws Kpax3.KCSVError Kpax3.CategoricalData(Kpax3.KSettings("data/read_no_id_char.csv", f))
  @test_throws Kpax3.KCSVError Kpax3.CategoricalData(Kpax3.KSettings("data/read_no_1st_seq.csv", f))
  @test_throws Kpax3.KCSVError Kpax3.CategoricalData(Kpax3.KSettings("data/read_no_nth_seq.csv", f))

  nothing
end

test_data_exceptions()

function test_data_blanks()
  f = "../build/test"

  nt = Kpax3.NucleotideData(Kpax3.KSettings("data/read_blanks.fasta", f))
  @test nt.data == UInt8[0 1;
                         1 0;
                         1 0;
                         0 1;
                         0 1;
                         1 0;
                         1 0;
                         0 1;
                         1 0;
                         0 1;
                         0 1;
                         1 0]
  @test nt.id == ["ID1", "ID5"]
  @test nt.ref == UInt8['a', 't', 'g', '.', '.', '.', 'g', '.', '.', 'a', '.', 'a']
  @test nt.val == UInt8['a', 'g', 'a', 'g', 'c', 'g', 'c', 'g', 'a', 'g', 'c', 'g']
  @test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

  nt = Kpax3.NucleotideData(Kpax3.KSettings("data/read_blanks.fasta", f, l=1))
  @test nt.data == UInt8[0 1;
                         1 0;
                         1 0;
                         0 1;
                         0 1;
                         1 0;
                         1 0;
                         0 1;
                         1 0;
                         0 1;
                         0 1;
                         1 0]
  @test nt.id == ["ID1", "ID5"]
  @test nt.ref == UInt8['a', 't', 'g', '.', '.', '.', 'g', '.', '.', 'a', '.', 'a']
  @test nt.val == UInt8['a', 'g', 'a', 'g', 'c', 'g', 'c', 'g', 'a', 'g', 'c', 'g']
  @test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

  aa = Kpax3.AminoAcidData(Kpax3.KSettings("data/read_blanks.fasta", f))
  @test aa.data == UInt8[0 1;
                         1 0;
                         1 0;
                         0 1;
                         0 1;
                         1 0;
                         1 0;
                         0 1;
                         1 0;
                         0 1;
                         0 1;
                         1 0]
  @test aa.id == ["ID1", "ID5"]
  @test aa.ref == UInt8['a', 't', 'g', '.', '.', '.', 'g', '.', '.', 'a', '.', 'a']
  @test aa.val == UInt8['a', 'g', 'a', 'g', 'c', 'g', 'c', 'g', 'a', 'g', 'c', 'g']
  @test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

  aa = Kpax3.AminoAcidData(Kpax3.KSettings("data/read_blanks.fasta", f, l=1))
  @test aa.data == UInt8[0 1;
                         1 0;
                         1 0;
                         0 1;
                         0 1;
                         1 0;
                         1 0;
                         0 1;
                         1 0;
                         0 1;
                         0 1;
                         1 0]
  @test aa.id == ["ID1", "ID5"]
  @test aa.ref == UInt8['a', 't', 'g', '.', '.', '.', 'g', '.', '.', 'a', '.', 'a']
  @test aa.val == UInt8['a', 'g', 'a', 'g', 'c', 'g', 'c', 'g', 'a', 'g', 'c', 'g']
  @test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

  cg = Kpax3.CategoricalData(Kpax3.KSettings("data/read_blanks.csv", f, l=1))

  nothing
end

test_data_blanks()

function test_data_proper_dna_file()
  f = "../build/test"

  nt = Kpax3.NucleotideData(Kpax3.KSettings("data/read_proper_nt.fasta", f))
  @test nt.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 1 1 1;
                         1 1 1 0 0 0;
                         0 0 1 0 0 0;
                         1 0 0 1 0 1;
                         0 1 0 0 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 0 0 1;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         0 1 0 0 1 0;
                         1 0 1 1 0 1]
  @test nt.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test nt.ref == UInt8['a', '.', 'g', '.', '.', '.', 'g', '.', '.', '.', '.', 'a']
  @test nt.val == UInt8['c', 't', 'a', 'g', 'a', 'g', 'c', 'g', 'a', 'c', 'g', 'a', 'g', 't', 'a', 't', 'c', 'g']
  @test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  nt = Kpax3.NucleotideData(Kpax3.KSettings("data/read_proper_nt.fasta", f, l=1))
  @test nt.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 1 1 1;
                         1 1 1 0 0 0;
                         0 0 1 0 0 0;
                         1 0 0 1 0 1;
                         0 1 0 0 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 0 0 1;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         0 1 0 0 1 0;
                         1 0 1 1 0 1]
  @test nt.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test nt.ref == UInt8['a', '.', 'g', '.', '.', '.', 'g', '.', '.', '.', '.', 'a']
  @test nt.val == UInt8['c', 't', 'a', 'g', 'a', 'g', 'c', 'g', 'a', 'c', 'g', 'a', 'g', 't', 'a', 't', 'c', 'g']
  @test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  # consider all characters
  nt = Kpax3.NucleotideData(Kpax3.KSettings("data/read_proper_nt.fasta", f,
                                miss=zeros(UInt8, 1)))
  @test nt.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         0 0 1 0 0 1;
                         0 0 0 1 1 1;
                         1 1 1 0 0 0;
                         0 0 1 0 0 0;
                         1 0 0 1 0 1;
                         0 1 0 0 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 0 0 1;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         0 1 0 0 1 0;
                         1 0 1 1 0 1;
                         1 0 1 1 1 1;
                         0 1 0 0 0 0]
  @test nt.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test nt.ref == UInt8['a', '.', 'g', '.', '.', '.', 'g', '.', '.', '.', '.', '.']
  @test nt.val == UInt8['c', 't', 'a', 'g', 'a', 'g', 'x', 'c', 'g', 'a', 'c', 'g', 'a', 'g', 't', 'a', 't', 'c', 'g', 'a', 'x']
  @test nt.key == [1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8, 9, 9]

  nothing
end

test_data_proper_dna_file()

function test_data_proper_protein_file()
  f = "../build/test"

  aa = Kpax3.AminoAcidData(Kpax3.KSettings("data/read_proper_aa.fasta", f))
  @test aa.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 1;
                         0 0 1 0 0 0;
                         0 1 0 0 1 0;
                         1 0 0 1 0 1;
                         0 0 0 0 0 1;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         1 1 0 1 0 0;
                         0 0 1 0 1 1]
  @test aa.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test aa.ref == UInt8['m', '.', 'a', '.', '.', '.', 'v', '.', '.', '.', '.', 'f']
  @test aa.val == UInt8['e', 'k', 'i', 'k', 'l', 'v', 'l', 'v', 'c', 'l', 't', 'e', 'l', 'm', 'c', 'y', 'a', 't']
  @test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  aa = Kpax3.AminoAcidData(Kpax3.KSettings("data/read_proper_aa.fasta", f, l=1))
  @test aa.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 1;
                         0 0 1 0 0 0;
                         0 1 0 0 1 0;
                         1 0 0 1 0 1;
                         0 0 0 0 0 1;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         1 1 0 1 0 0;
                         0 0 1 0 1 1]
  @test aa.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test aa.ref == UInt8['m', '.', 'a', '.', '.', '.', 'v', '.', '.', '.', '.', 'f']
  @test aa.val == UInt8['e', 'k', 'i', 'k', 'l', 'v', 'l', 'v', 'c', 'l', 't', 'e', 'l', 'm', 'c', 'y', 'a', 't']
  @test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  # consider all characters
  aa = Kpax3.AminoAcidData(Kpax3.KSettings("data/read_proper_aa.fasta", f, miss=zeros(UInt8,1)))
  @test aa.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         0 0 1 0 0 1;
                         1 1 1 0 0 0;
                         0 0 0 1 1 1;
                         0 0 1 0 0 0;
                         0 1 0 0 1 0;
                         1 0 0 1 0 1;
                         0 0 0 0 0 1;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         1 1 0 1 0 0;
                         0 0 1 0 1 1;
                         1 0 1 1 1 1;
                         0 1 0 0 0 0]
  @test aa.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test aa.ref == UInt8['m', '.', 'a', '.', '.', '.', 'v', '.', '.', '.', '.', '.']
  @test aa.val == UInt8['e', 'k', 'i', 'k', 'l', 'v', 'x', 'l', 'v', 'c', 'l', 't', 'e', 'l', 'm', 'c', 'y', 'a', 't', 'f', 'x']
  @test aa.key == [1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8, 9, 9]

  nothing
end

test_data_proper_protein_file()

function test_data_input_output()
  f = "../build/test"

  nt = Kpax3.NucleotideData(Kpax3.KSettings("data/read_proper_nt.fasta", f))

  # TODO: Test exception when saving to a location without writing permissions
  Kpax3.save("../build/nt.jld", nt)
  @test isfile("../build/nt.jld")

  @test_throws SystemError Kpax3.loadnt("../build/non_existent.file")

  nt = Kpax3.loadnt("../build/nt.jld")

  @test isa(nt, Kpax3.NucleotideData)
  @test nt.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 1 1 1;
                         1 1 1 0 0 0;
                         0 0 1 0 0 0;
                         1 0 0 1 0 1;
                         0 1 0 0 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         0 0 0 0 0 1;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         0 1 0 0 1 0;
                         1 0 1 1 0 1]
  @test nt.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test nt.ref == UInt8['a', '.', 'g', '.', '.', '.', 'g', '.', '.', '.', '.', 'a']
  @test nt.val == UInt8['c', 't', 'a', 'g', 'a', 'g', 'c', 'g', 'a', 'c', 'g', 'a', 'g', 't', 'a', 't', 'c', 'g']
  @test nt.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  aa = Kpax3.AminoAcidData(Kpax3.KSettings("data/read_proper_aa.fasta", f))

  # TODO: Test exception when saving to a location without writing permissions
  Kpax3.save("../build/aa.jld", aa)
  @test isfile("../build/aa.jld")

  @test_throws SystemError Kpax3.loadaa("../build/non_existent.file")

  aa = Kpax3.loadaa("../build/aa.jld")
  @test isa(aa, Kpax3.AminoAcidData)
  @test aa.data == UInt8[0 0 0 0 0 1;
                         1 1 1 1 1 0;
                         0 0 1 0 1 1;
                         1 1 0 1 0 0;
                         1 1 0 0 0 0;
                         0 0 0 1 1 0;
                         1 1 1 0 0 0;
                         0 0 0 1 1 1;
                         0 0 1 0 0 0;
                         0 1 0 0 1 0;
                         1 0 0 1 0 1;
                         0 0 0 0 0 1;
                         1 1 1 0 0 0;
                         0 0 0 1 1 0;
                         1 1 0 0 1 1;
                         0 0 1 1 0 0;
                         1 1 0 1 0 0;
                         0 0 1 0 1 1]
  @test aa.id == String["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test aa.ref == UInt8['m', '.', 'a', '.', '.', '.', 'v', '.', '.', '.', '.', 'f']
  @test aa.val == UInt8['e', 'k', 'i', 'k', 'l', 'v', 'l', 'v', 'c', 'l', 't', 'e', 'l', 'm', 'c', 'y', 'a', 't']
  @test aa.key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  nothing
end

test_data_input_output()
