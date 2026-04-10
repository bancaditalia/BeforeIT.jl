struct ExportAutoregressiveCoefficient
    value::Float64
end

struct ExportConstant
    value::Float64
end

struct ExportShockVariance
    value::Float64
end

struct ImportAutoregressiveCoefficient
    value::Float64
end

struct ImportConstant
    value::Float64
end

struct ImportShockVariance
    value::Float64
end

struct EuroAreaGDP
    value::Float64
end

struct EuroAreaGrowth
    value::Float64
end

struct EuroAreaInflation
    value::Float64
end

struct EuroAreaInflationAR
    value::Float64
end

struct EuroAreaInflationConstant
    value::Float64
end

struct EuroAreaInflationShockVariance
    value::Float64
end

struct EuroAreaGDPAR
    value::Float64
end

struct EuroAreaGDPConstant
    value::Float64
end

struct EuroAreaGDPShockVariance
    value::Float64
end

struct NetForeignPosition
    amount::Float64
end

struct ImportSupply
    quantity::Float64
end

struct ExportDemand
    quantity::Float64
end

struct ExportDemand
    values::Float64
end

struct ImportSupply
    values::VectorFloat64
end

struct ImportSales
    values::Float64
end

struct ImportDemand
    values::Float64
end

struct ImportPrice
    values::Float64
end

struct ExportPriceInflation
    value::Float64
end
