struct NominalInterestRate <: AbstractComponent
    rate::Float64
end

struct GovernmentBondInterestRate <: AbstractComponent
    rate::Float64
end

struct GradualAdjustmentRate <: AbstractComponent
    rate::Float64
end

struct EquilibriumInterestRate <: AbstractComponent
    rate::Float64
end

struct InflationTargetingWeight <: AbstractComponent
    weight::Float64
end

struct EconomicWeight <: AbstractComponent
    weight::Float64
end

struct CentralBankEquity <: AbstractComponent
    value::Float64
end
