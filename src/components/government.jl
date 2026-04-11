@component struct GovernmentConsumptionAutoregressiveCoefficient <: AbstractComponent
    coeff::Float64
end

@component struct GovernmentConsumptionVarianceCoefficient <: AbstractComponent
    coeff::Float64
end

@component struct GovernmentRevenues <: AbstractComponent
    amount::Float64
end

@component struct SocialBeneditsInactive <: AbstractComponent
    amount::Float64
end

@component struct SocialBeneditsAll <: AbstractComponent
    amount::Float64
end

@component struct PriceInflationGovernmentGoods <: AbstractComponent
    value::Float64
end
