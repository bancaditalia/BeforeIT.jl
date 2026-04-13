function setup_workers!(world::Ark.World, properties::Properties)
    (; active, inactive, total) = properties.population
    unemployment_benefit_rate = properties.social_insurance.unemployment_benefit
    (; subsidies_other, subsidies_inactive) = properties.initial_conditions.government
    (; debt, capital, unemployment_benefit) = properties.initial_conditions.households

    total_firms = properties.dimensions.total_firms

    employable = active - total_firms - 1

    Ark.new_entities!(
        world, employable, (
            Components.NetDisposableIncome(0.0),
            Components.Deposits(0.0),
            Components.CapitalStock(0.0),
            Components.Unemployed(unemployment_benefit / unemployment_benefit_rate),
            Components.ConsumptionBudget(0.0),
            Components.InvestmentBudget(0.0),
            Components.RealisedConsumption(0.0),
            Components.RealisedInvestment(0.0),
        )
    )

    disposable_income = subsidies_other + subsidies_inactive
    Ark.new_entities!(
        world, inactive, (
            Components.NetDisposableIncome(disposable_income),
            Components.Deposits(debt * disposable_income),
            Components.CapitalStock(capital * disposable_income),
            Components.Inactive(),
            Components.ConsumptionBudget(0.0),
            Components.InvestmentBudget(0.0),
            Components.RealisedConsumption(0.0),
            Components.RealisedInvestment(0.0),
        )
    )

    return nothing
end
