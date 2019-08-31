import DocumentFunction

expected = "**DocumentFunction.documentfunction**\n\nCreate function documentation\n\nMethods:\n - `DocumentFunction.documentfunction(f::Function; location, maintext, argtext, keytext) in DocumentFunction`\nArguments:\n - `f::Function` : Function to be documented\nKeywords:\n - `argtext` : Dictionary with text for each argument\n - `keytext` : Dictionary with text for each keyword\n - `location` : Boolean to show/hide function location on the disk\n - `maintext` : General function description\n"

import Test

output = DocumentFunction.documentfunction(DocumentFunction.documentfunction;
	location=false,
	maintext="Create function documentation",
	argtext=Dict("f"=>"Function to be documented"),
	keytext=Dict("maintext"=>"General function description",
				 "argtext"=>"Dictionary with text for each argument",
				 "keytext"=>"Dictionary with text for each keyword",
				 "location"=>"Boolean to show/hide function location on the disk"))

DocumentFunction.documentfunction(DocumentFunction.documentfunction; location=true)
noargfunction() = nothing
@Test.testset "Document" begin
    @Test.test output == expected
    @Test.test [] == DocumentFunction.getfunctionkeywords(DocumentFunction.getfunctionmethods)
    @Test.test [] == DocumentFunction.getfunctionarguments(noargfunction)
end

:passed
