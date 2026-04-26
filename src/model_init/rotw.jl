function setup_rotw!(world::Ark.World, properties::Properties)
    L = properties.dimensions.foreign_consumers
    G = properties.dimensions.sectors
    T_prime = properties.dimensions.interval_for_expectation_estimation


    external = properties.initial_conditions.external

    rotw = Ark.new_entity!(
        world,
        (
            Components.EuroAreaGDP(external.foreign_output),
            Components.EuroAreaGrowth(0.0),
            Components.EuroAreaInflation(external.foreign_inflation),
            Components.NetForeignPosition(external.debt),
            Components.ForeignConsumption(0.0),
            Components.TotalExportDemand(external.exports[T_prime]),
            Components.TotalImportSupply(external.imports[T_prime]),
        )
    )

    Ark.new_entities!(
        world, L, (
            Components.ForeignConsumptionDemand,
            Components.RestOfWorldEntity,
        )
    ) do (entities, fc, rowe)
        for i in eachindex(entities)
            fc[i] = Components.ForeignConsumptionDemand(0.0)
            rowe[i] = Components.RestOfWorldEntity(rotw)
        end
    end


    Ark.new_entities!(
        world, G,
        (

            Components.ForeignSector,
            Components.PrincipalProduct,
            Components.ImportSupply,
            Components.ImportSales,
            Components.ImportDemand,
            Components.ImportPrice,
            Components.ExportPriceInflation,
            Components.RestOfWorldEntity,
        )
    ) do (entities, fs, pp, isupply, isales, idemand, iprice, epi, rowe)
        for (g, i) in enumerate(eachindex(entities))
            fs[i] = Components.ForeignSector()
            pp[i] = Components.PrincipalProduct(g)
            isupply[i] = Components.ImportSupply(0.0)
            isales[i] = Components.ImportSales(0.0)
            idemand[i] = Components.ImportDemand(0.0)
            iprice[i] = Components.ImportPrice(0.0)
            epi[i] = Components.ExportPriceInflation(0.0)
            rowe[i] = Components.RestOfWorldEntity(rotw)
        end
    end

    return nothing
end
