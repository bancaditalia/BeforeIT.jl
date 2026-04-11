struct ECSModel
    world::Ark.World
end

function ECSModel(properties::Properties)
    world = Ark.World(Components.COMPONENTS...)

    setup_firms!(world, properties)
    setup_workers!(world, properties)
    setup_bank!(world, properties)
    setup_central_bank!(world, properties)
    setup_government!(world, properties)
    setup_rotw!(world, properties)
    setup_agg!(world, properties)


    Ark.add_resource!(world, properties)

    return ECSModel(world)
end

function setup_firms!(world, properties::Properties)
    total_firms = properties.dimensions.total_firms
    firms_per_sector = properties.dimensions.firms_per_sector


    tau_SIF = properties.social_insurance.employers_contribution
    mu = properties.banking.risk_premium
    theta_DIV = properties.banking.dividend_payout_ratio

    tau_INC = properties.tax_rates.income
    tau_FIRM = properties.tax_rates.corporate

    sb_other = properties.initial_conditions.government.subsidies_other
    r_bar = properties.initial_conditions.banking.policy_rate

    D_I = properties.initial_conditions.firms.total_debt
    L_I = properties.initial_conditions.firms.total_loan

    omega = properties.initial_conditions.firms.capacity_utilization

    D_H = properties.initial_conditions.households.debt
    K_H = properties.initial_conditions.households.capital

    sectoral_employment = round.(Int, properties.initial_conditions.sectors.employment)
    principal_product = reduce(vcat, [fill(g, firms_per_sector[g]) for g in 1:properties.dimensions.sectors])

    sectoral_params = properties.sectoral_params

    output_elasticities = sectoral_params.output_elasticity[principal_product]
    material_coeffs = sectoral_params.material_coefficient[principal_product]
    capital_coeffs = sectoral_params.capital_coefficient[principal_product]
    deprectation_rate = sectoral_params.depreciation_rate[principal_product]
    wage_rate = sectoral_params.wage_rate[principal_product]

    output_tax_rate = properties.sector_tax_rates.output[principal_product]
    capital_tax_rate = properties.sector_tax_rates.capital[principal_product]

    employment = Vector{Int}(undef, total_firms)
    for g in 1:G
        employment[principal_product .== g] .= randpl(firms_per_sector[g], 2.0, N_s[g])
    end

    output = output_elasticities .* employment


    capital = output ./ (omega .* material_coeffs)
    intermediates = output ./ (omega .* capital_coeffs)
    outstanding_loans = L_I .* capital / sum(capital)

    operating_margins = 1 .- (1 + tau_SIF) .* wage_rate ./ output_elasticities .- deprectation_rate ./ capital_coeffs .- 1 ./ material_coeffs .- capital_tax_rate .- output_tax_rate
    deposits = D_I .* max.(0, operating_margins .* output) / sum(max.(0, operating_margins .* output))

    r = r_bar + mu
    profits = operating_margins .* output - r .* outstanding_loans + r_bar .* max.(0, deposits)


    P_bar_HH = one(Float64)
    after_tax_profits = max.(0, profits) .* (1 - tau_INC) .* (1 - tau_FIRM)
    dividends = theta_DIV .* after_tax_profits
    subsidies = sb_other * P_bar_HH
    Y_h = dividends .+ subsidies
    K_h = K_H * Y_h
    D_h = D_H * Y_h


    #TODO: Replace this with a batch entity creation
    for i in 1:total_firms
        Ark.new_entity!(
            world,
            (
                Components.PrincipalProduct(principal_product[i]),
                Components.LaborProductivity(output_elasticities[i]),
                Components.IntermediateProductivity(material_coeffs[i]),
                Components.CapitalProductivity(capital_coeffs[i]),
                Components.WageBill(0.0),
                Components.AverageWageRate(wage_rate[i]),
                Components.CapitalDeprectationRate(deprectation_rate[i]),
                Components.OutputTaxRate(output_tax_rate[i]),
                Components.CapitalTaxRate(capital_tax_rate[i]),
                Components.Employment(employment[i]),
                Components.Output(output[i]),
                Components.Sales(output[i]),
                Components.GoodsDemand(output[i]),
                Components.Price(1.0),
                Components.Inventories(0.0),
                Components.Capital(capital[i]),
                Components.Intermediates(intermediates[i]),
                Components.LoansOutstanding(outstanding_loans[i]),
                Components.OperatingMargins(operating_margins[i]),
                Components.Deposits(deposits[i]),
                Components.Profits(profits[i]),
                Components.Vacancies(employment[i]),
                Components.Investment(0.0),
                Components.Equity(0.0),
                Components.PriceIndex(0.0),
                Components.CFPriceIndex(0.0),
                Components.TargetLoans(0.0),
                Components.ExpectedCapital(0.0),
                Components.ExpectedLoans(0.0),
                Components.ExpectedSales(0.0),
                Components.DesiredInvestment(0.0),
                Components.DesiredMaterials(0.0),
                Components.DesiredEmployment(0.0),
                Components.ExpectedProfits(0.0),

                #=
- `DS_i`: Differnece in stock of final goods
- `DM_i`: Difference in stock of intermediate goods
- `DL_i`: Obtained loans
=#
            )
        )
    end

    return nothing

end
