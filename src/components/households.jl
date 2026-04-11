@component struct NetDisposableIncome <: AbstractComponent
    value::Float64
end

@component struct HouseholdDesposit <: AbstractComponent
    value::Float64
end

@component struct CapitalStock <: AbstractComponent
    value::Float64
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
