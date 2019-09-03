# Recipe implementation of Simon Byrne editable table
editablefield(f; kwargs...) = editablefield(widget(f)::AbstractWidget; kwargs...)

function editablefield(w::AbstractWidget; editing = false, format = InteractBase.format)
    editing isa AbstractObservable || (editing = Observable(editing))
    data = [:widget => w, :editing => editing]
    wdg = Widget{:editablefield}(data; output = w)
    @layout! wdg Observables.@map &(:editing) ? :widget : map(format, :widget)
end

function editbutton(save = () -> nothing; editing = false)
    editing isa AbstractObservable || (editing = Observable(editing))
    data = [:edit => button("Edit"), :save => button("Save"), :editing => editing]
    changestate() = (editing[] = !editing[])
    wdg = Widget{:editbutton}(data)
    Observables.on(t -> changestate(), wdg[:edit])
    Observables.on(t -> (save(); changestate()), wdg[:save])
    @layout! wdg Observables.@map &(:editing) ? :save : :edit
end
