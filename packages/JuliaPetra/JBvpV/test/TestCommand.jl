function testJuliaPetra(flags...; coverage=false)
#    function test!(pkg::AbstractString,
#               errs::Vector{AbstractString},
#               nopkgs::Vector{AbstractString},
#               notests::Vector{AbstractString}; coverage::Bool=false)

    formattedFlags = ["--$flag" for flag in flags]
    combinedFlags = join(formattedFlags, "\n")

    test_path = abspath(Pkg.dir(), "JuliaPetra", "test", "runtests.jl")
    info("Testing JuliaPetra")
    Base.cd(dirname(test_path)) do
        try
            cmd = ```
            $(Base.julia_cmd())
            --code-coverage=$(coverage ? "user" : "none")
            --color=$(Base.have_color ? "yes" : "no")
            --compilecache=$(Bool(Base.JLOptions().use_compilecache) ? "yes" : "no")
            --check-bounds=yes
            --startup-file=$(Base.JLOptions().startupfile != 2 ? "yes" : "no")
            $test_path
            $formattedFlags
            ```
            run(cmd)
            info("JuliaPetra tests passed")
        catch err
             Base.Pkg.Entry.warnbanner(err, label="[ ERROR: JuliaPetra ]")
        end
    end
end
