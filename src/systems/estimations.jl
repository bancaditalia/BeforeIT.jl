function set_growth_inflation_expectations!(world::Ark.World)
    macro_state = Ark.get_resource(world, MacroeconomicState)
    properties = Ark.get_resource(world, Properties)
    interval = properties.dimensions.interval_for_expectation_estimation
    t = Ark.get_resource(world, TimeIndex).step

    (; gross_domestic_product_history, inflation_history) = macro_state


    expected_gdp = estimate_next_value(log.(gross_domestic_product_history[1:(interval + t - 1)])) |> exp
    expected_growth = expected_gdp / gross_domestic_product_history[interval + t - 1] - 1
    expected_inflation = estimate_next_value(log.(inflation_history[1:(interval + t - 1)])) |> exp

    macro_state.expected_gross_domestic_product = expected_gdp
    macro_state.expected_output_growth = expected_growth
    macro_state.expected_inflation = expected_inflation


    return nothing
end

function set_growth_inflation_for_EA!(world::Ark.World)
    epsilon_Y_EA = Ark.get_resource(world, Epsilons).Y_EA
    (;
        inflation_shock_sd,
        output_outoregression,
        inflation_response_to_output_gap,
        inflation_autoregression, output_autoregression_scalar,
    ) = Ark.get_resource(world, Properties).external_params

    random_inflation_shock = inflation_shock_sd * randn()


    for (e, gdp, growth, inflation) in Ark.Query(world, (Components.EuroAreaGDP, Components.EuroAreaGrowth, Components.EuroAreaInflation))
        @inbounds for i in eachindex(e)
            expected_growth = exp(output_outoregression * log(gdp[i].value) + output_autoregression_scalar + epsilon_Y_EA)
            growth[i] = Components.EuroAreaGrowth(expected_growth / gdp[i].value)
            gdp[i] = Components.EuroAreaGDP(expected_growth)
            inflation[i] = Components.EuroAreaInflation(
                exp(inflation_autoregression * log1p(inflation[i].value) + inflation_response_to_output_gap + random_inflation_shock)
            )
        end
    end


    return nothing
end

function set_inflation_price_index!(world::Ark.World)
    macro_state = Ark.get_resource(world, MacroeconomicState)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    interval = properties.dimensions.interval_for_expectation_estimation
    t = Ark.get_resource(world, TimeIndex).step
    total_monetary_output_value = 0.0
    total_output = 0.0

    for (entities, prices, quantities) in Ark.Query(world, (Component.Price, Component.Output))
        total_monetary_output_value += sum(prices.value .* quantities.amount)
        total_output += sum(quantities.amount)
    end
    price_index = total_monetary_output_value / total_output
    price_indices.aggregate = log(price_index / price_indices.aggregate)
    push!(macro_state.inflation_history, 0.0)
    macro_state.inflation_history[interval + t] = price_index

    return nothing
end

function set_sector_specific_priceindex!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    fill!(price_indices.sector, 0.0)
    total_quantities = zeros(size(price_indices.sector))

    for (entities, principal_product, prices, quantities) in Ark.Query(world, (Components.PrincipalProduct, Components.Price, Components.Quantities))
        @inbounds for i in eachindex(entities)
            price_indices.sector[principal_product[i].id] += prices[i].value * quantities[i].amount
            total_quantities[principal_product[i].id] += quantities[i].amount
        end
    end

    for (entities, principal_product, prices, quantities) in Ark.Query(world, (Components.PrincipalProduct, Components.ImportPrice, Components.ImportSales))
        @inbounds for i in eachindex(entities)
            price_indices.sector[principal_product[i].id] += prices[i].value * quantities[i].amount
            total_quantities[principal_product[i].id] += quantities[i].amount
        end
    end

    price_indices.sector ./= total_quantities
    return nothing
end

function set_capital_formation_priceindex!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)
    price_indices.capital_goods = LinearAlgebra.dot(properties.product_coefficients.capital_formation, price_indices.sector)
    return nothing
end

function set_household_price_index!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    price_indices.household_consumption = dot(properties.product_coefficients.household_consumption, price_indices.sector)
    return nothing

end
