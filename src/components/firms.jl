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
    rate::Float64
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
    amount::Int
end

@component struct Vacancies <: FirmComponent
    amount::Int
end

@component struct DesiredEmployment <: FirmComponent
    amount::Int
end

@component struct Output <: FirmComponent
    amount::Float64
end

@component struct Sales <: FirmComponent
    amount::Float64
end

@component struct GoodsDemand <: FirmComponent
    amount::Float64
end

@component struct Inventories <: FirmComponent
    amount::Float64
end

@component struct Intermediates <: FirmComponent
    amount::Float64
end

@component struct Investment <: FirmComponent
    amount::Float64
end

@component struct Equity <: FirmComponent
    amount::Float64
end

@component struct FinalGoodsStockChange <: FirmComponent
    amount::Float64
end

@component struct MaterialsStockChange <: FirmComponent
    amount::Float64
end

@component struct TargetLoans <: FirmComponent
    amount::Float64
end

@component struct ExpectedCapital <: FirmComponent
    amount::Float64
end

@component struct ExpectedLoans <: FirmComponent
    amount::Float64
end

@component struct ExpectedSales <: FirmComponent
    amount::Float64
end

@component struct DesiredInvestment <: FirmComponent
    amount::Float64
end

@component struct DesiredMaterials <: FirmComponent
    amount::Float64
end

@component struct Owner <: FirmComponent
    entity::Ark.Entity
end

@component struct Capitalist <: FirmComponent end
