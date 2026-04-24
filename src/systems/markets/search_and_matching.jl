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

#TODO: This allocates alot and should be fixed, A single execution takes arround 14ms
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

function build_stock_cache!(world::Ark.World)
    stock_cache = Ark.get_resource(world, BeforeIT.StockCache)
    BeforeIT.reset_cache!(stock_cache)

    for (e, pp, output, stocks, capital, capital_productivity, price) in Ark.Query(world, (Components. PrincipalProduct, Components.Output, Components.Inventories, Components.CapitalStock, Components.CapitalProductivity, Components.Price))
        @inbounds for i in eachindex(e)
            BeforeIT.emblace!(
                output[i].amount + stocks[i].amount,
                capital[i].amount * capital_productivity[i].value - output[i].amount,
                price[i].value,
                pp[i].id,
                e[i],
                stock_cache
            )
        end
    end

    for (e, pp, import_supply, price) in Ark.Query(world, (Components. PrincipalProduct, Components.ImportSupply, Components.ImportPrice))
        @inbounds for i in eachindex(e)
            BeforeIT.emblace!(
                import_supply[i].amount,
                Inf,
                price[i].value,
                pp[i].id,
                e[i],
                stock_cache
            )
        end
    end
    BeforeIT.finalize_stock_cache!(stock_cache)

    return nothing
end

function perform_firm_market!(world::Ark.World, sector::Int64)
    demand_from_intermediates_cache = Ark.get_resource(world, BeforeIT.DesiredIntermediatesCache)
    stock_cache = Ark.get_resource(world, BeforeIT.StockCache)

    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector
    while !iszero(@view demand_from_intermediates_cache.vals[:, sector]) && !iszero(BeforeIT.get_available_stocks(stock_cache, sector))
        for i in shuffle(eachindex(demand_from_intermediates_cache.vals[:, sector]))
            firm_index = BeforeIT.choose_random_firm(cache, sector, weights)
            x = min(stock_cache.available_stocks[firm_index, sector], demand_from_intermediates_cache.vals[i, sector])
            stock_cache.available_stocks[firm_index, sector] -= x
            demand_from_intermediates_cache.nominal[i, sector] += x * stock_cache.prices[firm_index, sector]
            demand_from_intermediates_cache.vals[i, sector] -= x
            weights[firm_index - cache.sector_offset[sector]] *= !iszero(demand_from_intermediates_cache.vals[i, sector])
        end
    end

    a = @view(a_sg[g, firms.G_i]) .* firms.DM_d_i .- pos.(DM_d_ig .- b_CF_g[g] .* firms.I_d_i)
    b = pos.(b_CF_g[g] .* firms.I_d_i .- DM_d_ig)
    c = @view(a_sg[g, firms.G_i]) .* firms.DM_d_i .+ b_CF_g[g] .* firms.I_d_i .- DM_d_ig


    DM_i_g[:, g] .= a
    I_i_g[:, g] .= b

    P_bar_i_g[:, g] .= DM_nominal_ig .* a ./ zero_to_one.(c)
    P_CF_i_g[:, g] .= DM_nominal_ig .* b ./ zero_to_one.(c)


    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector
    while !iszero(@view demand_from_intermediates_cache.vals[:, sector])&& !iszero(BeforeIT.get_stock_capacity(stock_cache, sector))
        for i in shuffle(eachindex(demand_from_intermediates_cache.vals[:, sector]))
            firm_index = BeforeIT.choose_random_firm(cache, sector, weights)
            x = min(stock_cache.stock_capacity[firm_index, sector], demand_from_intermediates_cache.vals[i, sector])
            stock_cache.available_stocks[firm_index, sector] -= x
            stock_cache.stock_capacity[firm_index, sector] -= x

            demand_from_intermediates_cache.vals[i, sector] -= x

            weights[firm_index - cache.sector_offset[sector]] *= !iszero(demand_from_intermediates_cache.vals[i, sector])
        end
    end


    return
end

function perform_retail_market!(world::Ark.World, sector::Int64)
    demand_from_consumption_cache = Ark.get_resource(world, BeforeIT.DesiredHouseholdConsumptionCache)
    stock_cache = Ark.get_resource(world, BeforeIT.StockCache)

    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector
    while !iszero(@view demand_from_consumption_cache.vals[:, sector]) && !iszero(BeforeIT.get_available_stocks(stock_cache, sector))
        for i in shuffle(eachindex(demand_from_consumption_cache.vals[:, sector]))
            firm_index = BeforeIT.choose_random_firm(cache, sector, weights)
            price = stock_cache.prices[firm_index, sector]
            x = min(stock_cache.available_stocks[firm_index, sector], demand_from_consumption_cache.vals[i, sector] / price)
            stock_cache.available_stocks[firm_index, sector] -= x
            demand_from_consumption_cache.nominal[i, sector] += x
            demand_from_consumption_cache.vals[i, sector] = max(demand_from_consumption_cache.vals[i, sector] - x * price, 0.0)
            weights[firm_index - cache.sector_offset[sector]] *= !iszero(demand_from_consumption_cache.vals[i, sector])
        end
    end

    a = @view(a_sg[g, firms.G_i]) .* firms.DM_d_i .- pos.(DM_d_ig .- b_CF_g[g] .* firms.I_d_i)
    b = pos.(b_CF_g[g] .* firms.I_d_i .- DM_d_ig)
    c = @view(a_sg[g, firms.G_i]) .* firms.DM_d_i .+ b_CF_g[g] .* firms.I_d_i .- DM_d_ig


    DM_i_g[:, g] .= a
    I_i_g[:, g] .= b

    P_bar_i_g[:, g] .= DM_nominal_ig .* a ./ zero_to_one.(c)
    P_CF_i_g[:, g] .= DM_nominal_ig .* b ./ zero_to_one.(c)


    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector
    while !iszero(@view demand_from_consumption_cache.vals[:, sector]) && !iszero(BeforeIT.get_available_stocks(stock_cache, sector))
        for i in shuffle(eachindex(demand_from_consumption_cache.vals[:, sector]))
            firm_index = BeforeIT.choose_random_firm(cache, sector, weights)
            price = stock_cache.prices[firm_index, sector]
            x = min(
                stock_cache.stock_capacity[firm_index, sector],
                demand_from_consumption_cache.vals[i, sector] / price
            )
            stock_cache.available_stocks[firm_index, sector] -= x
            stock_cache.stock_capacity[firm_index, sector] -= x
            demand_from_consumption_cache.vals[i, sector] = max(demand_from_consumption_cache.vals[i, sector] - x * price, 0.0)
            weights[firm_index - cache.sector_offset[sector]] *= !iszero(demand_from_consumption_cache.vals[i, sector])
        end
    end

    return
end
