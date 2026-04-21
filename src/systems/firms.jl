function set_firms_expectations_and_decisions!(world::Ark.World)
    expectations = Ark.get_resource(world, Expectations)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    #cost_push_inflation
    A = properties.production_coefficients.technology_matrix

    for (e, principal_product, prices, average_wages, deprecation_rate, intermediate_productivity, capital_productivity) in Ark.Query(
            world,
            (Components.PrincipalProduct, Components.Price, Components.AverageWageRate, Components.CapitalDeprecationRate, Components.IntermediateProductivity, Components.CapitalProductivity)
        )
        @inbounds for i in eachindex(e)
            inverse_price = inv(prices[i].value)
            labor_cost = (1 + properties.social_insurance.employer_contribution) * average_wages[i].rate * (price_indices.household * inverse_price - 1)
            material_cost = 1 ./ intermediate_productivity[i].value .* (
                dot(@views A[:, principal_product[i].id], price_indices.sector)
                    * inverse_price
            )
            capital_cost = deprecation_rate[i].rate ./ capital_productivity[i].value * (price_indices.capital_goods * inverse_price - 1)
        end

    end

    return nothing
end
