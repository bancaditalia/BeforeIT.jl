@component struct NetDisposableIncome <: AbstractComponent
    amount::Float64
end

@component struct ExpectedIncome <: AbstractComponent
    amount::Float64
end

@component struct Deposits <: AbstractComponent
    amount::Float64
end

@component struct CapitalStock <: AbstractComponent
    amount::Float64
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
