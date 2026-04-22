function setup_bank!(world::Ark.World, properties::Properties)
    (; equity_ratio, policy_rate) = properties.initial_conditions.banking
    risk_premium = properties.banking_params.risk_premium
    owner = Ark.new_entity!(
        world,
        (
            Components.NetDisposableIncome(0.0),
            Components.ConsumptionBudget(0.0),
            Components.ExpectedIncome(0.0),
            Components.InvestmentBudget(0.0),
            Components.RealisedConsumption(0.0),
            Components.RealisedInvestment(0.0),
            Components.CapitalStock(0.0),
            Components.Deposits(0.0),
            Components.Banker(),
            Components.Household(),
        )
    )
    Ark.new_entity!(
        world, (
            Components.EquityCapital(equity_ratio),
            Components.ResidualItems(0.0),
            Components.Profits(0.0),
            Components.ExpectedProfits(0.0),
            Components.LendingRate(policy_rate + risk_premium),
            Components.Owner(),
        ),
        relations = (Components.Owner => owner)
    )

    return nothing

end

function setup_central_bank!(world::Ark.World, properties::Properties)
    (; central_bank_equity, policy_rate) = properties.initial_conditions.banking
    return Ark.new_entity!(
        world, (
            Components.CentralBankEquity(central_bank_equity),
            Components.NominalInterestRate(policy_rate),
        )
    )
end
