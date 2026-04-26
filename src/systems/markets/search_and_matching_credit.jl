function search_and_matching_credit!(world::Ark.World)

    f = Ark.Filter(world, (Components.LoanFlow, Components.TargetLoans, Components.ExpectedLoans, Components.ExpectedCapital))
    Ark.shuffle_entities!(f)

    (; capital_requirement, loan_to_value_ratio) = BeforeIT.properties(world).banking_params
    total_expected_loans = @sum_over (el.amount for el in Ark.Query(world, (Components.ExpectedLoans,)))
    total_loans = 0.0
    (_, E_k) = single(Ark.Query(world, (Components.EquityCapital,)))
    for (e, loan_flow, target_loan, expected_loan, expected_capital) in Ark.Query(f)

        for i in eachindex(e)
            loan_flow[i] = Components.LoanFlow(
                max(
                    0.0,
                    min(
                        target_loan[i].amount,
                        loan_to_value_ratio * expected_capital[i].amount - expected_loan[i].amount,
                        E_k.amount / capital_requirement - total_expected_loans - total_loans
                    )
                )
            )
            total_loans += loan_flow[i].amount

        end
    end

    return nothing
end
