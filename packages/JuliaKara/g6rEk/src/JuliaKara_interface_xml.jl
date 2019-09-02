using LightXML

" Name mappings from JuliaKara.jl to classic Kara"
const XML_NAMES = Dict(
    :world=> "XmlWorld",
    :tree => "XmlWallPoints",
    :mushroom => "XmlObstaclePoints",
    :leaf => "XmlPaintedfieldPoints",
    :kara => "XmlKaraList"
)

"Directions mappings from classic JuliaKara to Kara.jl"
const XML_DIR = Dict(
    0 => 1,
    1 => 4,
    2 => 3,
    3 => 2,
)

function xml_map_direction(xml_index::Int)
    JuliaKara_noGUI.ActorsWorld.DIRECTIONS[XML_DIR[xml_index]]
end

function kara_map_direction(direction::Symbol)
    for (k,d) in enumerate(JuliaKara_noGUI.ActorsWorld.DIRECTIONS)
        if d == direction
            for p in XML_DIR
                if p.second == k
                    return p.first
                end
            end
        end
    end
end

function xml_map_y(wo::World,y::Int)
    # Original Kara starts counting at 0 in the left upper corner
    wo.size.height - y
end

function xml_map_x(wo::World,x::Int)
    x + 1
end

function kara_map_y(wo::World,y::Int)
    wo.size.height - y
end

function kara_map_x(wo::World,x::Int)
    x - 1
end

function xml_parse_tree!(wo::World,element::XMLElement)
    place_tree(
        wo,
        xml_map_x(wo,parse(Int,attribute(element,"x"))),
        xml_map_y(wo,parse(Int,attribute(element,"y")))
    )
end

function xml_parse_mushroom!(wo::World,element::XMLElement)
    place_mushroom(
        wo,
        xml_map_x(wo,parse(Int,attribute(element,"x"))),
        xml_map_y(wo,parse(Int,attribute(element,"y")))
    )
end

function xml_parse_leaf!(wo::World,element::XMLElement)
    place_leaf(
        wo,
        xml_map_x(wo,parse(Int,attribute(element,"x"))),
        xml_map_y(wo,parse(Int,attribute(element,"y")))
    )
end

function xml_parse_kara!(wo::World,element::XMLElement)
    place_kara(
        wo,
        xml_map_x(wo,parse(Int,attribute(element,"x"))),
        xml_map_y(wo,parse(Int,attribute(element,"y"))),
        parse(Int,attribute(element,"direction")) |> xml_map_direction
    )
end

function xml_generate_world(element::XMLElement)
    World(
        parse(Int,attribute(element,"sizex")),
        parse(Int,attribute(element,"sizey"))
    )
end

function xml_parse_actor!(wo::World,elements::Vector{XMLElement},
                          element_name::String,parser::Function)
    for el in elements
        for p in get_elements_by_tagname(el,element_name)
            parser(wo,p)
        end
    end
end

function xml_load_world(path::AbstractString)
    xworld = parse_file(path)
    xworld_def = root(xworld)

    world = xml_generate_world(xworld_def)

    xtree = get_elements_by_tagname(xworld_def,XML_NAMES[:tree])
    xmushroom = get_elements_by_tagname(xworld_def,XML_NAMES[:mushroom])
    xleaf = get_elements_by_tagname(xworld_def,XML_NAMES[:leaf])
    xkara = get_elements_by_tagname(xworld_def,XML_NAMES[:kara])

    xml_parse_actor!(
        world,
        xtree,
        "XmlPoint",
        xml_parse_tree!
    )

    xml_parse_actor!(
        world,
        xmushroom,
        "XmlPoint",
        xml_parse_mushroom!
    )

    xml_parse_actor!(
        world,
        xleaf,
        "XmlPoint",
        xml_parse_leaf!
    )

    xml_parse_actor!(
        world,
        xkara,
        "XmlKara",
        xml_parse_kara!
    )

    return world
end

function xml_create_world(wo::World,xdoc::XMLDocument)
    xworld_def = create_root(xdoc,XML_NAMES[:world])
    set_attribute(xworld_def,"sizex",wo.size.width)
    set_attribute(xworld_def,"sizey",wo.size.height)
    set_attribute(xworld_def,"version","KaraX 1.0 javakara")
    return xworld_def
end

function xml_save_world(wo::World,path::AbstractString)
    xdoc = XMLDocument()
    # create root element
    xworld_def  = xml_create_world(wo,xdoc)
    # create child groups
    xtree = new_child(xworld_def,XML_NAMES[:tree])
    xmushroom = new_child(xworld_def,XML_NAMES[:mushroom])
    xleaf = new_child(xworld_def,XML_NAMES[:leaf])
    xkara = new_child(xworld_def,XML_NAMES[:kara])
    # iterate over actors
    for ac in wo.actors
        if ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
            t = new_child(xkara,"XmlKara")
            set_attributes(t,Dict(
                "direction" => kara_map_direction(ac.orientation.value),
                "name" => "Kara",
                "x" => kara_map_x(wo,ac.location.x) |> string,
                "y" => kara_map_y(wo,ac.location.y) |> string
            ))
        elseif ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:mushroom]
            t = new_child(xmushroom,"XmlPoint")
            set_attributes(t,Dict(
                "x" => kara_map_x(wo,ac.location.x) |> string,
                "y" => kara_map_y(wo,ac.location.y) |> string
            ))
        elseif ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:tree]
            t = new_child(xtree,"XmlPoint")
            set_attributes(t,Dict(
                "x" => kara_map_x(wo,ac.location.x) |> string,
                "y" => kara_map_y(wo,ac.location.y) |> string
            ))
        elseif ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:leaf]
            t = new_child(xleaf,"XmlPoint")
            set_attributes(t,Dict(
                "type" => "0",
                "x" =>kara_map_x(wo,ac.location.x) |> string,
                "y" =>kara_map_y(wo,ac.location.y) |> string,
            ))
        else
            error("Missing actor definition, cant create XML Element")
        end
    end
    save_file(xdoc,path)
end
