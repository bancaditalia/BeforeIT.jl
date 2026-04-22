function set_gov_expenditure!(world::Ark.World)
    properties = Ark.get_resource(world, Properties)
    expectations = Ark.get_resource(world, Expectations)
    price_indices = Ark.get_resource(world, PriceIndices)

    c_G_g = properties.product_coefficients.government_consumption
    P_bar_g = price_indices.sector
    pi_e = expectations.inflation

    local_governments = properties.dimensions.local_governments
    (; consumption_autoregression, consumption_autoregression_scalar, consumption_shock_sd) = properties.fiscal_policy
    epsilon_G = consumption_shock_sd .* randn()

    nominal_sector_demand = dot(P_bar_g, c_G_g)
    for (gov_e, government_consumption) in Ark.Query(world, (Components.ConsumptionDemand,), with = (Components.Government,))
        for i in eachindex(gov_e)

            government_consumption[i] .= Components.ConsumptionDemand(exp(consumption_autoregression .* log(government_consumption[i].amount) + consumption_autoregression_scalar + epsilon_G))
            for (_, local_gov_consumption) in Ark.Query(world, (Components.ConsumptionDemand), relations = (Components.LocalGovernment => gov_e[i]))
                local_gov_consumption.amount .= government_consumption[i].amount ./ local_governments .* nominal_sector_demand .* (1 .+ pi_e)
            end
        end

    end

    return nothing
end


function set_government_revenues!(world::Ark.World)

    properties = Ark.get_resource(world, Properties)
    (;
        income,
        corporate,
        value_added,
        exports,
        capital_formation,
        government_consumption,
    ) = properties.tax_rates

    cpi = Ark.get_resource(world, PriceIndices).household_consumption


    return nothing
end
