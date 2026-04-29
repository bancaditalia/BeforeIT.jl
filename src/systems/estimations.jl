function set_growth_inflation_expectations!(world::Ark.World)
    macro_state = Ark.get_resource(world, MacroeconomicState)
    properties = BeforeIT.properties(world)
    expectations = BeforeIT.expectations(world)
    interval = properties.dimensions.interval_for_expectation_estimation
    t = Ark.get_resource(world, TimeIndex).step

    (; gross_domestic_product_history, inflation_history) = macro_state


    expected_gdp = estimate_next_value(log.(gross_domestic_product_history[1:(interval + t - 1)])) |> exp
    expected_growth = expected_gdp / gross_domestic_product_history[interval + t - 1] - 1.0
    expected_inflation = exp(estimate_next_value(inflation_history[1:(interval + t - 1)])) - 1.0

    expectations.gross_domestic_product = expected_gdp
    expectations.output_growth = expected_growth
    expectations.inflation = expected_inflation


    return nothing
end

function set_growth_inflation_EA!(world::Ark.World)
    epsilon_Y_EA = Ark.get_resource(world, Epsilons).Y_EA
    (;
        inflation_shock_sd,
        output_autoregression,
        inflation_response_to_output_gap,
        inflation_autoregression, output_autoregression_scalar,
    ) = Ark.get_resource(world, Properties).external_params

    random_inflation_shock = inflation_shock_sd * randn()


    for (e, gdp, growth, inflation) in Ark.Query(world, (Components.EuroAreaGDP, Components.EuroAreaGrowth, Components.EuroAreaInflation))
        @inbounds for i in eachindex(e)
            expected_growth = exp(output_autoregression * log(gdp[i].value) + output_autoregression_scalar + epsilon_Y_EA)
            growth[i] = Components.EuroAreaGrowth(expected_growth / gdp[i].value - 1)
            gdp[i] = Components.EuroAreaGDP(expected_growth)
            inflation[i] = Components.EuroAreaInflation(
                exp(inflation_autoregression * log1p(inflation[i].rate) + inflation_response_to_output_gap + random_inflation_shock) - 1
            )
        end
    end


    return nothing
end

function set_inflation_priceindex!(world::Ark.World)
    macro_state = Ark.get_resource(world, MacroeconomicState)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    interval = properties.dimensions.interval_for_expectation_estimation
    t = Ark.get_resource(world, TimeIndex).step
    total_monetary_output_value = 0.0
    total_output = 0.0

    for (_, prices, quantities) in Ark.Query(world, (Components.Price, Components.Output))
        total_monetary_output_value += sum(prices.value .* quantities.amount)
        total_output += sum(quantities.amount)
    end
    price_index = total_monetary_output_value / total_output
    price_indices.aggregate = price_index / price_indices.aggregate
    inflation = log(price_indices.aggregate)
    push!(macro_state.inflation_history, 0.0)
    macro_state.inflation_history[interval + t] = inflation

    return nothing
end

function set_sector_specific_priceindex!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    fill!(price_indices.sector, 0.0)
    total_sales = zeros(size(price_indices.sector))

    for (entities, principal_product, prices, sales) in Ark.Query(world, (Components.PrincipalProduct, Components.Price, Components.Sales))
        @inbounds for i in eachindex(entities)
            price_indices.sector[principal_product[i].id] += prices[i].value * sales[i].amount
            total_sales[principal_product[i].id] += sales[i].amount
        end
    end

    for (entities, principal_product, prices, sales) in Ark.Query(world, (Components.PrincipalProduct, Components.ImportPrice, Components.ImportSales))
        @inbounds for i in eachindex(entities)
            price_indices.sector[principal_product[i].id] += prices[i].value * sales[i].amount
            total_sales[principal_product[i].id] += sales[i].amount
        end
    end

    price_indices.sector ./= total_sales
    return nothing
end

function set_capital_formation_priceindex!(world::Ark.World)
    price_indices = BeforeIT.price_indices(world)
    properties = BeforeIT.properties(world)
    price_indices.capital_goods = LinearAlgebra.dot(properties.product_coeffs.capital_formation, price_indices.sector)
    return nothing
end

function set_households_priceindex!(world::Ark.World)
    price_indices = BeforeIT.price_indices(world)
    properties = BeforeIT.properties(world)

    price_indices.household_consumption = LinearAlgebra.dot(properties.product_coeffs.household_consumption, price_indices.sector)
    return nothing

end
