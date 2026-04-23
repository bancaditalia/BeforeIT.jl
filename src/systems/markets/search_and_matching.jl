function search_and_matching!(world::Ark.World)
    build_intermediate_demand_cache!(world)
    build_consumption_demand_cache!(world)
    return nothing
end

function build_intermediate_demand_cache!(world::Ark.World)
    properties = BeforeIT.properties(world)
    demand_from_intermediates_cache = Ark.get_resource(world, DesiredIntermediatesCache)
    BeforeIT.reset_cache!(demand_from_intermediates_cache)

    (; technology_matrix, capital_formation) = properties.product_coeffs
    for (e, principal_product, desired_investment, desired_materials) in Ark.Query(world, (Components.PrincipalProduct, Components.DesiredInvestment, Components.DesiredMaterials))
        for i in eachindex(e)
            BeforeIT.emblace!(
                @view(technology_matrix[:, principal_product[i].id]) .* desired_materials[i].amount + capital_formation .* desired_investment[i].amount,
                e[i],
                demand_from_intermediates_cache
            )
        end
    end

    return nothing
end

function build_consumption_demand_cache!(world::Ark.World)
    properties = BeforeIT.properties(world)
    demand_from_consumption_cache = Ark.get_resource(world, DesiredHouseholdConsumptionCache)
    BeforeIT.reset_cache!(demand_from_consumption_cache)
    (; household_consumption, household_investment, exports, government_consumption) = properties.product_coeffs

    for (e, consumption_budget, investment_budget) in Ark.Query(world, (Components.ConsumptionBudget, Components.InvestmentBudget))
        for i in eachindex(e)
            BeforeIT.emblace!(
                household_consumption .* consumption_budget[i].amount + household_investment .* investment_budget[i].amount,
                e[i],
                demand_from_consumption_cache
            )
        end
    end

    for (e, import_demand) in Ark.Query(world, (Components.ImportDemand,))
        for i in eachindex(e)
            BeforeIT.emblace!(
                exports * import_demand[i].amount,
                e[i],
                demand_from_consumption_cache
            )
        end
    end

    for (e, consumption_demand) in Ark.Query(world, (Components.ConsumptionDemand,), with = (Components.LocalGovernment,))
        for i in eachindex(e)
            BeforeIT.emblace!(
                government_consumption * consumption_demand[i].amount,
                e[i],
                demand_from_consumption_cache
            )
        end
    end

    return nothing
end
