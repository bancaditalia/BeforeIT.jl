function search_and_matching!(world::Ark.World)
    build_demand_cache!(world)
    return nothing
end

function build_demand_cache!(world::Ark.World)
    properties = BeforeIT.properties(world)
    demand_for_sectors_cache = Ark.get_resource(world, DesiredSectorProductionCache)
    BeforeIT.reset_cache!(demand_for_sectors_cache)

    (; technology_matrix, capital_formation) = properties.product_coeffs
    for (e, principal_product, desired_investment, desired_materials) in Ark.Query(world, (Components.PrincipalProduct, Components.DesiredInvestment, Components.DesiredMaterials))
        for i in eachindex(e)
            BeforeIT.emblace_firm!(@view(technology_matrix[:, principal_product[i].id]) .* desired_materials[i].amount + capital_formation .* desired_investment[i].amount, e[i], demand_for_sectors_cache)
        end
    end

    return
end
