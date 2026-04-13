function set_bank_deposits!(world)
    total_deposits = @sum_over (deposits.amount for deposits in Ark.Query(world, (Components.Deposits,)))
    total_loans = @sum_over (loans.amount for loans in Ark.Query(world, (Components.LoansOutstanding,)))

    for (e, equity, resisdual) in Ark.Query(world, (Components.Equity, Components.ResidualItem))
        for i in eachindex(e)
            resisdual[i] = Components.ResidualItem(equity[i] + total_loans + total_deposits)
        end
    end

    return
end
