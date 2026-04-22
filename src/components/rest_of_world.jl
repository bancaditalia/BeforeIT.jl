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
    quantity::Float64
end

@component struct ExportDemand <: AbstractComponent
    quantity::Float64
end

@component struct ImportSales <: AbstractComponent
    quantity::Float64
end

@component struct ImportDemand <: AbstractComponent
    quantity::Float64
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
