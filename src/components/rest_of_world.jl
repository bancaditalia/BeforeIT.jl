@component struct EuroAreaGDP <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGrowth <: AbstractComponent
    rate::Float64
end

@component struct EuroAreaInflation <: AbstractComponent
    rate::Float64
end

@component struct NetForeignPosition <: AbstractComponent
    amount::Float64
end

@component struct ImportSupply <: AbstractComponent
    amount::Float64
end

@component struct TotalExportDemand <: AbstractComponent
    amount::Float64
end

@component struct TotalImportSupply <: AbstractComponent
    amount::Float64
end

@component struct ExportDemand <: AbstractComponent
    amount::Float64
end

@component struct ImportSales <: AbstractComponent
    amount::Float64
end

@component struct ImportDemand <: AbstractComponent
    amount::Float64
end
@component struct ImportPrice <: AbstractComponent
    value::Float64
end

@component struct ExportPriceInflation <: AbstractComponent
    value::Float64
end

@component struct ForeignSector <: AbstractComponent end

@component struct ForeignConsumptionDemand <: AbstractComponent
    amount::Float64
end

@component struct ForeignConsumption <: AbstractComponent
    amount::Float64
end

@component struct RestOfWorldEntity <: AbstractComponent
    entity::Ark.Entity
end

@component struct RestOfWorld <: AbstractComponent end
