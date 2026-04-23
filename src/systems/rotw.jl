function set_rotw_import_export!(world::Ark.World)
    properties = BeforeIT.properties(world)
    sector_price_index = BeforeIT.price_indices(world).sector
    expected_inflation = BeforeIT.expectations(world).inflation
    (; exports, imports) = properties.product_coeffs

    (; E, I) = BeforeIT.epsilons(world)
    (; foreign_consumers) = properties.dimensions
    (; exports_response_to_foreign_output, exports_autoregression) = properties.fiscal_policy
    (; investment_autoregression, investment_response_to_utilization) = properties.sectoral_params

    for (_, total_export_demand, total_import_supply) in Ark.Query(world, (Components.TotalExportDemand, Components.TotalImportSupply))
        total_export_demand.amount .= exp.(exports_response_to_foreign_output .* log.(total_export_demand.amount) .+ exports_autoregression .+ E)
        total_import_supply.amount .= exp.(investment_autoregression .* log.(total_import_supply.amount) .+ investment_response_to_utilization .+ I)

        for (_, export_demand) in Ark.Query(world, (Components.ExportDemand,))
            export_demand.amount .= only(total_export_demand.amount) / foreign_consumers * dot(exports, sector_price_index) * (1 + expected_inflation)

        end

        for (_, import_supply, import_price) in Ark.Query(world, (Components.ImportSupply, Components.ImportPrice))
            import_supply.amount .= imports * only(total_import_supply.amount)
            import_price.value .= (1 + expected_inflation) * sector_price_index
        end

    end


    return nothing
end

function set_rotw_deposits!(world::Ark.World)
    properties = BeforeIT.properties(world)

    τ_EXPORT = properties.tax_rates.exports

    for (_, net_foreign_position, foreign_consumption) in Ark.Query(world, (Components.NetForeignPosition, Components.ForeignConsumption))

        for (_, price, sales) in Ark.Query(world, (Components.ImportPrice, Components.ImportSales))
            net_foreign_position.amount .+= dot(price.value, sales.amount)
        end
        net_foreign_position.amount .-= (1 - τ_EXPORT) * foreign_consumption.amount
    end

    return nothing
end
