@component struct NetDisposableIncome <: AbstractComponent
    amount::Float64
end

@component struct Deposits <: AbstractComponent
    amount::Float64
end

@component struct CapitalStock <: AbstractComponent
    amount::Float64
end

@component struct ConsumptionBudget <: AbstractComponent
    amount::Float64
end

@component struct InvestmentBudget <: AbstractComponent
    amount::Float64
end

@component struct RealisedConsumption <: AbstractComponent
    amount::Float64
end

@component struct RealisedInvestment <: AbstractComponent
    amount::Float64
end
@component struct Household <: AbstractComponent end
