function gross_domestic_product(model::AbstractModel)
    firms, agg, prop = model.firms, model.agg, model.prop
    return sum(firms.Y_i)
end
function set_gross_domestic_product!(world::Ark.World)
    macro_state = Ark.get_resource(world, MacroeconomicState)
    t = Ark.get_resource(world, TimeIndex)
    properties = BeforeIT.properties(world)
    T_prime = properties.dimensions.interval_for_expectation_estimation


    push!(0.0, macro_state.gross_domestic_product_histroy)
    macro_state.gross_domestic_product_histroy[T_prime + t.step] = @sum_over (c.amount for c in Ark.Query(world, (Components.Output,)))
    return nothing
end

function set_time!(world::Ark.World)
    t = Ark.get_resource(world, TimeIndex)
    t.step += 1
    return nothing
end
