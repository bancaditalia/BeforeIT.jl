function update_worker_wages!(world::Ark.World)
    for (firm_e, wage_bill) in Ark.Query(world, (Components.WageBill,))
        for i in eachindex(firm_e)
            for (worker_e, employed) in Query(word, (Components.Employed,), with = (Components.Employed => firm_e[i]))
                employed.rate .= wage_bill[i].amount
            end
        end
    end

    return nothing
end

function employed_worker_income(wage, τ_SIW, τ_INC, social_benefits_other, cpi, expected_inflation)
    return wage * (1.0 - τ_SIW - τ_INC * (1.0 - τ_SIW) + social_benefits_other) * cpi * (1.0 + expected_inflation)
end

function unemployed_worker_income(benefits, θ_UB, social_benefits_other, cpi, expected_inflation)
    return (θ_UB * benefits + social_benefits_other) * cpi * (1.0 + expected_inflation)
end

function inactive_worker_income(sb_inact, sb_other, cpi, expected_inflation)
    return (sb_inact + sb_other) * cpi * (1.0 + expected_inflation)
end

function firm_owner_disposable_income(θ_DIV, τ_INC, τ_FIRM, cpi, sb_other, expected_profits, expected_inflation)
    return θ_DIV * (1 - τ_INC) * (1 - τ_FIRM) * max(0, expected_profits) + sb_other * cpi * (1 + expected_inflation)
end


function set_households_income!(world::Ark.World)
    prop = properties(world)
    τ_INC = prop.tax_rates.income
    τ_SIW = prop.social_insurance.employees_contribution
    τ_FIRM = prop.tax_rates.corporate
    θ_DIV = prop.banking_params.dividend_payout_ratio


    θ_UB = prop.social_insurance.unemployment_benefit
    cpi = price_indices(world).household_consumption
    (_, sb_other, sb_inact) = single(Ark.Query(world, (Components.SocialBenefitsOther, Components.SocialBenefitsInactive)))

    expected_inflation = expectations(world).inflation

    for (_, employment, net_disposable_income, expected_income) in Ark.Query(world, (Components.Employed, Components.NetDisposableIncome, Components.ExpectedIncome))
        net_disposable_income.amount .= employed_worker_income.(employment.rate, τ_SIW, τ_INC, sb_other.amount, cpi, 0.0)
        expected_income.amount .= employed_worker_income.(employment.rate, τ_SIW, τ_INC, sb_other.amount, cpi, expected_inflation)
    end

    for (_, unemployed, net_disposable_income, expected_income) in Ark.Query(world, (Components.Unemployed, Components.NetDisposableIncome, Components.ExpectedIncome))
        net_disposable_income.amount .= unemployed_worker_income.(unemployed.unemployment_benefit, θ_UB, sb_other.amount, cpi, 0.0)
        expected_income.amount .= unemployed_worker_income.(unemployed.unemployment_benefit, θ_UB, sb_other.amount, cpi, expected_inflation)
    end

    for (_, net_disposable_income, expected_income) in Ark.Query(world, (Components.NetDisposableIncome, Components.ExpectedIncome), with = (Components.Inactive,))
        net_disposable_income.amount .= inactive_worker_income(sb_inact.amount, sb_other.amount, cpi, 0.0)
        expected_income.amount .= inactive_worker_income(sb_inact.amount, sb_other.amount, cpi, expected_inflation)
    end

    for (e_owner, net_disposable_income, expected_income) in Ark.Query(world, (Components.NetDisposableIncome, Components.ExpectedIncome), without = (Components.Employed, Components.Unemployed, Components.Inactive))
        for i in eachindex(e_owner)
            (_, profits, expected_profits) = single(Ark.Query(world, (Components.Profits, Components.ExpectedProfits), relationship = (Components.Owner => e_owner[i])))
            net_disposable_income[i] = Components.NetDisposableIncome(firm_owner_disposable_income(θ_DIV, τ_INC, τ_FIRM, cpi, sb_other, profits.amount, 0.0))
            expected_income[i] = Components.ExpectedIncome(firm_owner_disposable_income(θ_DIV, τ_INC, τ_FIRM, cpi, sb_other, expected_profits.amount, expected_inflation))
        end
    end

    return nothing
end

function set_households_budget!(world::Ark.World)
    prop = properties(world)
    τ_VAT = prop.tax_rates.value_added
    τ_CF = prop.tax_rates.capital_formation

    ψ = prop.household_params.consumption_share
    ψₕ = prop.household_params.housing_investment_share

    for (_, expected_income, consumption_budget, investment_budget) in Ark.Query(world, (Components.ExpectedIncome, Components.ConsumptionBudget, Components.InvestmentBudget))
        consumption_budget.amount .= ψ .* expected_income.amount ./ (1 + τ_VAT)
        investment_budget.amount .= ψₕ .* expected_income.amount ./ (1 + τ_CF)
    end

    return nothing
end

function set_households_deposits!(world::Ark.World)

    prop = properties(world)
    τ_VAT = prop.tax_rates.value_added
    τ_CF = prop.tax_rates.capital_formation

    (_, r_bar) = single(Ark.Query(world, (Components.NominalInterestRate,)))
    (_, r) = single(Ark.Query(world, (Components.LendingRate,)))

    for (_, net_disposable_income, realised_consumption, realised_investment, deposits) in Ark.Query(world, (Components.NetDisposableIncome, Components.RealisedConsumption, Components.RealisedInvestment, Components.Deposits))
        deposits.amount .+= net_disposable_income.amount
        .- (1 + τ_VAT) .* realised_consumption.amount
        .- (1 + τ_CF) .* realised_investment
        .+ r_bar .* max.(0.0, deposits.amount) .+ r .* min.(0.0, deposits.amount)
    end


    return nothing
end
