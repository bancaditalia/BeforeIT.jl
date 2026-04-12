struct ECSModel{CS <: Tuple, CT <: Tuple, ST <: Tuple, N, M}
    world::Ark.World{CS, CT, ST, N, M}
end

function ECSModel(parameters::Dict{String, Any}, init_conditions::Dict{String, Any})
    return ECSModel(Properties(parameters, init_conditions))
end

function ECSModel(properties::Properties)
    world = Ark.World(Components.COMPONENTS...)

    setup_firms!(world, properties)
    setup_workers!(world, properties)
    setup_bank!(world, properties)
    setup_central_bank!(world, properties)
    setup_government!(world, properties)
    setup_rotw!(world, properties)
    setup_aggregates!(world, properties)

    return ECSModel(world)
end


function properties(m::ECSModel)
    return Ark.get_resource(m.world, Properties)
end
