function get_accounting_identities(data)
    # income accounting and production accounting should be equal
    income_and_production = sum(data.nominal_gva - data.compensation_employees -
                                data.operating_surplus - data.taxes_production)

    # compare nominal_gdp to total expenditure
    gdp_and_expenditure = sum(data.nominal_gdp - data.nominal_household_consumption -
                              data.nominal_government_consumption -
                              data.nominal_capitalformation - data.nominal_exports +
                              data.nominal_imports)

    # compare real_gdp to total expenditure
    gdp_and_expenditure_real = sum(data.real_gdp - data.real_household_consumption -
                                   data.real_government_consumption -
                                   data.real_capitalformation - data.real_exports +
                                   data.real_imports)

    return income_and_production, gdp_and_expenditure, gdp_and_expenditure_real
end

function get_accounting_identity_banks(model)
    cb_balance = model.cb.E_CB + model.rotw.D_RoW - model.gov.L_G + model.bank.D_k

    # accounting identity of balance sheet of commercial bank
    tot_D_h = sum(model.w_act.D_h) + sum(model.w_inact.D_h) + sum(model.firms.D_h) +
              model.bank.D_h

    bank_balance = sum(model.firms.D_i) + tot_D_h + sum(model.bank.E_k) -
                   sum(model.firms.L_i) - model.bank.D_k

    return cb_balance, bank_balance
end
