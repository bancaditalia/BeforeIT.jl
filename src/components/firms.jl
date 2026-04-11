abstract type FirmComponent <: AbstractComponent end
@component struct PrincipalProduct <: FirmComponent
    id::Int64
end

@component struct LaborProductivity <: FirmComponent
    value::Float64
end

@component struct IntermediateProductivity <: FirmComponent
    value::Float64
end

@component struct CapitalProductivity <: FirmComponent
    value::Float64
end

@component struct CapitalDeprecationRate <: FirmComponent
    rate::Float64
end

@component struct OperatingMargins <: FirmComponent
    margin::Float64
end

@component struct WageBill <: FirmComponent
    amount::Float64
end

@component struct AverageWageRate <: FirmComponent
    rate::Float64
end

@component struct OutputTaxRate <: FirmComponent
    rate::Float64
end

@component struct CapitalTaxRate <: FirmComponent
    rate::Float64
end

@component struct Price <: FirmComponent
    value::Float64
end

@component struct PriceIndex <: FirmComponent
    value::Float64
end

@component struct CFPriceIndex <: FirmComponent
    value::Float64
end

@component struct Employment <: FirmComponent
    count::Int
end

@component struct Vacancies <: FirmComponent
    count::Int
end

@component struct DesiredEmployment <: FirmComponent
    count::Int
end

@component struct Output <: FirmComponent
    quantity::Float64
end

@component struct Sales <: FirmComponent
    quantity::Float64
end

@component struct GoodsDemand <: FirmComponent
    quantity::Float64
end

@component struct Inventories <: FirmComponent
    quantity::Float64
end

@component struct Capital <: FirmComponent
    quantity::Float64
end
@component struct Intermediates <: FirmComponent

    quantity::Float64
end

@component struct Investment <: FirmComponent
    quantity::Float64
end

@component struct Deposits <: FirmComponent
    amount::Float64
end

@component struct Equity <: FirmComponent
    amount::Float64
end

@component struct FinalGoodsStockChange <: FirmComponent
    quantity::Float64
end

@component struct MaterialsStockChange <: FirmComponent
    quantity::Float64
end

@component struct TargetLoans <: FirmComponent
    amount::Float64
end

@component struct ExpectedCapital <: FirmComponent
    quantity::Float64
end

@component struct ExpectedLoans <: FirmComponent
    amount::Float64
end

@component struct ExpectedSales <: FirmComponent
    quantity::Float64
end

@component struct DesiredInvestment <: FirmComponent
    quantity::Float64
end

@component struct DesiredMaterials <: FirmComponent
    quantity::Float64
end

@component struct Owner <: FirmComponent
    entity::Ark.Entity
end

@component struct Capitalist <: FirmComponent end
