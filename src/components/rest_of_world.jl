struct ExportAutoregressiveCoefficient <: AbstractComponent
    value::Float64
end

struct ExportConstant <: AbstractComponent
    value::Float64
end

struct ExportShockVariance <: AbstractComponent
    value::Float64
end

struct ImportAutoregressiveCoefficient <: AbstractComponent
    value::Float64
end

struct ImportConstant <: AbstractComponent
    value::Float64
end

struct ImportShockVariance <: AbstractComponent
    value::Float64
end

struct EuroAreaGDP <: AbstractComponent
    value::Float64
end

struct EuroAreaGrowth <: AbstractComponent
    value::Float64
end

struct EuroAreaInflation <: AbstractComponent
    value::Float64
end

struct EuroAreaInflationAR <: AbstractComponent
    value::Float64
end

struct EuroAreaInflationConstant <: AbstractComponent
    value::Float64
end

struct EuroAreaInflationShockVariance <: AbstractComponent
    value::Float64
end

struct EuroAreaGDPAR <: AbstractComponent
    value::Float64
end

struct EuroAreaGDPConstant <: AbstractComponent
    value::Float64
end

struct EuroAreaGDPShockVariance <: AbstractComponent
    value::Float64
end

struct NetForeignPosition <: AbstractComponent
    amount::Float64
end

struct ImportSupply <: AbstractComponent
    quantity::Float64
end

struct ExportDemand <: AbstractComponent
    quantity::Float64
end

struct ExportDemand <: AbstractComponent
    values::Float64
end

struct ImportSupply <: AbstractComponent
    values::VectorFloat64
end

struct ImportSales <: AbstractComponent
    values::Float64
end

struct ImportDemand <: AbstractComponent
    values::Float64
end

struct ImportPrice <: AbstractComponent
    values::Float64
end

struct ExportPriceInflation <: AbstractComponent
    value::Float64
end
