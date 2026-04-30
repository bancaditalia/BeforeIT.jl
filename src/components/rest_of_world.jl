@component struct EuroAreaGDP <: AbstractComponent
    value::FloatType
end

@component struct EuroAreaGrowth <: AbstractComponent
    rate::FloatType
end

@component struct EuroAreaInflation <: AbstractComponent
    rate::FloatType
end

@component struct NetForeignPosition <: AbstractComponent
    amount::FloatType
end

@component struct ImportSupply <: AbstractComponent
    amount::FloatType
end

@component struct TotalExportDemand <: AbstractComponent
    amount::FloatType
end

@component struct TotalImportSupply <: AbstractComponent
    amount::FloatType
end

@component struct ExportDemand <: AbstractComponent
    amount::FloatType
end

@component struct ImportSales <: AbstractComponent
    amount::FloatType
end

@component struct ImportDemand <: AbstractComponent
    amount::FloatType
end
@component struct ImportPrice <: AbstractComponent
    value::FloatType
end

@component struct ExportPriceInflation <: AbstractComponent
    value::FloatType
end

@component struct ForeignSector <: AbstractComponent end

@component struct ForeignConsumptionDemand <: AbstractComponent
    amount::FloatType
end

@component struct ForeignConsumption <: AbstractComponent
    amount::FloatType
end

@component struct RestOfWorldEntity <: AbstractComponent
    entity::Ark.Entity
end

@component struct RestOfWorld <: AbstractComponent end
