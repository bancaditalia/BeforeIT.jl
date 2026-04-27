function step!(model)
    world = model.world

    BeforeIT.finance_insolvent_firms!(world)

    ####### GENERAL ESTIMATIONS #######

    # expectation on economic growth and inflation
    BeforeIT.set_growth_inflation_expectations!(world)

    # update growth and inflation of economic area
    BeforeIT.set_epsilon!(world)
    BeforeIT.set_growth_inflation_EA!(world)

    # set central bank rate via the Taylor rule
    BeforeIT.set_central_bank_rate!(world)

    # apply an eventual shock to the world, the default does nothing
    #shock!(world)

    # update rate on loans and morgages
    BeforeIT.set_bank_rate!(world)

    ####### FIRM EXPECTATIONS AND DECISIONS #######

    # compute firm quantity, price, investment and intermediate-goods, employment decisions,
    # expected profits, and desired/expected loans and capital
    BeforeIT.set_firms_expectations_and_decisions!(world)

    ####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

    # firms acquire new loans in a search and match market for credit
    BeforeIT.search_and_matching_credit!(world)

    # firms acquire labour in the search and match market for labour
    BeforeIT.search_and_matching_labor!(world)

    # update wages and productivity of labour and compute production function (Leontief technology)
    BeforeIT.set_firms_wages!(world)
    BeforeIT.set_firms_production!(world)

    # update wages for workers
    BeforeIT.update_workers_wages!(world)

    ####### CONSUMPTION AND INVESTMENT BUDGET #######

    # update social benefits
    BeforeIT.set_gov_social_benefits!(world)

    # update expected bank profits
    BeforeIT.set_bank_expected_profits!(world)

    # update consumption and investment budget for all households
    BeforeIT.set_households_expected_income!(world)
    BeforeIT.set_households_budget!(world)

    ####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

    # compute gov expenditure
    BeforeIT.set_gov_expenditure!(world)

    # compute demand for export and supply of imports
    BeforeIT.set_rotw_import_export!(world)

    ####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######
    BeforeIT.search_and_matching!(world)

    ####### FINAL GENERAL ACCOUNTING #######

    # update inflation and update global price index
    BeforeIT.set_inflation_priceindex!(world)

    # update sector-specific price index
    BeforeIT.set_sector_specific_priceindex!(world)

    # update CF index and HH (CPI) index
    BeforeIT.set_capital_formation_priceindex!(world)
    BeforeIT.set_households_priceindex!(world)

    # update firms stocks
    BeforeIT.set_firms_stocks!(world)

    # update firms profits
    BeforeIT.set_firms_profits!(world)

    # update bank profits
    BeforeIT.set_bank_profits!(world)

    # update bank equity
    BeforeIT.set_bank_equity!(world)

    # update actual income of all households
    BeforeIT.set_households_income!(world)

    # update savings (deposits) of all households
    BeforeIT.set_households_deposit!(world)

    # compute central bank equity
    BeforeIT.set_central_bank_equity!(world)

    # compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
    BeforeIT.set_gov_revenues!(world)

    # compute government deficit/surplus and update the government debt
    BeforeIT.set_gov_loans!(world)

    # compute firms deposits, loans and equity
    BeforeIT.set_firms_deposits!(world)
    BeforeIT.set_firms_loans!(world)
    BeforeIT.set_firms_equity!(world)

    # update net credit/debit position of rest of the world
    BeforeIT.set_rotw_deposits!(world)

    # update bank net credit/debit position
    BeforeIT.set_bank_deposits!(world)

    # update GDP with the results of the time step
    BeforeIT.set_gross_domestic_product!(world)

    # update time step
    BeforeIT.set_time!(world)

    return model
end
