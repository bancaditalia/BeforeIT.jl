function set_gov_expenditure!(world::Ark.World)
    prop = properties(world)
    expect = expectations(world)
    price_indices = BeforeIT.price_indices(world)

    c_G_g = prop.product_coeffs.government_consumption
    P_bar_g = price_indices.sector
    pi_e = expect.inflation

    local_governments = prop.dimensions.local_governments
    (; consumption_autoregression, consumption_autoregression_scalar, consumption_shock_sd) = prop.fiscal_policy
    epsilon_G = consumption_shock_sd .* randn()

    nominal_sector_demand = dot(P_bar_g, c_G_g)
    for (gov_e, government_consumption) in Ark.Query(world, (Components.ConsumptionDemand,), with = (Components.Government,))
        for i in eachindex(gov_e)

            government_consumption[i] = Components.ConsumptionDemand(
                exp(consumption_autoregression .* log(government_consumption[i].amount) + consumption_autoregression_scalar + epsilon_G)
            )
            for (_, local_gov_consumption, _) in Ark.Query(world, (Components.ConsumptionDemand, Components.LocalGovernment), relations = (Components.LocalGovernment => gov_e[i],))
                local_gov_consumption.amount .= government_consumption[i].amount ./ local_governments .* nominal_sector_demand .* (1 .+ pi_e)
            end
        end

    end

    return nothing
end


function set_gov_revenues!(world::Ark.World)

    prop = properties(world)

    taxes = prop.tax_rates
    τ_income = taxes.income
    τ_vat = taxes.value_added
    τ_firm = taxes.corporate
    τ_cf = taxes.capital_formation
    θ_div = prop.banking_params.dividend_payout_ratio

    (;
        employers_contribution,
        employees_contribution,
    ) = prop.social_insurance

    cpi = Ark.get_resource(world, PriceIndices).household_consumption

    total_wages = @sum_over (w.rate for  w in Ark.Query(world, (Components.Employed,)))
    total_consumption = @sum_over (c.amount for c in Ark.Query(world, (Components.RealisedConsumption,)))
    total_investment = @sum_over (c.amount for c in Ark.Query(world, (Components.RealisedInvestment,)))
    total_profits = @sum_over (max(0, p.amount) for p in Ark.Query(world, (Components.Profits,)))

    social_security = (employees_contribution + employers_contribution) * total_wages * cpi
    labor_income = τ_income * (1 - employees_contribution) * cpi * total_wages
    value_added = τ_vat * total_consumption
    capital_income = τ_income * (1 - τ_firm) * θ_div * total_profits
    corporate_income = τ_firm * total_profits
    capital_formation = τ_cf * total_investment
    products = 0.0
    production = 0.0
    for (e, y, p, τ_prod, τ_capital) in Ark.Query(world, (Components.Output, Components.Price, Components.OutputTaxRate, Components.CapitalTaxRate))
        products += sum(y.amount .* p.value .* τ_prod.rate)
        production += sum(y.amount .* p.value .* τ_capital.rate)
    end

    τ_export = prop.tax_rates.exports # or matching property name
    exports = @sum_over (
        x.amount for x in Ark.Query(world, (Components.ForeignConsumption,))
    )

    export_tax = τ_export * exports


    for (e, government_revenues) in Ark.Query(world, (Components.GovernmentRevenues,))
        for i in eachindex(e)
            government_revenues[i] = Components.GovernmentRevenues(
                social_security
                    + labor_income
                    + value_added
                    + capital_income
                    + capital_formation
                    + products
                    + production
                    + corporate_income
                    + export_tax
            )
        end
    end
    return nothing
end

function set_gov_loans!(world::Ark.World)
    cpi = Ark.get_resource(world, PriceIndices).household_consumption
    properties = Ark.get_resource(world, Properties)
    (; total, inactive) = properties.population
    theta_UB = properties.social_insurance.unemployment_benefit
    r_g = properties.fiscal_policy.government_interest_rate

    total_wages_unemployed = @sum_over (w.unemployment_benefits for  w in Ark.Query(world, (Components.Unemployed,)))
    for (e, sb_inactive, sb_other, debt, realised_consumption, revenues) in Ark.Query(world, (Components.SocialBenefitsInactive, Components.SocialBenefitsOther, Components.GovernmentDebt, Components.RealisedConsumption, Components.GovernmentRevenues))
        for i in eachindex(e)
            social_benefits = cpi * (inactive * sb_inactive[i].amount + theta_UB * total_wages_unemployed + total * sb_other[i].amount)
            debt[i] = Components.GovernmentDebt(debt[i].amount + social_benefits + realised_consumption[i].amount + r_g * debt[i].amount - revenues[i].amount)
        end
    end


    return nothing
end

function set_gov_social_benefits!(world::Ark.World)
    expected_growth = BeforeIT.expectations(world).output_growth

    for (_, sb_inactive, sb_other) in Ark.Query(world, (Components.SocialBenefitsInactive, Components.SocialBenefitsOther, Components.GovernmentDebt))
        sb_inactive.amount .*= (1 + expected_growth)
        sb_other.amount .*= (1 + expected_growth)

    end
    return nothing
end
