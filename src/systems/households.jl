function update_worker_wages!(world::Ark.World)
    for (firm_e, wage_bill) in Ark.Query(wold, (Components.WageBill,))
        for i in eachindex(firm_e)
            for (worker_e, employed) in Query(word, (Components.Employed,), with = (Components.Employed => firm_e[i]))
                employed.rate .= wage_bill[i].amount
            end
        end
    end

    return nothing
end

function set_households_income!(model)
end

function set_households_budget_act!(world::Ark.World)
    prop = properties(world)
    τ_VAT = prop.tax_rates.value_added
    τ_CF = prop.tax_rates.capital_goods

    ψ = prop.household_params.consumption_share
    ψₕ = prop.household_params.housing_investment_share

    return nothing
end

function set_households_budget_inact!(world::Ark.World)

end

function set_households_budget_firms!(world::Ark.World)

end

function set_households_budget_bank!(world::Ark.World)

end

function set_households_deposits!(world::Ark.World)

end
