@component struct NominalInterestRate <: AbstractComponent
    rate::Float64
end

@component struct GovernmentBondInterestRate <: AbstractComponent
    rate::Float64
end

@component struct GradualAdjustmentRate <: AbstractComponent
    rate::Float64
end

@component struct EquilibriumInterestRate <: AbstractComponent
    rate::Float64
end

@component struct InflationTargetingWeight <: AbstractComponent
    weight::Float64
end

@component struct EconomicWeight <: AbstractComponent
    weight::Float64
end

@component struct CentralBankEquity <: AbstractComponent
    value::Float64
end
