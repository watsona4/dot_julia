using Test
using Tachyons
using WebIO
using Blink
using Observables

notinstalled = !AtomShell.isinstalled()

notinstalled && AtomShell.install()

@testset "Blink mocks" begin
    w = Window(Dict(:show => false))

    elem = dom"div#test1"("hello, world") |> class"bg-yellow green" |> class"pa5"
    body!(w, dom"div"(tachyons_css, elem))
    sleep(5) # wait for it to render.

    substrings = ["""<div id="test1" class="bg-yellow green pa5">hello, world</div>"""]
    content = Blink.@js(w, document.body.innerHTML)
    @test all(x->occursin(x, content), substrings)
    br = Blink.@js(w, window.getComputedStyle(document.querySelector("#test1"), null).getPropertyValue("background-color"))
    @test br == "rgb(255, 215, 0)"
end

notinstalled && AtomShell.uninstall()
