#**************************************************************************************
# test_Input_Console.jl
# ======================= part of the GeoEfficiency.jl package.
# 
# test all the input to the package from the console.
# 
#**************************************************************************************


@debug("GeoEfficiency.input")
@testset "GeoEfficiency.input" begin
	@test H.exec_console_unattended(G.input, []) == ""
    @test H.exec_console_unattended(G.input, "") == ""
    @test H.exec_console_unattended(G.input, [1]) == "1"
	@test H.exec_console_unattended(G.input, "1") == "1"
	@test H.exec_console_unattended(G.input,  "anbfyiQERFC") == "anbfyiQERFC"
	@test readavailable(stdin.buffer) |> String == ""   # test that no thing is left in the stdin
end #testset_input


@debug("GeoEfficiency.getfloat")
@testset "GeoEfficiency.getfloat" begin  
	
	@debug("getfloat - different ways to input numbers")
	@test   0.0     ==  G.getfloat("\njust press return: ",value="")
	@test   0.0     ==  G.getfloat("\ninput '0.0', then press return: ",value="0.0")
	@test   0.0     ==  G.getfloat("\ninput '0', then press return: ",value="0")
	@test   0.0     ==  G.getfloat("\ninput '+0', then press return: ",value="+0")
	@test   0.0     ==  G.getfloat("\ninput '-0', then press return: ",value="-0")
	@test   0.0     ==  G.getfloat("\ninput '1*0im', then press return: ",value="1*0im")
		
	@test   1.0     ==  G.getfloat("\njust press return: ",value="1.0")		
	@test   1.0     ==  G.getfloat("\ninput 1, then press return: ",value="+1.0")
	@test   -1.0    ==  G.getfloat("\ninput 1.0, then press return: ",value="-1.0")
	@test   1.0     ==  G.getfloat("\ninput '1*0im', then press return: ",value="1+1*0im")		
		
	@test   2000.0  ==  G.getfloat("\ninput '2e3', then press return: ",value="2e3")
	@test   2000.0  ==  G.getfloat("\ninput '2e3', then press return: ",value="2E3")
	@test   -2000.0 ==  G.getfloat("\ninput '-2e3', then press return: ",value="-2e3")
	@test   -2000.0 ==  G.getfloat("\ninput '-2e3', then press return: ",value="-2E3")
	@test   0.034   ==  G.getfloat("\ninput '3.4e-2', then press return: ",value="3.4e-2")
	@test   -0.034  ==  G.getfloat("\ninput '-3.4e-2', then press return: ",value="-3.4e-2")	

	
	@debug("getfloat - mathematical expressions")
	@test   0.5           		==  G.getfloat("\ninput 1/2, then press return: ",value="1/2")
	@test   0.75          		==  G.getfloat("\ninput 3//4, then press return: ",value="3//4")
	@test   MathConstants.pi/2 	≈   G.getfloat("\ninput 'pi/2', then press return: ",value="pi/2")
	@test   MathConstants.e     ≈   G.getfloat("\ninput 'e', then press return: ",value="e")
	@test   MathConstants.e^3   ≈   G.getfloat("\ninput 'e^3', then press return: ",value="e^3")
	@test   Base.sin(0.1) 		≈   G.getfloat("\ninput 'sin(0.1)', then press return: ",value="sin(0.1)")
	@test   Base.sin(0.1) + e^3 ≈   G.getfloat("\ninput 'sin(0.1)', then press return: ",value="sin(0.1)+e^3")


	@debug("getfloat - invalide console input")
	readavailable(stdin.buffer) == UInt8[] || @warn "buffer not empty, see the pervious process to `stdin`"  buffer = String(bffr) 
	write(stdin.buffer,"\n"); 				@test 0.0 == G.getfloat("\njust press return: ")	# valide input but for completness	
	write(stdin.buffer,"\n" * "3\n"); 		@test 3.0 == G.getfloat("\nthe first time just press return, then input `3` : ", 0.1, 4.0)
	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput 5, then press return: ", 0.0, 4.0)
	write(stdin.buffer,"-1\n" * "3\n"); 	@test 3.0 == G.getfloat("\ninput -1, then press return: ", 0.0, 4.0)
		
	write(stdin.buffer,"1.2f\n" * "3\n");	 @test 3.0 == G.getfloat("\nthe first time input '1.2f', then input `3` : ")
	write(stdin.buffer,"one\n" * "3\n");	 @test 3.0 == G.getfloat("\nthe first time input 'one', then input `3` : ") # trying to input any string, only valid number should accepted.	
	write(stdin.buffer,"3.4e-2.0\n" * "3\n");@test 3.0  == G.getfloat("\nthe first time input '3.4e-2.0', then input `3` : ")
		
	for i = 0:5
		write(stdin.buffer,"1.2+2im\n"^i * "3\n")
		@test G.getfloat("\nthe first time input '1.2+2im': ") == 3.0
	end # for


	@debug("getfloat - interval boundaries")
	# '1', '5' are to represent the lower, upper limits; while '3' represents an intermediate value.

	@test 1.0 == G.getfloat("\ninput '1', then press Return: ", 1.0, 5.0, value="1")					# by default lower limit is valide
	@test 1.0 == G.getfloat("\ninput '1', then press Return: ", 1.0, 5.0, value="1", lower=true)		# now explicit lower
	@test 1.0 == G.getfloat("\ninput '1', then press Return: ", 1.0, 5.0, value="1", lower=true, upper=false)	# now explicit lower - explicit upper
	@test 1.0 == G.getfloat("\ninput '1', then press Return: ", 1.0, 5.0, value="1", lower=true, upper=true)	# now explicit lower- modified upper

	write(stdin.buffer,"1\n" * "3\n"); 		@test 3.0 == G.getfloat("\ninput '1' & Return, then '3' & Return: ", 1.0, 5.0, lower=false)					# now lower limit `1` is not valide	
	write(stdin.buffer,"1\n" * "3\n"); 		@test 3.0 == G.getfloat("\ninput '1' & Return, then '3' & Return: ", 1.0, 5.0, lower=false, upper=false)	# now lower limit `1` is not valide - explicit upper
	write(stdin.buffer,"1\n" * "3\n"); 		@test 3.0 == G.getfloat("\ninput '1' & Return, then '3' & Return: ", 1.0, 5.0, lower=false, upper=true)	# now lower limit `1` is not valide - modified upper


	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5' & Return, then '3' & Return:", 1.0, 5.0)		# by default upper limit is not valide
	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5' & Return, then '3' & Return:", 1.0, 5.0, lower=true)		# by default upper limit is not valide - explicit lower
	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5' & Return, then '3' & Return:", 1.0, 5.0, lower=false)		# by default upper limit is not valide - modified lower
	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5' & Return, then '3' & Return:", 1.0, 5.0, 			  upper=false)		# explicit upper limit is not valide
	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5' & Return, then '3' & Return:", 1.0, 5.0, lower=true, upper=false,)		# explicit upper limit is not valide - explicit lower
	write(stdin.buffer,"5\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5' & Return, then '3' & Return:", 1.0, 5.0, lower=false, upper=false, )	# explicit upper limit is not valide - modified lower

	@test 5.0 == G.getfloat("\ninput 5, then press Return: ", 1.0, 5.0, value="5", upper=true)		# now upper limit `5` is valide	
	@test 5.0 == G.getfloat("\ninput 5, then press Return: ", 1.0, 5.0, value="5", upper=true, lower=true)		# now input `5` is valide	 - explicit lower
	@test 5.0 == G.getfloat("\ninput 5, then press Return: ", 1.0, 5.0, value="5", upper=true, lower=false)		# now input `5` is valide	 - modified lower
	

	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3")		# by default intermediate value accepted
	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3", lower=true)
	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3", lower=true, upper=false)
	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3", lower=true, upper=true)

	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3", lower=false)
	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3", lower=false, upper=false)
	@test 3.0 == G.getfloat("\ninput '3', then press Return: ", 1.0, 5.0, value="3", lower=false, upper=true)
	

	write(stdin.buffer,"5\n" * "1\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5', then '1', then '3': ", 3.0, 3.0)								# when only one value (ex. 3.0) accepted
	write(stdin.buffer,"5\n" * "1\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5', then '1', then '3': ", 3.0, 3.0, 			 upper =true)	# when only one value (ex. 3.0) accepted
	write(stdin.buffer,"5\n" * "1\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5', then '1', then '3': ", 3.0, 3.0, lower =true, upper =true)	# when only one value (ex. 3.0) accepted
	write(stdin.buffer,"5\n" * "1\n" * "3\n");  	@test 3.0 == G.getfloat("\ninput '5', then '1', then '3': ", 3.0, 3.0, lower =false, upper =true)	# when only one value (ex. 3.0) accepted
	
	@test_throws 	ArgumentError	3.0 == G.getfloat("\ninput '3', then press Return: ", 3.0, 3.0, lower =false, upper =false, value="3")
	@test_throws 	ArgumentError	3.0 == G.getfloat("\ninput '3', then press Return: ", 5.0, 1.0, value="3")
	@test_throws 	ArgumentError	3.0 == G.getfloat("\ninput '3', then press Return: ", 5.0, 1.0, lower =true, value="3")
	@test_throws 	ArgumentError	3.0 == G.getfloat("\ninput '3', then press Return: ", 5.0, 1.0, lower =true, upper =false, value="3")
	@test_throws 	ArgumentError	3.0 == G.getfloat("\ninput '3', then press Return: ", 5.0, 1.0, lower =false, upper =false, value="3")
	@test_throws 	ArgumentError	3.0 == G.getfloat("\ninput '3', then press Return: ", 5.0, 1.0, lower =false, upper =true, value="3")
end #testset_getfloat