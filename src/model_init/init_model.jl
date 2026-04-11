struct ECSModel{CS <: Tuple, CT <: Tuple, ST <: Tuple, N, M}
    world::Ark.World{CS, CT, ST, N, M}
end

function ECSModel(properties::Properties)
    world = Ark.World(Components.COMPONENTS...)

    setup_firms!(world, properties)
    setup_workers!(world, properties)
    setup_bank!(world, properties)
    setup_central_bank!(world, properties)
    setup_government!(world, properties)
    setup_rotw!(world, properties)
    setup_agg!(world, properties)


    Ark.add_resource!(world, properties)

    return ECSModel(world)
end
