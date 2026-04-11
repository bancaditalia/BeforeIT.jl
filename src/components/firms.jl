abstract type FirmComponent <: AbstractComponent end
struct PrincipalProduct <: FirmComponent
    id::Int64
end

struct LaborProductivity <: FirmComponent
    value::Float64
end

struct IntermediateProductivity <: FirmComponent
    value::Float64
end

struct CapitalProductivity <: FirmComponent
    value::Float64
end

struct CapitalDepreciationRate <: FirmComponent
    rate::Float64
end

struct OperatingMargins <: FirmComponent
    margin::Float64
end

struct WageBill <: FirmComponent
    amount::Float64
end

struct AverageWageRate <: FirmComponent
    rate::Float64
end

struct OutputTaxRate <: FirmComponent
    rate::Float64
end

struct CapitalTaxRate <: FirmComponent
    rate::Float64
end

struct Price <: FirmComponent
    value::Float64
end

struct PriceIndex <: FirmComponent
    value::Float64
end

struct CFPriceIndex <: FirmComponent
    value::Float64
end

struct Employment <: FirmComponent
    count::Int
end

struct Vacancies <: FirmComponent
    count::Int
end

struct DesiredEmployment <: FirmComponent
    count::Int
end

struct Output <: FirmComponent
    quantity::Float64
end

struct Sales <: FirmComponent
    quantity::Float64
end

struct GoodsDemand <: FirmComponent
    quantity::Float64
end

struct Inventories <: FirmComponent
    quantity::Float64
end

struct Capital <: FirmComponent
    quantity::Float64
end
struct Intermediates <: FirmComponent

    quantity::Float64
end

struct Investment <: FirmComponent
    quantity::Float64
end

struct Deposits <: FirmComponent
    amount::Float64
end

struct Equity <: FirmComponent
    amount::Float64
end

struct FinalGoodsStockChange <: FirmComponent
    quantity::Float64
end

struct MaterialsStockChange <: FirmComponent
    quantity::Float64
end

struct TargetLoans <: FirmComponent
    amount::Float64
end

struct ExpectedCapital <: FirmComponent
    quantity::Float64
end

struct ExpectedLoans <: FirmComponent
    amount::Float64
end

struct ExpectedSales <: FirmComponent
    quantity::Float64
end

struct DesiredInvestment <: FirmComponent
    quantity::Float64
end

struct DesiredMaterials <: FirmComponent
    quantity::Float64
end
