@testset "@console" begin
    @test 6 == H.@console +(1, 2, 3)
        @test readavailable(stdin.buffer) |> String == "\n"
#
#
    @test ""    == H.@console readline()
    @test "1"   == H.@console readline() 1
    @test "1.1"   == H.@console readline() 1.1 20 30.1
        @test [readline(), readline()] == ["20", "30.1"]
        @test readavailable(stdin.buffer) |> String == ""   # test that no thing is left in the stdin
    @test ""    == H.@console readline() ""
    @test "1.2"   == H.@console readline() "1.2"
    @test "1.3"   == H.@console readline() "1.3" "2.1" "3.1"
        @test [readline(), readline()] == ["2.1", "3.1"]
        @test readavailable(stdin.buffer) |> String == ""   # test that no thing is left in the stdin
#
#
    @test b"\n"    == H.@console readavailable(stdin)
    @test b"\n"    == H.@console readavailable(stdin) ""
    @test b"1.5\n2.2\n3.2\n"    == H.@console readavailable(stdin) 1.5 2.2 3.2
    @test b"1.6\n2.4\n3.4\n"    == H.@console readavailable(stdin) "1.6\n2.4\n3.4"
    @test b"1.7\n2.7\n3.7\n"    == H.@console readavailable(stdin) "1.7\n2.7\n3.7\n"
    
    @test b"1.8\n2.8\n3.8\n"    == H.@console readavailable(stdin) "1.8 2.8 3.8"
    @test b"1.9\n2.9\n3.9\n"    == H.@console readavailable(stdin) "1.9 2.9 3.9\n"
    @test b"11\n12\n13\nQ\n" == H.@console readavailable(stdin) "11 12 13 Q"
        @test readavailable(stdin.buffer) |> String == ""   # test that no thing is left in the stdin
end #testset_@console

@testset "exec_console_unattended" begin
    @test H.exec_console_unattended(+, [] ;Fn_ARGs=[1, 2, 3]) == 6
        @test readavailable(stdin.buffer) |> String == "\n"
    @test H.exec_console_unattended(+ ;Fn_ARGs=[4, 5, 6]) == 15
        @test readavailable(stdin.buffer) |> String == "\n"
    @test H.exec_console_unattended(+, "";Fn_ARGs=[1, 2, 3]) == 6
        @test readavailable(stdin.buffer) |> String == "\n"

    @test H.exec_console_unattended(readline, []) == ""
    @test H.exec_console_unattended(readline, "") == ""
    @test H.exec_console_unattended(readline, [10]) == "10"
    @test H.exec_console_unattended(readline, [1, 2, 3]) == "1"
        @test [readline(), readline()] == ["2", "3"]
    @test H.exec_console_unattended(readline, "4") == "4"
    @test H.exec_console_unattended(readline, "50 60 70") == "50"
        @test [readline(), readline()] == ["60", "70"]
    @test H.exec_console_unattended(readline, 80.1) == "80.1"
    @test H.exec_console_unattended(readline, 1, 2, 3) == "1"
        @test [readline(), readline()] == ["2", "3"]

    @test H.exec_console_unattended(sin, "10 20 30 40" ;Fn_ARGs=[pi]) == sin(pi)
        @test [readline(), readline(), readline(), readline()] == ["10", "20", "30", "40"]
    @test H.exec_console_unattended(sin, ["1", "2", "3", "4"] ;Fn_ARGs=[pi]) == sin(pi)
        @test [readline(), readline(), readline(), readline()] == ["1", "2", "3", "4"]
    @test H.exec_console_unattended(sin, [10, 20, 30, 40] ;Fn_ARGs=[pi]) == sin(pi)
        @test [readline(), readline(), readline(), readline()] == ["10", "20", "30", "40"]
    @test H.exec_console_unattended(sin, 1, 2, 3, 4 ;Fn_ARGs=[pi]) == sin(pi)
        @test [readline(), readline(), readline(), readline()] == ["1", "2", "3", "4"]
    @test readavailable(stdin.buffer) |> String == ""   # test that no thing is left in the stdin

    @test H.exec_console_unattended(readavailable, []    ;Fn_ARGs=[stdin])   == b"\n"
    @test H.exec_console_unattended(readavailable, ""    ;Fn_ARGs=[stdin])   == b"\n"
    @test H.exec_console_unattended(readavailable        ;Fn_ARGs=[stdin])   == b"\n"
    @test H.exec_console_unattended(readavailable, [1, 2, 3];    Fn_ARGs=[stdin])    == b"1\n2\n3\n"
    @test H.exec_console_unattended(readavailable, "10\n20\n30";    Fn_ARGs=[stdin]) == b"10\n20\n30\n"
    @test H.exec_console_unattended(readavailable, "1\n2\n3\n";  Fn_ARGs=[stdin])    == b"1\n2\n3\n"
    @test H.exec_console_unattended(readavailable, "10 20 30";      Fn_ARGs=[stdin]) == b"10\n20\n30\n"
    @test H.exec_console_unattended(readavailable, "1 2 3\n";    Fn_ARGs=[stdin])    == b"1\n2\n3\n"
    @test H.exec_console_unattended(readavailable, "10 20 30 Q";    Fn_ARGs=[stdin]) == b"10\n20\n30\nQ\n"

    @test H.exec_console_unattended(readavailable, "1.0 2.0 " * "3.0 Q";    Fn_ARGs=[stdin]) == b"1.0\n2.0\n3.0\nQ\n"
    @test H.exec_console_unattended(readavailable, "1.1 2.1 " * " 3.1 Q";    Fn_ARGs=[stdin]) == b"1.1\n2.1\n3.1\nQ\n"
    
    @test H.exec_console_unattended(readavailable, 1, 2, 3;     Fn_ARGs=[stdin])     == b"1\n2\n3\n"

    @test readavailable(stdin.buffer) |> String == ""   # test that no thing is left in the stdin
end #testset_exec_console_unattended
