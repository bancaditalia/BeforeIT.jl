function search_and_matching!(world::Ark.World)
    build_intermediate_demand_cache!(world)
    build_consumption_demand_cache!(world)
    build_stock_cache!(world)
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

function rebuild_active_buyers!(active, demand, sector)

    nactive = 0
    @inbounds for i in axes(demand, 1)
        if demand[i, sector] > 0.0
            nactive += 1
            active[nactive] = i
        end
    end
    return nactive
end

function perform_firm_market!(world::Ark.World, sector::Int64)
    demand_from_intermediates_cache = Ark.get_resource(world, BeforeIT.DesiredIntermediatesCache)
    stock_cache = Ark.get_resource(world, BeforeIT.StockCache)

    (; technology_matrix, capital_formation) = BeforeIT.properties(world).product_coeffs
    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector


    remaining_supply = sum(BeforeIT.get_available_stocks(stock_cache, sector))

    active = Vector{Int64}(undef, size(demand_from_intermediates_cache.vals, 1))

    nactive = rebuild_active_buyers!(active, demand_from_intermediates_cache.vals, sector)

    while nactive > 0 && !iszero(remaining_supply)
        i = 1
        shuffle!(view(active, 1:nactive))
        while i <= nactive
            buyer = active[i]
            firm_index = BeforeIT.choose_random_firm(stock_cache, sector, weights)
            sold_amount = min(stock_cache.available_stocks[firm_index, sector], demand_from_intermediates_cache.vals[buyer, sector])
            stock_cache.available_stocks[firm_index, sector] -= sold_amount
            demand_from_intermediates_cache.nominal[buyer, sector] += sold_amount * stock_cache.prices[firm_index, sector]
            demand_from_intermediates_cache.vals[buyer, sector] = max(demand_from_intermediates_cache.vals[buyer, sector] - sold_amount, 0.0)
            remaining_supply -= sold_amount
            weights[firm_index - stock_cache.sector_offset[sector]] *= !iszero(stock_cache.available_stocks[firm_index, sector])
            if iszero(demand_from_intermediates_cache.vals[buyer, sector])
                active[i] = active[nactive]
                nactive -= 1
            else
                i += 1
            end

        end
    end

    remaining_supply = sum(BeforeIT.get_stock_capacity(stock_cache, sector))

    for (e, material_stock_change, investment, principal_product, desired_materials, desired_investment, price_index, cf_price_index) in Ark.Query(
            world,
            (Components.MaterialStockChange, Components.Investment, Components.PrincipalProduct, Components.DesiredMaterials, Components.DesiredInvestment, Components.PriceIndex, Components.CFPriceIndex)
        )
        for i in eachindex(e)
            index_of_entity = BeforeIT.find_entity_index(e[i], demand_from_intermediates_cache)
            material_stock_change[i] = Components.MaterialStockChange(
                material_stock_change[i].amount +
                    technology_matrix[sector, principal_product[i].id] * desired_materials[i].amount - max(
                    0.0, demand_from_intermediates_cache.vals[index_of_entity, sector] - capital_formation[sector] * desired_investment[i].amount
                )
            )
            investment[i] = Components.Investment(
                investment[i].amount + max(0.0, capital_formation[sector] * desired_investment[i].amount - demand_from_intermediates_cache.vals[index_of_entity, sector])
            )

            realised_quantities = technology_matrix[sector, principal_product[i].id] * desired_materials[i].amount + capital_formation[sector] * desired_investment[i].amount - demand_from_intermediates_cache.vals[index_of_entity, sector]

            price_index[i] = Components.PriceIndex(
                price_index[i].value +
                    demand_from_intermediates_cache.nominal[index_of_entity, sector] * material_stock_change[i].amount / realised_quantities
            )

            cf_price_index[i] = Components.CFPriceIndex(
                cf_price_index[i].value +
                    demand_from_intermediates_cache.nominal[index_of_entity, sector] * investment[i].amount / realised_quantities
            )
        end
    end

    nactive = rebuild_active_buyers!(active, demand_from_intermediates_cache.vals, sector)


    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector
    while nactive > 0 && !iszero(remaining_supply)
        i = 1
        shuffle!(view(active, 1:nactive))
        while i <= nactive
            buyer = active[i]
            firm_index = BeforeIT.choose_random_firm(stock_cache, sector, weights)
            sold_amount = min(stock_cache.stock_capacity[firm_index, sector], demand_from_intermediates_cache.vals[buyer, sector])
            stock_cache.available_stocks[firm_index, sector] -= sold_amount
            stock_cache.stock_capacity[firm_index, sector] -= sold_amount
            remaining_supply -= sold_amount

            demand_from_intermediates_cache.vals[buyer, sector] = max(demand_from_intermediates_cache.vals[buyer, sector] - sold_amount, 0.0)

            weights[firm_index - stock_cache.sector_offset[sector]] *= !iszero(stock_cache.stock_capacity[firm_index, sector])

            if iszero(demand_from_intermediates_cache.vals[buyer, sector])
                active[i] = active[nactive]
                nactive -= 1
            else
                i += 1
            end
        end
    end


    return
end

function perform_retail_market!(world::Ark.World, sector::Int64)
    demand_from_consumption_cache = Ark.get_resource(world, BeforeIT.DesiredHouseholdConsumptionCache)
    stock_cache = Ark.get_resource(world, BeforeIT.StockCache)

    active = Vector{Int64}(undef, size(demand_from_consumption_cache.vals, 1))
    (; government_consumption, exports, household_consumption, household_investment) = BeforeIT.properties(world).product_coeffs

    nactive = rebuild_active_buyers!(active, demand_from_consumption_cache.vals, sector)
    remaining_stocks = sum(BeforeIT.get_available_stocks(stock_cache, sector))

    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector

    while nactive > 0 && !iszero(remaining_stocks)
        i = 1
        shuffle!(view(active, 1:nactive))
        while i <= nactive
            buyer = active[i]
            firm_index = BeforeIT.choose_random_firm(stock_cache, sector, weights)
            price = stock_cache.prices[firm_index, sector]
            sold_amount = min(stock_cache.available_stocks[firm_index, sector], demand_from_consumption_cache.vals[buyer, sector] / price)
            stock_cache.available_stocks[firm_index, sector] -= sold_amount
            demand_from_consumption_cache.nominal[buyer, sector] += sold_amount
            demand_from_consumption_cache.vals[buyer, sector] = max(demand_from_consumption_cache.vals[buyer, sector] - sold_amount * price, 0.0)
            weights[firm_index - stock_cache.sector_offset[sector]] *= !iszero(stock_cache.available_stocks[firm_index, sector])
            remaining_stocks = max(0.0, remaining_stocks - sold_amount)

            if iszero(demand_from_consumption_cache.vals[buyer, sector])
                active[i] = active[nactive]
                nactive -= 1
            else
                i += 1
            end
        end
    end


    for (e, realised_consumption) in Ark.Query(world, (Components.RealisedConsumption,), with = (Components.Government,))
        for i in eachindex(e)
            for (local_gov_e, consumption_demand) in Ark.Query(world, (Components.ConsumptionDemand,), relations = (Components.LocalGovernment => e[i]))
                for j in eachindex(local_gov_e)

                    idx = BeforeIT.find_entity_index(local_gov_e[j], demand_from_consumption_cache)
                    realised_consumption[i] = Components.RealisedConsumption(
                        realised_consumption[i].amount +
                            government_consumption[sector] * consumption_demand[j].amount -
                            demand_from_consumption_cache.val[idx, sector]
                    )
                end
            end
        end
    end

    for (e, foreign_consumption) in Ark.Query(world, (Components.ForeignConsumption,))
        for i in eachindex(e)
            for (foreign_sector_e, consumption_demand) in Ark.Query(world, (Components.ForeignConsumptionDemand,))
                for j in eachindex(foreign_sector_e)

                    idx = BeforeIT.find_entity_index(foreign_sector_e[j], demand_from_consumption_cache)
                    foreign_consumption[i] = Components.ForeignConsumption(
                        foreign_consumption[i].amount +
                            exports[sector] * consumption_demand[j].amount -
                            demand_from_consumption_cache.val[idx, sector]
                    )
                end
            end
        end
    end

    price_indices = BeforeIT.price_indices(world)

    total_real_demand = 0.0
    total_realized_consumption_expenditure = 0.0
    total_realized_investment_expenditure = 0.0
    total_expenditure = 0.0

    for (e, consumption_budget, investment_budget, realised_consumption, realised_investmet) in Ark.Query(world, (Components.ConsumptionBudget, Components.InvestmentBudget, Components.RealisedConsumption, Components.RealisedInvestmet), with = (Components.Household,))

        for i in eachindex(e)
            household_index = BeforeIT.find_entity_index(e[i], demand_from_consumption_cache)
            total_real_demand += demand_from_consumption_cache.nominal[household_index, sector]

            residual = household_investment[sector] * investment_budget[i].amount - demand_from_consumption_cache.vals[household_index, sector]
            sector_consumption_demand = household_consumption[sector] * consumption_budget[i].amount

            realised_consumption_comp =
                sector_consumption_demand - max(0.0, -residual)
            realised_consumption[i] = Components.RealisedConsumption(
                realised_consumption[i].amount + realised_consumption_comp
            )
            total_realized_consumption_expenditure += realised_consumption_comp

            realized_investment_comp =
                max(0.0, residual)

            realised_investmet[i] = Components.RealisedConsumption(
                realised_investmet[i].amount + realized_investment_comp
            )
            total_realized_investment_expenditure += realized_investment_comp
            total_expenditure += sector_consumption_demand + residual

        end
    end

    price_indices.household_consumption += total_real_demand * total_realized_consumption_expenditure / total_expenditure
    price_indices.capital_formation_households += total_real_demand * total_realized_investment_expenditure / total_expenditure


    nactive = rebuild_active_buyers!(active, demand_from_consumption_cache.vals, sector)

    weights = BeforeIT.get_weights(stock_cache, sector) |> FixedSizeWeightVector

    remaining_stocks = sum(BeforeIT.get_stock_capacity(stock_cache, sector))

    while nactive > 0 && !iszero(remaining_stocks)
        i = 1
        shuffle!(view(active, 1:nactive))
        while i <= nactive
            buyer = active[i]
            firm_index = BeforeIT.choose_random_firm(stock_cache, sector, weights)
            price = stock_cache.prices[firm_index, sector]
            sold_amount = min(
                stock_cache.stock_capacity[firm_index, sector],
                demand_from_consumption_cache.vals[buyer, sector] / price
            )
            stock_cache.available_stocks[firm_index, sector] -= sold_amount
            stock_cache.stock_capacity[firm_index, sector] -= sold_amount
            demand_from_consumption_cache.vals[buyer, sector] = max(demand_from_consumption_cache.vals[buyer, sector] - sold_amount * price, 0.0)
            weights[firm_index - stock_cache.sector_offset[sector]] *= !iszero(stock_cache.stock_capacity[firm_index, sector])

            if iszero(demand_from_consumption_cache.vals[buyer, sector])
                active[i] = active[nactive]
                nactive -= 1
            else
                i += 1

            end
        end
    end

    return
end
