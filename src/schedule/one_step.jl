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

function CommonSolve.step!(model)
    world = model.world

    Bit.finance_insolvent_firms!(world)

    ####### GENERAL ESTIMATIONS #######

    # expectation on economic growth and inflation
    Bit.set_growth_inflation_expectations!(world)

    # update growth and inflation of economic area
    Bit.set_epsilon!(world)
    Bit.set_growth_inflation_EA!(world)

    # set central bank rate via the Taylor rule
    Bit.set_central_bank_rate!(world)

    # apply an eventual shock to the world, the default does nothing
    shock!(world)

    # update rate on loans and morgages
    Bit.set_bank_rate!(world)

    ####### FIRM EXPECTATIONS AND DECISIONS #######

    # compute firm quantity, price, investment and intermediate-goods, employment decisions,
    # expected profits, and desired/expected loans and capital
    Bit.set_firms_expectations_and_decisions!(world)

    ####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

    # firms acquire new loans in a search and match market for credit
    Bit.search_and_matching_credit!(world)

    # firms acquire labour in the search and match market for labour
    Bit.search_and_matching_labour!(world)

    # update wages and productivity of labour and compute production function (Leontief technology)
    Bit.set_firms_wages!(world)
    Bit.set_firms_production!(world)

    # update wages for workers
    Bit.update_workers_wages!(world)

    ####### CONSUMPTION AND INVESTMENT BUDGET #######

    # update social benefits
    Bit.set_gov_social_benefits!(world)

    # update expected bank profits
    Bit.set_bank_expected_profits!(world)

    # update consumption and investment budget for all households
    Bit.set_households_expected_income!(world)
    Bit.set_households_budget!(world)

    ####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

    # compute gov expenditure
    Bit.set_gov_expenditure!(world)

    # compute demand for export and supply of imports
    Bit.set_rotw_import_export!(world)

    ####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######
    Bit.search_and_matching!(world; parallel)

    ####### FINAL GENERAL ACCOUNTING #######

    # update inflation and update global price index
    Bit.set_inflation_priceindex!(world)

    # update sector-specific price index
    Bit.set_sector_specific_priceindex!(world)

    # update CF index and HH (CPI) index
    Bit.set_capital_formation_priceindex!(world)
    Bit.set_households_priceindex!(world)

    # update firms stocks
    Bit.set_firms_stocks!(world)

    # update firms profits
    Bit.set_firms_profits!(world)

    # update bank profits
    Bit.set_bank_profits!(world)

    # update bank equity
    Bit.set_bank_equity!(world)

    # update actual income of all households
    Bit.set_households_income!(world)

    # update savings (deposits) of all households
    Bit.set_households_deposit!(world)

    # compute central bank equity
    Bit.set_central_bank_equity!(world)

    # compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
    Bit.set_gov_revenues!(world)

    # compute government deficit/surplus and update the government debt
    Bit.set_gov_loans!(world)

    # compute firms deposits, loans and equity
    Bit.set_firms_deposits!(world)
    Bit.set_firms_loans!(world)
    Bit.set_firms_equity!(world)

    # update net credit/debit position of rest of the world
    Bit.set_rotw_deposits!(world)

    # update bank net credit/debit position
    Bit.set_bank_deposits!(world)

    # update GDP with the results of the time step
    Bit.set_gross_domestic_product!(world)

    # update time step
    Bit.set_time!(world)

    return model
end
