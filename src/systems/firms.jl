# --- helpers (small, type-stable, inlinable) ---------------------------------

@inline function labor_cost_component(
        average_wage::T, employer_contribution::T,
        household_price_index::T, inv_price::T
    ) where {T <: Real}
    # (1 + sc) * w * (P_h / p - 1)
    return (one(T) + employer_contribution) * average_wage * (household_price_index * inv_price - one(T))
end

@inline function material_cost_component(
        intermediate_productivity::T,
        sector_production_cost::T, inv_price::T
    ) where {T <: Real}
    # (1 / a_m) * (c_s / p)
    return (one(T) / intermediate_productivity) * (sector_production_cost * inv_price)
end

@inline function capital_cost_component(
        deprecation_rate::T, capital_productivity::T,
        capital_goods_price_index::T, inv_price::T
    ) where {T <: Real}
    # (δ / a_k) * (P_k / p - 1)
    return (deprecation_rate / capital_productivity) * (capital_goods_price_index * inv_price - one(T))
end


function set_firms_expectations_and_decisions!(world::Ark.World)
    expectations = Ark.get_resource(world, Expectations)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    firm_cache = Ark.get_resource(world, FirmTmpBuffer{Float64})

    # Precompute sector production costs: c_s = A' * p_sector
    A = properties.production_coefficients.technology_matrix
    mul!(firm_cache.sector_production_cost, transpose(A), price_indices.sector)

    employer_contribution = properties.social_insurance.employer_contribution
    pk = price_indices.capital_goods
    sector_costs = firm_cache.sector_production_cost

    for (
            e, principal_product, prices, average_wages, deprecation_rate,
            intermediate_productivity, capital_productivity, labor_productivity, goods_demand, capital,
        ) in Ark.Query(
            world,
            (
                Components.PrincipalProduct, Components.Price, Components.AverageWageRate,
                Components.CapitalDeprecationRate, Components.IntermediateProductivity, Components.LaborProductivity,
                Components.CapitalProductivity, Components.GoodsDemand, Components.Capital,
            )
        )
        @inbounds for i in eachindex(e)
            inv_price = inv(prices[i].value)

            labor_cost = labor_cost_component(
                average_wages[i].rate, employer_contribution,
                price_indices.household, inv_price
            )

            material_cost = material_cost_component(
                intermediate_productivity[i].value,
                sector_costs[principal_product[i].id],
                inv_price
            )

            capital_cost = capital_cost_component(
                deprecation_rate[i].rate,
                capital_productivity[i].value,
                pk, inv_price
            )

            cost_pust_inflation = labor_cost + material_cost + capital_cost

            effective_sales = min(
                (1 + expectations.growth) * goods_demand[i].amount, capital_productivity[i] * capital[i].amount
            )

            target_capital_investment = deprecation_rate[i].rate / capital_productivity[i].value * effective_sales
            target_intermediary_goods = effective_sales / capital_productivity[i].value
            target_employment = max(1, round(Int64, effective_sales / labor_productivity[i].value))

        end
    end

    return nothing
end
