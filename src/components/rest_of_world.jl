@component struct EuroAreaGDP <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGrowth <: AbstractComponent
    value::Float64
end

@component struct EuroAreaInflation <: AbstractComponent
    value::Float64
end

@component struct NetForeignPosition <: AbstractComponent
    amount::Float64
end

@component struct ImportSupply <: AbstractComponent
    quantity::Float64
end


@component struct ExportDemand <: AbstractComponent
    values::Float64
end

@component struct ImportSupply <: AbstractComponent
    values::Float64
end

@component struct ImportSales <: AbstractComponent
    values::Float64
end

@component struct ImportDemand <: AbstractComponent
    values::Float64
end

@component struct ImportPrice <: AbstractComponent
    values::Float64
end

@component struct ExportPriceInflation <: AbstractComponent
    value::Float64
end

@component struct ForeignSector <: AbstractComponent
    id::Int
end

@component struct ForeignConsumptionDemand <: AbstractComponent
    amount::Float64
end

@component struct ForeignConsumption <: AbstractComponent
    amount::Float64
end
