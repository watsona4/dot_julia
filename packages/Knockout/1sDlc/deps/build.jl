const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_deps = joinpath(_pkg_root,"deps")
const _pkg_assets = joinpath(_pkg_root,"assets")

!isdir(_pkg_assets) && mkdir(_pkg_assets)

download("http://knockoutjs.com/downloads/knockout-3.4.2.js", joinpath(_pkg_assets, "knockout.js"))
download("http://mbest.github.io/knockout.punches/knockout.punches.min.js", joinpath(_pkg_assets, "knockout_punches.js"))
