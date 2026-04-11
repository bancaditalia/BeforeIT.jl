struct GovernmentConsumptionAutoregressiveCoefficient <: AbstractComponent
    coeff::Float64

struct GovernmentConsumptionVarianceCoefficient <: AbstractComponent
    coeff::Float64
end

struct GovernmentRevenues <: AbstractComponent
    amount::Float64
end

struct SocialBeneditsInactive <: AbstractComponent
  amount::Float64
end

struct SocialBeneditsAll <: AbstractComponent
  amount::Float64
end

struct PriceInflationGovernmentGoods <: AbstractComponent
  value::Float64
end

