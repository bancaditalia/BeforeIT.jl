@inline function precompute_sector_production_costs!(
        sector_production_cost::AbstractVector,
        technology_matrix::AbstractMatrix,
        sector_prices::AbstractVector,
    )
    mul!(sector_production_cost, transpose(technology_matrix), sector_prices)
    return nothing
end

@inline function expected_sales_amount(
        demand::Float64,
        growth::Float64,
    )
    return (1.0 + growth) * demand
end

@inline function desired_investment_amount(
        depreciation_rate::Float64,
        capital_productivity::Float64,
        expected_sales::Float64,
    )
    return depreciation_rate / capital_productivity * expected_sales
end

@inline function desired_materials_amount(
        capital_productivity::Float64,
        expected_sales::Float64,
    )
    return expected_sales / capital_productivity
end

@inline function desired_employment_amount(
        labor_productivity::Float64,
        expected_sales::Float64,
    )
    return max(1, round(Int64, expected_sales / labor_productivity))
end

@inline function expected_profit_amount(
        current_profit::Float64,
        growth::Float64,
        inflation::Float64,
    )
    return current_profit * (1.0 + growth) * (1.0 + inflation)
end

@inline function expected_deposits_amount(
        expected_profit::Float64,
        current_loans::Float64,
        debt_installment_rate::Float64,
        corporate_tax::Float64,
        dividend_payout_ratio::Float64,
    )
    positive_profit = max(0.0, expected_profit)

    return expected_profit -
        debt_installment_rate * current_loans -
        corporate_tax * positive_profit -
        dividend_payout_ratio * (1.0 - corporate_tax) * positive_profit
end

@inline function expected_capital_amount(
        capital_goods_price_index::Float64,
        inflation::Float64,
        capital_stock::Float64,
    )
    return capital_goods_price_index * (1.0 + inflation) * capital_stock
end

@inline function expected_loans_amount(
        current_loans::Float64,
        debt_installment_rate::Float64,
    )
    return (1.0 - debt_installment_rate) * current_loans
end

@inline function target_loans_amount(
        expected_deposits::Float64,
        deposits::Float64,
    )
    return max(0.0, -expected_deposits - deposits)
end

@inline function labor_cost_component(wage, labor_productivity, employer_contribution, household_price, inv_price)
    return (1.0 + employer_contribution) * wage / labor_productivity * (household_price * inv_price - 1.0)
end
@inline function material_cost_component(intermediate_productivity, sector_production_cost, inv_price)
    return inv(intermediate_productivity) * (sector_production_cost * inv_price - 1.0)
end
@inline function capital_cost_component(depreciation_rate, capital_productivity, capital_goods_price, inv_price)
    return depreciation_rate / capital_productivity * (capital_goods_price * inv_price - 1.0)
end

@inline function compute_firm_cost_push_inflation(
        wage::Float64,
        employer_contribution::Float64,
        household_price::Float64,
        depreciation_rate::Float64,
        intermediate_productivity::Float64,
        labor_productivity::Float64,
        capital_productivity::Float64,
        capital_goods_price::Float64,
        sector_production_cost::Float64,
        inv_price::Float64,
    )
    labor_cost = labor_cost_component(
        wage, labor_productivity, employer_contribution, household_price, inv_price
    )

    material_cost = material_cost_component(
        intermediate_productivity, sector_production_cost, inv_price
    )

    capital_cost = capital_cost_component(
        depreciation_rate, capital_productivity, capital_goods_price, inv_price
    )

    return labor_cost + material_cost + capital_cost
end

@inline function compute_firm_expectation_scalars(
        demand::Float64,
        capital_stock::Float64,
        current_profit::Float64,
        current_loans::Float64,
        current_deposits::Float64,
        growth::Float64,
        inflation::Float64,
        depreciation_rate::Float64,
        labor_productivity::Float64,
        capital_productivity::Float64,
        intermediate_productivity::Float64,
        capital_goods_price::Float64,
        debt_installment_rate::Float64,
        dividend_payout_ratio::Float64,
        corporate_tax::Float64,
    )
    expected_sales = expected_sales_amount(
        demand, growth
    )

    capacity_constraint_sales = min(expected_sales, capital_stock * capital_productivity)

    desired_investment = desired_investment_amount(
        depreciation_rate, capital_productivity, capacity_constraint_sales
    )

    desired_materials = desired_materials_amount(
        intermediate_productivity, capacity_constraint_sales
    )

    desired_employment = desired_employment_amount(
        labor_productivity, capacity_constraint_sales
    )

    expected_profit = expected_profit_amount(
        current_profit, growth, inflation
    )

    expected_deposits = expected_deposits_amount(
        expected_profit,
        current_loans,
        debt_installment_rate,
        corporate_tax,
        dividend_payout_ratio,
    )

    expected_capital = expected_capital_amount(
        capital_goods_price, inflation, capital_stock
    )

    expected_loans = expected_loans_amount(
        current_loans, debt_installment_rate
    )

    target_loans = target_loans_amount(
        expected_deposits, current_deposits
    )

    return (
        expected_sales,
        desired_investment,
        desired_materials,
        desired_employment,
        expected_profit,
        expected_capital,
        expected_loans,
        target_loans,
    )
end

const FIRM_EXPECTATION_COMPONENTS = (
    Components.PrincipalProduct,
    Components.Price,
    Components.AverageWageRate,
    Components.CapitalDeprecationRate,
    Components.IntermediateProductivity,
    Components.LaborProductivity,
    Components.CapitalProductivity,
    Components.GoodsDemand,
    Components.CapitalStock,
    Components.Profits,
    Components.LoansOutstanding,
    Components.Deposits,
    Components.DesiredInvestment,
    Components.DesiredMaterials,
    Components.DesiredEmployment,
    Components.ExpectedProfits,
    Components.ExpectedCapital,
    Components.ExpectedLoans,
    Components.ExpectedSales,
    Components.TargetLoans,
)

function set_firms_expectations_and_decisions!(world::Ark.World)
    expectations = Ark.get_resource(world, Expectations)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)
    firm_cache = Ark.get_resource(world, FirmTmpBuffers{Float64})

    growth = expectations.output_growth
    inflation = expectations.inflation

    sector = price_indices.sector
    household = price_indices.household_consumption
    capital_goods = price_indices.capital_goods

    technology_matrix = properties.product_coeffs.technology_matrix
    employer_contribution = properties.social_insurance.employers_contribution

    debt_installment_rate = properties.banking_params.debt_installment_rate
    dividend_payout_ratio = properties.banking_params.dividend_payout_ratio
    corporate_tax = properties.tax_rates.corporate

    precompute_sector_production_costs!(
        firm_cache.sector_production_cost,
        technology_matrix,
        sector,
    )

    for (
            e,
            principal_product,
            prices,
            average_wages,
            depreciation_rate,
            intermediate_productivity,
            labor_productivity,
            capital_productivity,
            goods_demand,
            capital,
            profits,
            loans,
            deposits,
            desired_investment,
            desired_materials,
            desired_employment,
            expected_profits,
            expected_capital,
            expected_loans,
            expected_sales,
            target_loans,
        ) in Ark.Query(world, FIRM_EXPECTATION_COMPONENTS)

        @inbounds for i in eachindex(e)
            product_id = principal_product[i].id
            price = prices[i].value
            inv_price = inv(price)

            wage = average_wages[i].rate
            δ = depreciation_rate[i].rate
            a_m = intermediate_productivity[i].value
            a_l = labor_productivity[i].value
            a_k = capital_productivity[i].value

            demand = goods_demand[i].amount
            capital_stock = capital[i].amount
            current_profit = profits[i].amount
            current_loans = loans[i].amount
            current_deposits = deposits[i].amount

            sector_production_cost = firm_cache.sector_production_cost[product_id]

            cost_push_inflation = compute_firm_cost_push_inflation(
                wage,
                employer_contribution,
                household,
                δ,
                a_m,
                a_l,
                a_k,
                capital_goods,
                sector_production_cost,
                inv_price,
            )

            (
                expected_sales_amount,
                desired_investment_amount,
                desired_materials_amount,
                desired_employment_amount,
                expected_profit_amount,
                expected_capital_amount,
                expected_loans_amount,
                target_loans_amount,
            ) = compute_firm_expectation_scalars(
                demand,
                capital_stock,
                current_profit,
                current_loans,
                current_deposits,
                growth,
                inflation,
                δ,
                a_l,
                a_k,
                a_m,
                capital_goods,
                debt_installment_rate,
                dividend_payout_ratio,
                corporate_tax,
            )

            desired_investment[i] = Components.DesiredInvestment(desired_investment_amount)
            desired_materials[i] = Components.DesiredMaterials(desired_materials_amount)
            desired_employment[i] = Components.DesiredEmployment(desired_employment_amount)
            expected_sales[i] = Components.ExpectedSales(expected_sales_amount)
            expected_profits[i] = Components.ExpectedProfits(expected_profit_amount)
            expected_capital[i] = Components.ExpectedCapital(expected_capital_amount)
            expected_loans[i] = Components.ExpectedLoans(expected_loans_amount)
            target_loans[i] = Components.TargetLoans(target_loans_amount)
            prices[i] = Components.Price(price * (1 + cost_push_inflation) * (1 + inflation))
        end
    end

    return nothing
end

function firm_wage(
        baseline_wage,
        expected_sales,
        capital_stock,
        capital_productivity,
        materials,
        intermediate_productivity,
        employment,
        labor_productivity,
    )
    constrained_output = min(
        expected_sales,
        min(
            capital_stock * capital_productivity,
            materials * intermediate_productivity,
        ),
    )
    return baseline_wage * min(1.5, constrained_output / (employment * labor_productivity))
end

const FIRM_WAGE_COMPONENTS = (
    Components.ExpectedSales, Components.WageBill, Components.CapitalStock, Components.Intermediates, Components.Employment,
    Components.LaborProductivity, Components.CapitalProductivity, Components.IntermediateProductivity, Components.AverageWageRate,
)

function set_firms_wages!(world::Ark.World)
    for (
            _,
            expected_sales,
            wage_bill,
            capital,
            intermediates,
            employment,
            labor_productivity,
            capital_productivity,
            intermediate_productivity,
            average_wages,
        ) in Ark.Query(
            world,
            FIRM_WAGE_COMPONENTS
        )
        wage_bill.amount .= firm_wage.(
            average_wages.rate,
            expected_sales.amount,
            capital.amount,
            capital_productivity.value,
            intermediates.amount,
            intermediate_productivity.value,
            employment.amount,
            labor_productivity.value
        )
    end

    return
end

@inline function firm_labor_productivity(
        baseline_labor_productivity,
        expected_sales,
        capital_stock,
        capital_productivity,
        materials,
        intermediate_productivity,
        employment,
    )
    constrained_output = min(
        expected_sales,
        min(
            capital_stock * capital_productivity,
            materials * intermediate_productivity,
        ),
    )
    return baseline_labor_productivity *
        min(1.5, constrained_output / (employment * baseline_labor_productivity))
end

@inline function firm_production(
        expected_sales,
        employment,
        labor_productivity,
        capital_stock,
        capital_productivity,
        materials,
        intermediate_productivity,
    )
    return min(
        expected_sales,
        min(
            employment * labor_productivity,
            min(
                capital_stock * capital_productivity,
                materials * intermediate_productivity,
            ),
        ),
    )
end

const FIRM_PRODUCTION_COMPONENTS = (
    Components.ExpectedSales,
    Components.Output,
    Components.Employment,
    Components.LaborProductivity,
    Components.CapitalStock,
    Components.CapitalProductivity,
    Components.Intermediates,
    Components.IntermediateProductivity,
)

function set_firms_production!(world::Ark.World)
    for (
            _,
            expected_sales,
            production,
            employment,
            labor_productivity,
            capital,
            capital_productivity,
            intermediates,
            intermediate_productivity,
        ) in Ark.Query(world, FIRM_PRODUCTION_COMPONENTS)

        effective_labor_productivity = firm_labor_productivity.(
            labor_productivity.value,
            expected_sales.amount,
            capital.amount,
            capital_productivity.value,
            intermediates.amount,
            intermediate_productivity.value,
            employment.amount,
        )
        @inbounds production.amount .= firm_production.(
            expected_sales.amount,
            employment.amount,
            effective_labor_productivity,
            capital.amount,
            capital_productivity.value,
            intermediates.amount,
            intermediate_productivity.value,
        )
    end
    return nothing
end


@inline function firm_profit(
        price,
        quantity,
        excess_sales,
        deposits,
        wage,
        employment,
        household_price_index,
        employer_contribution,
        intermediate_productivity,
        intermediate_price,
        output,
        depreciation_rate,
        capital_productivity,
        capital_goods_price,
        product_tax_rate,
        capital_tax_rate,
        loans,
        lending_rate,
        deposit_rate,
    )
    in_sales = price * quantity + price * excess_sales
    in_deposits = deposit_rate * pos(deposits)

    out_wages = (1 + employer_contribution) * wage * employment * household_price_index
    out_expenses = inv(intermediate_productivity) * intermediate_price * output
    out_depreciation = depreciation_rate / capital_productivity * capital_goods_price * output
    out_taxes_prods = product_tax_rate * price * output
    out_taxes_capital = capital_tax_rate * price * output
    out_loans = lending_rate * (loans + max(0.0, -deposits))

    return in_sales + in_deposits -
        out_wages - out_expenses - out_depreciation - out_taxes_prods - out_taxes_capital - out_loans
end

const FIRM_PROFIT_COMPONENTS = (
    Components.Profits,
    Components.Price,
    Components.Sales,
    Components.Output,
    Components.FinalGoodsStockChange,
    Components.Deposits,
    Components.WageBill,
    Components.Employment,
    Components.IntermediateProductivity,
    Components.PriceIndex,
    Components.CapitalDeprecationRate,
    Components.CapitalProductivity,
    Components.CFPriceIndex,
    Components.OutputTaxRate,
    Components.CapitalTaxRate,
    Components.LoansOutstanding,
)

function set_firms_profits!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    (_, r) = single(Ark.Query(world, (Components.LendingRate,)))
    (_, r_bar) = single(Ark.Query(world, (Components.NominalInterestRate,)))


    for (
            _,
            profits,
            prices,
            sales,
            production,
            final_goods_stock_change,
            deposits,
            wage_bill,
            employment,
            intermediate_productivity,
            intermediate_price,
            depreciation_rate,
            capital_productivity,
            cf_price_index,
            product_tax_rate,
            capital_tax_rate,
            loans,
        ) in Ark.Query(world, FIRM_PROFIT_COMPONENTS)

        @inbounds profits.amount .= firm_profit.(
            prices.value,
            sales.amount,
            final_goods_stock_change.amount,
            deposits.amount,
            wage_bill.amount,
            employment.amount,
            price_indices.household_consumption,
            properties.social_insurance.employers_contribution,
            intermediate_productivity.value,
            intermediate_price.value,
            production.amount,
            depreciation_rate.rate,
            capital_productivity.value,
            cf_price_index.value,
            product_tax_rate.rate,
            capital_tax_rate.rate,
            loans.amount,
            r.rate,
            r_bar.rate,
        )
    end

    return nothing
end

@inline pos(x) = max(zero(x), x)

@inline function firm_deposits(
        deposits,
        price,
        sales,
        wage_bill,
        employment,
        household_price_index,
        employer_contribution,
        materials_stock_change,
        intermediate_price_index,
        output_tax_rate,
        output,
        capital_tax_rate,
        profits,
        corporate_tax_rate,
        dividend_payout_ratio,
        loans,
        lending_rate,
        deposit_rate,
        capital_goods_price_index,
        investment,
        loan_flow,
        debt_installment_rate,
    )
    sales_income = price * sales
    labour_cost = -(1.0 + employer_contribution) * wage_bill * employment * household_price_index
    material_cost = -materials_stock_change * intermediate_price_index
    taxes_products = -output_tax_rate * price * output
    taxes_production = -capital_tax_rate * price * output
    corporate_tax = -corporate_tax_rate * pos(profits)
    dividend_payments = -dividend_payout_ratio * (1.0 - corporate_tax_rate) * pos(profits)
    interest_payments = -lending_rate * (loans + pos(-deposits))
    interest_received = deposit_rate * pos(deposits)
    investment_cost = -capital_goods_price_index * investment
    debt_installment = -debt_installment_rate * loans

    deposit_change =
        sales_income +
        labour_cost +
        material_cost +
        taxes_products +
        taxes_production +
        corporate_tax +
        dividend_payments +
        interest_payments +
        interest_received +
        investment_cost +
        loan_flow +
        debt_installment

    return deposits + deposit_change
end

@inline function firm_equity(
        deposits,
        intermediates,
        sector_production_cost,
        price,
        inventories,
        capital_goods_price_index,
        capital_stock,
        loans,
    )
    return deposits +
        intermediates * sector_production_cost +
        price * inventories +
        capital_goods_price_index * capital_stock -
        loans
end

@inline function next_capital_stock(
        capital_stock,
        depreciation_rate,
        capital_productivity,
        output,
        investment,
    )
    return capital_stock - depreciation_rate / capital_productivity * output + investment
end

@inline function next_intermediates(
        intermediates,
        output,
        intermediate_productivity,
        materials_stock_change,
    )
    return intermediates - output / intermediate_productivity + materials_stock_change
end


const FIRM_DEPOSIT_COMPONENTS = (
    Components.Deposits,
    Components.Price,
    Components.Sales,
    Components.WageBill,
    Components.Employment,
    Components.MaterialsStockChange,
    Components.PriceIndex,
    Components.OutputTaxRate,
    Components.Output,
    Components.CapitalTaxRate,
    Components.CFPriceIndex,
    Components.Profits,
    Components.LoansOutstanding,
    Components.Investment,
    Components.LoanFlow,
)

function set_firms_deposits!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)

    (_, r) = single(Ark.Query(world, (Components.LendingRate,)))
    (_, r_bar) = single(Ark.Query(world, (Components.NominalInterestRate,)))

    employer_contribution = properties.social_insurance.employers_contribution
    corporate_tax_rate = properties.tax_rates.corporate
    dividend_payout_ratio = properties.banking_params.dividend_payout_ratio
    debt_installment_rate = properties.banking_params.debt_installment_rate

    household_price_index = price_indices.household_consumption

    for (
            _,
            deposits,
            prices,
            sales,
            wage_bill,
            employment,
            materials_stock_change,
            price_index,
            output_tax_rate,
            output,
            capital_tax_rate,
            cf_price_index,
            profits,
            loans,
            investment,
            loan_flow,
        ) in Ark.Query(world, FIRM_DEPOSIT_COMPONENTS)

        @inbounds deposits.amount .= firm_deposits.(
            deposits.amount,
            prices.value,
            sales.amount,
            wage_bill.amount,
            employment.amount,
            household_price_index,
            employer_contribution,
            materials_stock_change.amount,
            price_index.value,
            output_tax_rate.rate,
            output.amount,
            capital_tax_rate.rate,
            profits.amount,
            corporate_tax_rate,
            dividend_payout_ratio,
            loans.amount,
            r.rate,
            r_bar.rate,
            cf_price_index.value,
            investment.amount,
            loan_flow.amount,
            debt_installment_rate,
        )
    end

    return nothing
end

const FIRM_EQUITY_COMPONENTS = (
    Components.Equity,
    Components.Deposits,
    Components.Intermediates,
    Components.PrincipalProduct,
    Components.Price,
    Components.Inventories,
    Components.CapitalStock,
    Components.LoansOutstanding,
)

function set_firms_equity!(world::Ark.World)
    price_indices = Ark.get_resource(world, PriceIndices)
    properties = Ark.get_resource(world, Properties)
    firm_cache = Ark.get_resource(world, FirmTmpBuffers{Float64})

    precompute_sector_production_costs!(
        firm_cache.sector_production_cost,
        properties.product_coeffs.technology_matrix,
        price_indices.sector,
    )

    sector_costs = firm_cache.sector_production_cost
    capital_goods_price_index = price_indices.capital_goods

    for (
            e,
            equity,
            deposits,
            intermediates,
            principal_product,
            prices,
            inventories,
            capital,
            loans,
        ) in Ark.Query(world, FIRM_EQUITY_COMPONENTS)

        @inbounds for i in eachindex(e)
            equity[i] = Components.Equity(
                firm_equity(
                    deposits[i].amount,
                    intermediates[i].amount,
                    sector_costs[principal_product[i].id],
                    prices[i].value,
                    inventories[i].amount,
                    capital_goods_price_index,
                    capital[i].amount,
                    loans[i].amount,
                )
            )
        end
    end

    return nothing
end

const FIRM_LOAN_COMPONENTS = (
    Components.LoansOutstanding,
    Components.LoanFlow,
)

function set_firms_loans!(world::Ark.World)
    debt_installment_rate = Ark.get_resource(world, Properties).banking_params.debt_installment_rate

    for (_, loans, loan_flow) in Ark.Query(world, FIRM_LOAN_COMPONENTS)
        @inbounds loans.amount .= (1.0 - debt_installment_rate) .* loans.amount .+ loan_flow.amount
    end

    return nothing
end

const FIRM_STOCK_COMPONENTS = (
    Components.CapitalStock,
    Components.CapitalDeprecationRate,
    Components.CapitalProductivity,
    Components.Output,
    Components.Investment,
    Components.Intermediates,
    Components.IntermediateProductivity,
    Components.MaterialsStockChange,
    Components.Sales,
    Components.FinalGoodsStockChange,
    Components.Inventories,
)

function set_firms_stocks!(world::Ark.World)
    for (
            _,
            capital,
            depreciation_rate,
            capital_productivity,
            output,
            investment,
            intermediates,
            intermediate_productivity,
            materials_stock_change,
            sales,
            final_goods_stock_change_comp,
            inventories,
        ) in Ark.Query(world, FIRM_STOCK_COMPONENTS)

        @inbounds final_goods_stock_change_comp.amount .= output.amount .- sales.amount


        @inbounds capital.amount .= next_capital_stock.(
            capital.amount,
            depreciation_rate.rate,
            capital_productivity.value,
            output.amount,
            investment.amount,
        )

        @inbounds intermediates.amount .= next_intermediates.(
            intermediates.amount,
            output.amount,
            intermediate_productivity.value,
            materials_stock_change.amount,
        )

        @inbounds inventories.amount .= inventories.amount .+ final_goods_stock_change_comp.amount
    end

    return nothing
end
