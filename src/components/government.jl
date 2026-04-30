abstract type GovernmentComponent <: AbstractComponent end

@component struct GovernmentRevenues <: GovernmentComponent #Y_G
    amount::FloatType
end

@component struct SocialBenefitsInactive <: GovernmentComponent #sb_inact
    amount::FloatType
end

@component struct SocialBenefitsOther <: GovernmentComponent #sb_other
    amount::FloatType
end

@component struct PriceInflationGovernmentGoods <: GovernmentComponent #P_j
    value::FloatType
end

@component struct GovernmentDebt <: GovernmentComponent #L_G
    amount::FloatType
end

@component struct ConsumptionDemand <: GovernmentComponent #C_G
    amount::FloatType
end

@component struct LocalGovernment <: Ark.Relationship end
@component struct Government <: GovernmentComponent end
