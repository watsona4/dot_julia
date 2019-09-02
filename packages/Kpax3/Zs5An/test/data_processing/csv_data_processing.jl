# This file is part of Kpax3. License is MIT.

function test_csv_data_processing_exceptions()
  @test_throws Kpax3.KCSVError Kpax3.readdata("data/read_empty_file.csv", ',', ["X"], false, 0)
  @test_throws Kpax3.KCSVError Kpax3.readdata("data/read_no_id_char.csv", ',', ["X"], false, 0)
  @test_throws Kpax3.KCSVError Kpax3.readdata("data/read_no_1st_seq.csv", ',', ["X"], false, 0)
  @test_throws Kpax3.KCSVError Kpax3.readdata("data/read_no_nth_seq.csv", ',', ["X"], false, 0)

  nothing
end

test_csv_data_processing_exceptions()

function test_csv_data_processing_read_blanks()
  (data, id, ref) = Kpax3.readdata("data/read_blanks.csv", ',', ["X"], false, 0)
  @test data == ["G" "A";
                 "A" "G";
                 "G" "C";
                 "C" "G";
                 "A" "G";
                 "G" "C"]
  @test id == ["ID1", "ID5"]
  @test ref == ["A", "T", "G", ".", ".", ".", "G", ".", ".", "A", ".", "A"]

  (bindata, val, key) = Kpax3.categorical2binary(data, "")
  @test bindata == UInt8[0 1;
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
  @test val == ["A", "G", "A", "G", "C", "G", "C", "G", "A", "G", "C", "G"]
  @test key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]

  nothing
end

test_csv_data_processing_read_blanks()

function test_csv_data_processing_proper_dna_file()
  (data, id, ref) = Kpax3.readdata("data/read_proper_nt.csv", ',', ["X"], false, 0)

  @test data == ["T" "T" "T" "T" "T" "C";
                 "G" "G" "A" "G" "A" "A";
                 "A" "A" ""  "G" "G" "" ;
                 "G" "G" "G" "C" "C" "C";
                 "C" "G" "A" "C" "G" "C";
                 "A" "A" "A" "G" "G" "U";
                 "A" "A" "U" "T" "A" "A";
                 "G" "C" "G" "G" "C" "G"]
  @test id == ["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test ref == ["A", ".", "G", ".", ".", ".", "G", ".", ".", ".", ".", "A"]

  (bindata, val, key) = Kpax3.categorical2binary(data, "")
  @test bindata == UInt8[0 0 0 0 0 1;
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
                         0 0 0 1 0 0;
                         0 0 1 0 0 0;
                         0 1 0 0 1 0;
                         1 0 1 1 0 1]
  @test val == ["C", "T", "A", "G", "A", "G", "C", "G", "A", "C", "G", "A", "G", "U", "A", "T", "U", "C", "G"]
  @test key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8]

  # consider all characters
  (data, id, ref) = Kpax3.readdata("data/read_proper_nt.csv", ',', [""], false, 0)
  @test data == ["T" "T" "T" "T" "T" "C";
                 "G" "G" "A" "G" "A" "A";
                 "A" "A" "X" "G" "G" "X";
                 "G" "G" "G" "C" "C" "C";
                 "C" "G" "A" "C" "G" "C";
                 "A" "A" "A" "G" "G" "U";
                 "A" "A" "U" "T" "A" "A";
                 "G" "C" "G" "G" "C" "G";
                 "A" "X" "A" "A" "A" "A"]
  @test id == ["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test ref == ["A", ".", "G", ".", ".", ".", "G", ".", ".", ".", ".", "."]

  (bindata, val, key) = Kpax3.categorical2binary(data, "")
  @test bindata == UInt8[0 0 0 0 0 1;
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
                         0 0 0 1 0 0;
                         0 0 1 0 0 0;
                         0 1 0 0 1 0;
                         1 0 1 1 0 1;
                         1 0 1 1 1 1;
                         0 1 0 0 0 0]
  @test val == ["C", "T", "A", "G", "A", "G", "X", "C", "G", "A", "C", "G", "A", "G", "U", "A", "T", "U", "C", "G", "A", "X"]
  @test key == [1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9, 9]

  nothing
end

test_csv_data_processing_proper_dna_file()

function test_csv_data_processing_proper_protein_file()
  (data, id, ref) = Kpax3.readdata("data/read_proper_aa.csv", ',', ["X"], false, 0)

  @test data == ["K" "K" "K" "K" "K" "E";
                 "K" "K" "I" "K" "I" "I";
                 "L" "L" ""  "V" "V" "" ;
                 "L" "L" "L" "V" "V" "V";
                 "T" "L" "C" "T" "L" "T";
                 "L" "L" "L" "M" "M" "E";
                 "C" "C" "Y" "Y" "C" "C";
                 "A" "A" "T" "A" "T" "T"]
  @test id == ["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test ref == ["M", ".", "A", ".", ".", ".", "V", ".", ".", ".", ".", "F"]

  (bindata, val, key) = Kpax3.categorical2binary(data, "")
  @test bindata == UInt8[0 0 0 0 0 1;
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
  @test val == ["E", "K", "I", "K", "L", "V", "L", "V", "C", "L", "T", "E", "L", "M", "C", "Y", "A", "T"]
  @test key == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8]

  # consider all characters
  (data, id, ref) = Kpax3.readdata("data/read_proper_aa.csv", ',', [""], false, 0)
  @test data == ["K" "K" "K" "K" "K" "E";
                 "K" "K" "I" "K" "I" "I";
                 "L" "L" "X" "V" "V" "X";
                 "L" "L" "L" "V" "V" "V";
                 "T" "L" "C" "T" "L" "T";
                 "L" "L" "L" "M" "M" "E";
                 "C" "C" "Y" "Y" "C" "C";
                 "A" "A" "T" "A" "T" "T";
                 "F" "X" "F" "F" "F" "F"]
  @test id == ["ID1", "ID2", "ID3", "ID4", "ID5", "ID6"]
  @test ref == ["M", ".", "A", ".", ".", ".", "V", ".", ".", ".", ".", "."]

  (bindata, val, key) = Kpax3.categorical2binary(data, "")
  @test bindata == UInt8[0 0 0 0 0 1;
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
  @test val == ["E", "K", "I", "K", "L", "V", "X", "L", "V", "C", "L", "T", "E", "L", "M", "C", "Y", "A", "T", "F", "X"]
  @test key == [1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8, 9, 9]

  nothing
end

test_csv_data_processing_proper_protein_file()
