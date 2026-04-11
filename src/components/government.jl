@component struct GovernmentRevenues <: AbstractComponent
    amount::Float64
end

@component struct SocialBenefitsInactive <: AbstractComponent
    amount::Float64
end

@component struct SocialBenefitsOther <: AbstractComponent
    amount::Float64
end

@component struct PriceInflationGovernmentGoods <: AbstractComponent
    value::Float64
end

@component struct GovernmentDebt <: AbstractComponent
    value::Float64
end

@component struct LocalGovernment end
