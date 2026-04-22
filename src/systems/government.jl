function set_gov_expenditure!(world::Ark.World)
    properties = Ark.get_resource(world, Properties)
    expectations = Ark.get_resource(world, Expectations)
    price_indices = Ark.get_resource(world, PriceIndices)

    c_G_g = properties.product_coefficients.government_consumption
    P_bar_g = price_indices.sector
    pi_e = expectations.inflation

    local_governments = properties.dimensions.local_governments
    (; consumption_autoregression, consumption_autoregression_scalar, consumption_shock_sd) = properties.fiscal_policy
    epsilon_G = consumption_shock_sd .* randn()

    nominal_sector_demand = dot(P_bar_g, c_G_g)
    for (gov_e, government_consumption) in Ark.Query(world, (Components.ConsumptionDemand,), with = (Components.Government,))
        for i in eachindex(gov_e)

            government_consumption[i] .= Components.ConsumptionDemand(exp(consumption_autoregression .* log(government_consumption[i].amount) + consumption_autoregression_scalar + epsilon_G))
            for (_, local_gov_consumption) in Ark.Query(world, (Components.ConsumptionDemand), relations = (Components.LocalGovernment => gov_e[i]))
                local_gov_consumption.amount .= government_consumption[i].amount ./ local_governments .* nominal_sector_demand .* (1 .+ pi_e)
            end
        end

    end

    return nothing
end


function set_gov_revenues!(world::Ark.World)

    properties = Ark.get_resource(world, Properties)

    taxes = properties.tax_rates
    τ_income = taxes.income
    τ_corp = taxes.corporate
    τ_vat = taxes.value_added
    τ_firm = taxes.corporate
    τ_cf = taxes.capital_goods
    θ_div = properties.banking_params.dividend_payout_ratio


    (;
        employers_contribution,
        employees_contribution,
    ) = properties.social_insurance

    cpi = Ark.get_resource(world, PriceIndices).household_consumption

    total_wages = @sum_over (w.rate for (_, w) in Ark.Query(world, (Components.Employed,)))
    total_consumption = @sum_over (c.amount for (_, c) in Ark.Query(world, (Components.RealisedConsumption,)))
    total_investment = @sum_over (c.amount for (_, c) in Ark.Query(world, (Components.RealisedInvestment,)))
    total_profits = @sum_over (max(0, p.amount) for (_, p) in Ark.Query(world, (Components.Profits,)))

    social_security = (employees_contribution + employers_contribution) * total_wages * cpi
    labor_income = τ_income * (1 - employees_contribution) * cpi * total_wages
    value_added = τ_vat * total_consumption
    capital_income = τ_income * (1 - τ_firm) * θ_div * total_profits
    corporate_income = τ_firm * total_profits
    capital_formation = τ_cf * total_investment
    products = @sum_over(y.amount * p.value * τ.rate for (_, y, p, τ) in Ark.Query(world, (Components.Output, Components.Price, Components.OutputTaxRate)))
    production = @sum_over(y.amount * p.value * τ.rate for (_, y, p, τ) in Ark.Query(world, (Components.Output, Components.Price, Components.CapitalTaxRate)))

    for (e, government_revenues) in Ark.Query(world, (Components.GovernmentRevenues,))
        for i in eachindex(e)
            government_revenues[i] = Components.GovernmentRevenues(social_security + labor_income + value_added + capital_income + capital_formation + products + production)
        end
    end
    return nothing
end

function set_gov_loans!(world::Ark.World)
    cpi = Ark.get_resource(world, PriceIndices).household_consumption
    properties = Ark.get_resource(world, Properties)
    (; active, total, inactive) = properties.population
    theta_UB = properties.social_insurance.unemployment_benefit
    r_g = properties.fiscal_policy.government_interest_rate
  (_,r_g) = sinlge(Ark.Query(world, (Components.  )))

    total_wages_unemployed = @sum_over (w.unemployment_benefits for (_, w) in Ark.Query(world, (Components.Unemployed,)))
    for (e, sb_inactive, sb_other, debt, realised_consumption, revenues, debt) in Ark.Query(world, (Components.SocialBenefitsInactive, Components.SocialBenefitsOther, Components.GovernmentDebt, Components.RealisedConsumption, Components.GovernmentRevenues, Components.GovernmentDebt))
        for i in eachindex(e)
            social_benefits = cpi * (inactive * sb_inactive[i].amount + theta_UB * total_wages_unemployed + total * sb_other[i].amount)
            debt[i] = Components.GovernmentDebt(social_benefits + realised_consumption[i].amount + r_G * debt[i].amount - revenues[i].amount)
        end
    end


    return nothing
end

function set_gov_social_benefits!(world::Ark.World)
    expected_growth = Ark.get_resource(world, Expectations).growth

    for (e, sb_inactive, sb_other) in Ark.Query(world, (Components.SocialBenefitsInactive, Components.SocialBenefitsOther, Components.GovernmentDebt))
        sb_inactive.amount .*= (1 + expected_growth) 
        sb_other.amount .*= (1 + expected_growth) 
        
    end
  
end
