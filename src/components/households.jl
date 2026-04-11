struct NetDisposableIncome <: AbstractComponent
    value::Float64
end

struct HouseholdDesposit <: AbstractComponent
    value::Float64
end

struct CapitalStock <: AbstractComponent
    value::Float64
end

struct ConsumptionBudget <: AbstractComponent
    amount::Float64
end

struct InvestmentBudget <: AbstractComponent
    amount::Float64
end

struct RealisedConsumption <: AbstractComponent
    amount::Float64
end

struct RealisedInvestment <: AbstractComponent
    amount::Float64
end
