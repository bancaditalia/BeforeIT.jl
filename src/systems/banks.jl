function set_bank_deposits!(world)
    total_deposits = @sum_over (deposits.amount for deposits in Ark.Query(world, (Components.Deposits,)))
    total_loans = @sum_over (loans.amount for loans in Ark.Query(world, (Components.LoansOutstanding,)))

    for (e, equity, resisdual) in Ark.Query(world, (Components.Equity, Components.ResidualItems))
        for i in eachindex(e)
            resisdual[i] = Components.ResidualItem(equity[i] - total_loans + total_deposits)
        end
    end

    return nothing
end

function finance_insolvant_firms(world)
    P_bar_CF = Ark.get_resource(world, PriceIndices).capital_goods
    ζ = Ark.get_resource(world, Properties).banking_params.new_firm_loan_ratio

    financed_total_equity = 0.0
    for (e, outstanding_loans, equity, deposits, capital) in Ark.Query(world, Components.LoansOutstanding, Components.Equity, Components.Deposits, Components.CapitalStock)
        for i in eachindex(e)
            deposits[i].amount >= 0.0 && equity[i].amount >= 0 && continue
            loan = ζ * P_bar_CF * capital[i].amount
            fianced_equity = outstanding_loans[i].amount - deposits[i].amount - loan

            financed_total_equity += fianced_equity
            equity[i] = Components.Equity(equity[i].amount + fianced_equity)
            outstanding_loans[i] = Components.LoansOutstanding(loan)
            deposits[i] = Components.Deposits(0.0)
        end
    end

    for (_, equity) in Ark.Query(world, (Components.Equity,), with = (Components.LendingRate,))
        equity.amount .-= financed_total_equity
    end

    return nothing
end

function set_expected_profits!(world)
    (; expected_inflation, expected_output_growth) = Ark.get_resource(world, MacroeconomicState)

    for (_, expected_profits, profits) in Ark.Query(world, (Components.ExpectedProfits, Components.Profits), with = (Components.LendingRate,))
        expected_profits.amount .= profits.amount .* (1 + expected_output_growth) .* (1 + expected_inflation)
    end


    return nothing
end

function set_bank_rate!(world)
    cb_rate = 0.0
    for (e, cb) in Ark.Query(world, (Components.NominalInterestRate,))
        for i in eachindex(e)
            cb_rate = cb[i].rate
        end
    end

    mu = Ark.get_resource(world, Properties).banking_params.risk_premium

    for (_, lending_rate) in Ark.Query(world, (Components.LendingRate,))
        lending_rate.rate .= cb_rate + mu
    end

    return nothing
end

function set_bank_equity!(world)
    properties = Ark.get_resource(world, Properties)
    dividend_payout_ratio = properties.banking_params.dividend_payout_ratio
    corporate_tax = properties.tax_rates.corporate

    total_taxed_and_dividend_ratio = (dividend_payout_ratio * (1 - corporate_tax) + corporate_tax)
    for (_, equity, profits) in Ark.Query(world, (Components.Equity, Components.Profits), with = (Components.LendingRate,))
        equity.amount .= profits.amount .- total_taxed_and_dividend_ratio .* max.(0, profits.amount)
    end

    return nothing
end

function set_bank_profits!(world)
    total_positive_deposits = 0.0
    total_negative_deposits = 0.0
    for (e, deposits) in Ark.Query(world, (Components.Deposits,))
        @inbounds for i in eachindex(e)
            total_positive_deposits += max(0.0, deposits[i])
            total_negative_deposits += max(0.0, -deposits[i])
        end
    end
    total_loans = @sum_over (loans.amount for loans in Ark.Query(world, (Components.LoansOutstanding,)))

    cb_rate = 0.0
    for (e, cb) in Ark.Query(world, (Components.NominalInterestRate,))
        for i in eachindex(e)
            cb_rate = cb[i].rate
        end
    end

    rterm = total_loans + total_negative_deposits
    for (e, profits, lending_rate, residual_item) in Ark.Query(world, (Components.Profits, Components.LendingRate, Components.ResidualItem))
        @inbounds for i in eachindex(e)
            central_bank_term = residual_item[i] - total_positive_deposits - total_negative_deposits
            profits[i] = Components.Profits(lending_rate[i].rate * rterm + cb_rate * central_bank_term)
        end
    end


    return nothing

end
