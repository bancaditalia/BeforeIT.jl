@component struct NetDisposableIncome <: AbstractComponent
    amount::FloatType
end

@component struct ExpectedIncome <: AbstractComponent
    amount::FloatType
end

@component struct Deposits <: AbstractComponent
    amount::FloatType
end

@component struct CapitalStock <: AbstractComponent
    amount::FloatType
end

@component struct ConsumptionBudget <: AbstractComponent
    amount::FloatType
end

@component struct InvestmentBudget <: AbstractComponent
    amount::FloatType
end

@component struct RealisedConsumption <: AbstractComponent
    amount::FloatType
end

@component struct RealisedInvestment <: AbstractComponent
    amount::FloatType
end
@component struct Household <: AbstractComponent end
