using TableShowUtils
using Test

@testset "TableShowUtils" begin

source = [(a=1,b="A"),(a=2,b="B")]

@test sprint(TableShowUtils.printtable, source, "foo file") == """
2x2 foo file
a │ b
──┼──
1 │ A
2 │ B"""

@test sprint(TableShowUtils.printHTMLtable, source) == """
<table><thead><tr><th>a</th><th>b</th></tr></thead><tbody><tr><td>1</td><td>&quot;A&quot;</td></tr><tr><td>2</td><td>&quot;B&quot;</td></tr></tbody></table>"""

end
