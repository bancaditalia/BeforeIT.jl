@component struct NominalInterestRate <: AbstractComponent
    rate::FloatType
end

@component struct GovernmentBondInterestRate <: AbstractComponent
    rate::FloatType
end

@component struct GradualAdjustmentRate <: AbstractComponent
    rate::FloatType
end

@component struct EquilibriumInterestRate <: AbstractComponent
    rate::FloatType
end

@component struct InflationTargetingWeight <: AbstractComponent
    weight::FloatType
end

@component struct EconomicWeight <: AbstractComponent
    weight::FloatType
end

@component struct CentralBank <: AbstractComponent end
