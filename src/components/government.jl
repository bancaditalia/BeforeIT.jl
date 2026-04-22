abstract type GovernmentComponent <: AbstractComponent end

@component struct GovernmentRevenues <: GovernmentComponent #Y_G
    amount::Float64
end

@component struct SocialBenefitsInactive <: GovernmentComponent #sb_inact
    amount::Float64
end

@component struct SocialBenefitsOther <: GovernmentComponent #sb_other
    amount::Float64
end

@component struct PriceInflationGovernmentGoods <: GovernmentComponent #P_j
    value::Float64
end

@component struct GovernmentDebt <: GovernmentComponent #L_G
    value::Float64
end

@component struct ConsumptionDemand <: GovernmentComponent #C_G
    value::Float64
end

@component struct LocalGovernment <: GovernmentComponent end
@component struct Government <: GovernmentComponent end
