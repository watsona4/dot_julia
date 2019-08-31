@testset "MurmurHash3" begin
      tests = [
      Dict{String,Any}("x86_32"=>"00000000","text"=>""),
      Dict{String,Any}("x86_32"=>"087fcd5c","seed"=>42,"text"=>""),
      Dict{String,Any}("x86_32"=>"1cb30d2d","text"=>"!eDoZj \$XVe>vtaxn<x^ qU]m([aWSI^Hy>@E#hX}v mbkz#gB"),
      Dict{String,Any}("x86_32"=>"e6aa80e1","seed"=>10,"text"=>"o.SH}f]tVS\$deSKiOgE?#V %EP&]V!oyjlq}{BO)\$cz&fRGPrGUtz@b]{C"),
      Dict{String,Any}("x86_32"=>"100949f7","text"=>"[)<{vbjRgcp"),
      Dict{String,Any}("x86_32"=>"79b365c1","text"=>"R"),
      Dict{String,Any}("x86_32"=>"e70207f0","seed"=>5489776,"text"=>"mB"),
      Dict{String,Any}("x86_32"=>"c4b773e5","seed"=>111117,"text"=>"mExonGybCN{n# iVmrVI!?ahk]q&}BbHyx"),
      Dict{String,Any}("x86_32"=>"92bbd066","text"=>"TqDa}YvgP!K&P\$vsbeGt<Q{zVuBHQ>h}tBxvVlYVO\$LAgxNIik{)WeJtX]i?yom!.KoNB*sOUJv/.pF,lncuM@EXBTgw%VuY>\$!l!TFGe?HEO>NFiK,RSS%o#)lhy&Mw{QFGN![qKcM!eSXxfQ&eYeTtq[m<h#rvwuaNFTv e@kXzD##[%.JDYlKhQzrGV{/bB)^dCT&GDum#V{cVgAn)xjahnT[E\$<)yyElAhV/imQ!P%JL\$&tB%oaj*L\$<qzsD\$*oKT^/ykA([\$(sI}G{blBT>SSo UnOlclQkAJ(@FLXP&w/EKY?Kn}ndbY\$!#IC%IlcWF]^UX*iVejGrzX%ox@b{ &KUm>q>dP,k\$(&mmE,f.Kp/R[.FnjDPJ?FhniNuAi<o%*m./BjypWIaao*&@<kGICn!qP(uTjavSxzKfaT(H]!NmRWgejf?#q%l&ulr oxLv])NsNM>Q#bEAXy[lZXod?Yeu][SYaO DZ^doDLmgrCuBBWy"),
      Dict{String,Any}("x86_32"=>"8ba3f73c","text"=>"#Xu"),
      Dict{String,Any}("x86_32"=>"fb73894d","seed"=>1,"text"=>"MMBh*"),
      Dict{String,Any}("x86_32"=>"c83626b3","text"=>"QDJ{gyEAJMbhd\$,iRU(!uv>zCpzIDjcel F#/?/Tux?nX{^n*?a"),
      Dict{String,Any}("x86_32"=>"91032392","text"=>"GeBcX^k?C,]d*nx##RL*#*lZ{ &b{.I?Z]#qMyMiMT"),
      Dict{String,Any}("x86_32"=>"1b9cb3e5","seed"=>160753,"text"=>"KA.f#)K?#%by#G(w?ag^at{jbW)Q(QJtvX\$Gs{@UMWhhzYdX# A{uPrvm#"),
      Dict{String,Any}("x86_32"=>"54c379d4","seed"=>2,"text"=>"%w.I#vFp"),
      Dict{String,Any}("x86_32"=>"950a02a4","seed"=>0,"text"=>"th!S?L*A[VUtZZ)[%Zw/&!ZO!MsJDcFjV/uGb^yuZLZ\$)mlf}#N\$<b,!k t@R"),
      Dict{String,Any}("x86_32"=>"c7d8827f","seed"=>999983,"text"=>"IqP ]t (OrK"),
      Dict{String,Any}("x86_32"=>"704a49be","text"=>"PKqG47bFcNTKKTE"),
      Dict{String,Any}("x86_32"=>"52042560","text"=>"Qs7i2oN0kr10dOf")]
      for test in tests
            if "seed" in keys(test)
                  x86_32 = lpad(string(Bitcoin.Murmur3.hash32(test["text"], test["seed"]), base=16), 8, "0")
            else
                  x86_32 = lpad(string(Bitcoin.Murmur3.hash32(test["text"]), base=16), 8, "0")
            end
            @test test["x86_32"] == x86_32
      end
end
