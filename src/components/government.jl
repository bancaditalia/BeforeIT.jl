abstract type GovernmentComponent <: AbstractComponent end
@component struct GovernmentRevenues <: GovernmentComponent
    amount::Float64
end

@component struct SocialBenefitsInactive <: GovernmentComponent
    amount::Float64
end

@component struct SocialBenefitsOther <: GovernmentComponent
    amount::Float64
end

@component struct PriceInflationGovernmentGoods <: GovernmentComponent
    value::Float64
end

@component struct GovernmentDebt <: GovernmentComponent
    value::Float64
end

@component struct LocalGovernment <: GovernmentComponent end
