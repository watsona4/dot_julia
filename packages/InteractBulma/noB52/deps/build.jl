const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_assets = joinpath(_pkg_root, "assets")

!isdir(_pkg_assets) && mkdir(_pkg_assets)

deps = [
    "bulma.sass",
    "sass/base/_all.sass",
    "sass/base/generic.sass",
    "sass/base/helpers.sass",
    "sass/base/minireset.sass",
    "sass/components/_all.sass",
    "sass/components/breadcrumb.sass",
    "sass/components/card.sass",
    "sass/components/dropdown.sass",
    "sass/components/level.sass",
    "sass/components/list.sass",
    "sass/components/media.sass",
    "sass/components/menu.sass",
    "sass/components/message.sass",
    "sass/components/modal.sass",
    "sass/components/navbar.sass",
    "sass/components/pagination.sass",
    "sass/components/panel.sass",
    "sass/components/tabs.sass",
    "sass/elements/_all.sass",
    "sass/elements/box.sass",
    "sass/elements/button.sass",
    "sass/elements/container.sass",
    "sass/elements/content.sass",
    "sass/elements/form.sass",
    "sass/elements/icon.sass",
    "sass/elements/image.sass",
    "sass/elements/notification.sass",
    "sass/elements/other.sass",
    "sass/elements/progress.sass",
    "sass/elements/table.sass",
    "sass/elements/tag.sass",
    "sass/elements/title.sass",
    "sass/grid/_all.sass",
    "sass/grid/columns.sass",
    "sass/grid/tiles.sass",
    "sass/layout/_all.sass",
    "sass/layout/footer.sass",
    "sass/layout/hero.sass",
    "sass/layout/section.sass",
    "sass/utilities/_all.sass",
    "sass/utilities/animations.sass",
    "sass/utilities/controls.sass",
    "sass/utilities/derived-variables.sass",
    "sass/utilities/functions.sass",
    "sass/utilities/initial-variables.sass",
    "sass/utilities/mixins.sass",
]

for dep in deps
    path = joinpath(_pkg_assets, split(dep, '/')...)
    mkpath(splitdir(path)[1])
    download("https://cdn.jsdelivr.net/npm/bulma@0.7.4/"*dep, path)
end

extensions = [
    "https://cdn.jsdelivr.net/npm/bulma-extensions@1.0.14/bulma-slider/dist/bulma-slider.sass",
    "https://cdn.jsdelivr.net/npm/bulma-extensions@1.0.14/bulma-switch/dist/bulma-switch.sass",
    "https://cdn.jsdelivr.net/npm/bulma-extensions@1.0.14/bulma-checkradio/dist/bulma-checkradio.sass",
    "https://cdn.jsdelivr.net/npm/bulma-extensions@1.0.14/bulma-accordion/dist/bulma-accordion.sass",
    "https://cdn.jsdelivr.net/npm/bulma-extensions@1.0.14/bulma-tooltip/dist/bulma-tooltip.sass",
]
for extension in extensions
    download(extension, joinpath(_pkg_assets, splitdir(extension)[2]))
end
