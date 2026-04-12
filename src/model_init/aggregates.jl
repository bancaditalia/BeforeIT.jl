function setup_aggregates!(world::Ark.World, properties::Properties)
    economy = properties.initial_conditions.economy


    Ark.add_resource!(
        world,
        TimeIndex(0.0)
    )

    Ark.add_resource!(
        world, properties
    )
    return Ark.add_resource!(
        world,
        MacroeconomicState(
            economy.total_output,   # gross_domestic_product_history
            economy.inflation,      # inflation_history
            1.0,                    # aggregate_price_index
            1.0,                    # household_consumption_price_index
            1.0,                    # capital_goods_price_index
            0.0,                    # household_consumption_price_index_previous
            0.0,                    # capital_goods_price_index_previous
            0.0,                    # expected_gross_domestic_product
            0.0,                    # expected_output_growth
            0.0,                    # expected_inflation
            0.0,                    # foreign_output_shock
            0.0,                    # export_demand_shock
            0.0,                    # investment_demand_shock
        )
    )

end
