import CommonSolve
using CommonSolve: step!
export step!

"""
    step!(model, T=1; parallel = false, shock! = Bit.NoShock())

This function simulates the economic model for `T` steps, updating various components of the model based 
the interactions between different economic agents. It accepts a `model` object, which encapsulates the
state for the simulation, and some optional parameters. `parallel` to enable or disable multi-threading.
`shock` which can be used to shock the model during the stepping.

Key operations performed include:
- Financial adjustments for firms and banks, including insolvency checks and profit calculations.
- Economic expectations and adjustments, such as growth, inflation, and central bank rates.
- Labor and credit market operations, including wage updates and loan processing.
- Household economic activities, including consumption and investment budgeting.
- Government and international trade financial activities, including budgeting and trade balances.
- General market matching and accounting updates to reflect changes in economic indicators and positions.

The function updates the model in-place and return the model itself.
"""
function CommonSolve.step!(model::AbstractModel, T; parallel = false, shock! = NoShock())
    for _ in 1:T
        step!(model; parallel, shock!)
    end
    return model
end
function CommonSolve.step!(model::AbstractModel; parallel = false, shock! = NoShock())

    Bit.finance_insolvent_firms!(model)

    ####### GENERAL ESTIMATIONS #######

    # expectation on economic growth and inflation
    Bit.set_growth_inflation_expectations!(model)

    # update growth and inflation of economic area
    Bit.set_epsilon!(model)
    Bit.set_growth_inflation_EA!(model)

    # set central bank rate via the Taylor rule
    Bit.set_central_bank_rate!(model)

    # apply an eventual shock to the model, the default does nothing
    shock!(model)

    # update rate on loans and morgages
    Bit.set_bank_rate!(model)

    ####### FIRM EXPECTATIONS AND DECISIONS #######

    # compute firm quantity, price, investment and intermediate-goods, employment decisions,
    # expected profits, and desired/expected loans and capital
    Bit.set_firms_expectations_and_decisions!(model)

    ####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

    # firms acquire new loans in a search and match market for credit
    Bit.search_and_matching_credit!(model)

    # firms acquire labour in the search and match market for labour
    Bit.search_and_matching_labour!(model)

    # update wages and productivity of labour and compute production function (Leontief technology)
    Bit.set_firms_wages!(model)
    Bit.set_firms_production!(model)

    # update wages for workers
    Bit.update_workers_wages!(model)

    ####### CONSUMPTION AND INVESTMENT BUDGET #######

    # update social benefits
    Bit.set_gov_social_benefits!(model)

    # update expected bank profits
    Bit.set_bank_expected_profits!(model)

    # update consumption and investment budget for all households
    Bit.set_households_budget_act!(model)
    Bit.set_households_budget_inact!(model)
    Bit.set_households_budget_firms!(model)
    Bit.set_households_budget_bank!(model)

    ####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

    # compute gov expenditure
    Bit.set_gov_expenditure!(model)

    # compute demand for export and supply of imports
    Bit.set_rotw_import_export!(model)

    ####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######
    Bit.search_and_matching!(model; parallel)

    ####### FINAL GENERAL ACCOUNTING #######

    # update inflation and update global price index
    Bit.set_inflation_priceindex!(model)

    # update sector-specific price index
    Bit.set_sector_specific_priceindex!(model)

    # update CF index and HH (CPI) index
    Bit.set_capital_formation_priceindex!(model)
    Bit.set_households_priceindex!(model)

    # update firms stocks
    Bit.set_firms_stocks!(model)

    # update firms profits
    Bit.set_firms_profits!(model)

    # update bank profits
    Bit.set_bank_profits!(model)

    # update bank equity
    Bit.set_bank_equity!(model)

    # update actual income of all households
    Bit.set_households_income_act!(model)
    Bit.set_households_income_inact!(model)
    Bit.set_households_income_firms!(model)
    Bit.set_households_income_bank!(model)

    # update savings (deposits) of all households
    Bit.set_households_deposits_act!(model)
    Bit.set_households_deposits_inact!(model)
    Bit.set_households_deposits_firms!(model)
    Bit.set_households_deposits_bank!(model)

    # compute central bank equity
    Bit.set_central_bank_equity!(model)

    # compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
    Bit.set_gov_revenues!(model)

    # compute government deficit/surplus and update the government debt
    Bit.set_gov_loans!(model)

    # compute firms deposits, loans and equity
    Bit.set_firms_deposits!(model)
    Bit.set_firms_loans!(model)
    Bit.set_firms_equity!(model)

    # update net credit/debit position of rest of the world
    Bit.set_rotw_deposits!(model)

    # update bank net credit/debit position
    Bit.set_bank_deposits!(model)

    # update GDP with the results of the time step
    Bit.set_gross_domestic_product!(model)

    # update time step
    Bit.set_time!(model)

    return model
end
