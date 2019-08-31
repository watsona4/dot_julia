using Knockout, WebIO, Blink
using Test

using WebIO: node

cleanup = !AtomShell.isinstalled()
cleanup && AtomShell.install()

# write your own tests here
s = Observable(["a", "b", "c"])
t = node(:select, attributes = Dict("data-bind" => "options : options", "id" => "myselect"));
n = (knockout(t, ["options" => s]));

w = Window(Blink.@d(:show => false)); sleep(10.0)

body!(w, n); sleep(5.0)

@test Blink.@js(w, document.querySelector("#myselect").children.length) == 3
@test Blink.@js(w, document.querySelector("#myselect").children[0].value) == "a"
@test Blink.@js(w, document.querySelector("#myselect").children[1].value) == "b"
@test Blink.@js(w, document.querySelector("#myselect").children[2].value) == "c"

s[] = ["c", "d"]
sleep(1.0)

@test Blink.@js(w, document.querySelector("#myselect").children.length) == 2
@test Blink.@js(w, document.querySelector("#myselect").children[0].value) == "c"
@test Blink.@js(w, document.querySelector("#myselect").children[1].value) == "d"

cleanup && AtomShell.uninstall()
