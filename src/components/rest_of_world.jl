@component struct ExportAutoregressiveCoefficient <: AbstractComponent
    value::Float64
end

@component struct ExportConstant <: AbstractComponent
    value::Float64
end

@component struct ExportShockVariance <: AbstractComponent
    value::Float64
end

@component struct ImportAutoregressiveCoefficient <: AbstractComponent
    value::Float64
end

@component struct ImportConstant <: AbstractComponent
    value::Float64
end

@component struct ImportShockVariance <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGDP <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGrowth <: AbstractComponent
    value::Float64
end

@component struct EuroAreaInflation <: AbstractComponent
    value::Float64
end

@component struct EuroAreaInflationAR <: AbstractComponent
    value::Float64
end

@component struct EuroAreaInflationConstant <: AbstractComponent
    value::Float64
end

@component struct EuroAreaInflationShockVariance <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGDPAR <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGDPConstant <: AbstractComponent
    value::Float64
end

@component struct EuroAreaGDPShockVariance <: AbstractComponent
    value::Float64
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

@component struct ExportDemand <: AbstractComponent
    values::Float64
end

@component struct ImportSupply <: AbstractComponent
    values::Vector{Float64}
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
