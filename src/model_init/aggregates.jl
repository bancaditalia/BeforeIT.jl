function setup_aggregates!(world::Ark.World, properties::Properties)
    economy = properties.initial_conditions.economy


    Ark.add_resource!(
        world,
        TimeIndex(0.0)
    )

    Ark.add_resource!(
        world, properties
    )
    Ark.add_resource!(
        world,
        Shocks(
            0.0,                    # foreign_output_shock
            0.0,                    # export_demand_shock
            0.0
        )
    )

    Ark.add_resource!(world, FirmTmpBuffers{Float64}(zeros(properties.dimensions.sectors)))
    Ark.add_resource!(world, DesiredIntermediatesCache(properties.dimensions.total_firms, properties.dimensions.sectors))
    Ark.add_resource!(
        world, DesiredHouseholdConsumptionCache(
            properties.population.total + properties.dimensions.local_governments + properties.dimensions.foreign_consumers, properties.dimensions.sectors
        )

    )

    Ark.add_resource!(
        world, StockCache(
            properties.dimensions.total_firms + properties.dimensions.sectors,
            properties.dimensions.sectors
        )
    )

    Ark.add_resource!(world, Epsilons(0.0, 0.0, 0.0))

    Ark.add_resource!(world, Expectations(0.0, 0.0, 0.0))
    Ark.add_resource!(
        world, PriceIndices(
            zeros(Float64, properties.dimensions.sectors), # sector price index
            1.0,                                           # aggregate_price_index
            1.0,                                           # household_consumption_price_index
            1.0,                                           # capital_goods_price_index
            0.0,                                           # household_consumption_price_index_previous
            0.0,                                           # capital_goods_price_index_previous
        )
    )
    Ark.add_resource!(
        world,
        MacroeconomicState(
            economy.total_output,                          # gross_domestic_product_history
            economy.inflation,                             # inflation_history
        )
    )
    return nothing

end
