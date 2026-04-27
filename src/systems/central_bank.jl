function taylor_rule(adjustment_rate, interest_rate, natural_rate, inflation_target, inflation_weight, growth_weigth, output_growth_rate, inflation_rate)
    rate = muladd(adjustment_rate, interest_rate, (1.0 - adjustment_rate) * (natural_rate + inflation_target + inflation_weight * (inflation_rate - inflation_target) + growth_weigth * output_growth_rate))
    return max(0.0, rate)
end

function set_central_bank_rate!(world)
    properties = Ark.get_resource(world, Properties)

    (; inflation_target, interest_rate_smoothing, response_to_inflation, response_to_output, natural_rate) = properties.monetary_policy


    (e, growth, inflation) = single(Ark.Query(world, (Components.EuroAreaGrowth, Components.EuroAreaInflation)))
    rotw_growth = growth.rate
    rotw_inflation = inflation.rate

    for (e, interest_rate) in Ark.Query(world, (Components.NominalInterestRate,))
        @inbounds for i in eachindex(e)
            interest_rate[i] = Components.NominalInterestRate(
                taylor_rule(interest_rate_smoothing, interest_rate[i].rate, natural_rate, inflation_target, response_to_inflation, response_to_output, rotw_growth, rotw_inflation)
            )
        end
    end

    return
end

function set_central_bank_equity!(world)
    properties = Ark.get_resource(world, Properties)
    government_interest_rate = properties.fiscal_policy.government_interest_rate
    total_government_debt = @sum_over (government_debt.amount for government_debt in Ark.Query(world, (Components.GovernmentDebt,)))
    total_banking_residuals = @sum_over (residual.amount for residual in Ark.Query(world, (Components.ResidualItems,)))

    for (e, equity, interest_rate) in Ark.Query(world, (Components.CentralBankEquity, Components.NominalInterestRate))
        for i in eachindex(e)
            profits = government_interest_rate * total_government_debt - interest_rate[i].rate * total_banking_residuals
            equity[i] = Components.CentralBankEquity(
                equity[i].value + profits
            )
        end
    end

    return nothing

end
