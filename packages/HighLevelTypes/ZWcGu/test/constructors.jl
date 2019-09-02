DeveloperBuilder(name::String) = (name, 700)
SpecializedDeveloperBuilder(name::String, language::String) = 
        tuplejoin(DeveloperBuilder(name), language)
        
@testset "Constructors" begin    
    junior = Developer("Junior") 
    
    @test junior.name == "Junior"    
    @test junior.salary == 700   
    
    artur = SpecializedDeveloper("Artur", "Julia")
    
    @test artur.name == "Artur"    
    @test artur.salary == 700
    @test artur.language == "Julia"        
end

