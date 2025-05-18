
"""
    gov_expenditure(gov::AbstractGovernment, model)

Computes government expenditure on consumption and transfers to households.

# Arguments
- `gov`: government object
- `model`: model object

# Returns
- `C_G`: government consumption
- `C_d_j`: local government consumptions
"""
function gov_expenditure(gov, model)
    # unpack non-government arguments
    c_G_g = model.prop.products.c_G_g
    P_bar_g = model.agg.P_bar_g
    pi_e = model.agg.pi_e

    epsilon_G = randn() * gov.sigma_G
    C_G = exp(gov.alpha_G * log(gov.C_G) + gov.beta_G + epsilon_G)
    J = size(gov.C_d_j, 1)
    C_d_j = C_G ./ J .* ones(J) .* sum(c_G_g .* P_bar_g) .* (1 + pi_e)
    return C_G, C_d_j
end

""" 
    gov_revenues(model)

Computes government revenues from taxes and social security contributions.
The government collects taxes on labour income, capital income, value added,
and corporate income. It also collects social security contributions from
workers and firms. The government also collects taxes on consumption and
capital formation. Finally, the government collects taxes on exports and
imports.

# Arguments
- `model`: model object

# Returns
- `Y_G`: government revenues
"""
function gov_revenues(model::AbstractModel)
    # unpack objects
    w_act, w_inact, firms, bank, rotw = model.w_act, model.w_inact, model.firms, model.bank, model.rotw
    prop = model.prop
    P_bar_HH = model.agg.P_bar_HH

    # unpack parameters
    tau_SIF, tau_SIW, tau_INC, tau_CF, tau_VAT = prop.tau_SIF, prop.tau_SIW, prop.tau_INC, prop.tau_CF, prop.tau_VAT
    tau_FIRM, tau_EXPORT, theta_DIV = prop.tau_FIRM, prop.tau_EXPORT, prop.theta_DIV

    # compute total wages, consumption and investment
    tot_wages_emp = sum(w_act.w_h[w_act.O_h .!= 0])
    tot_C_h = sum(w_act.C_h) + sum(w_inact.C_h) + sum(firms.C_h) + bank.C_h
    tot_I_h = sum(w_act.I_h) + sum(w_inact.I_h) + sum(firms.I_h) + bank.I_h

    # compute government revenues
    social_security = (tau_SIF + tau_SIW) * tot_wages_emp * P_bar_HH
    labour_income = tau_INC * (1 - tau_SIW) * P_bar_HH * tot_wages_emp
    value_added = tau_VAT * tot_C_h
    capital_income = tau_INC * (1 - tau_FIRM) * theta_DIV * (sum(pos.(firms.Pi_i)) + pos(bank.Pi_k))
    corporate_income = tau_FIRM * (sum(pos.(firms.Pi_i)) + pos(bank.Pi_k))
    capital_formation = tau_CF * tot_I_h
    products = sum(firms.tau_Y_i .* firms.P_i .* firms.Y_i)
    production = sum(firms.tau_K_i .* firms.P_i .* firms.Y_i)
    export_ = tau_EXPORT * rotw.C_l

    Y_G =
        social_security +
        labour_income +
        value_added +
        capital_income +
        corporate_income +
        capital_formation +
        products +
        production +
        export_

    return Y_G
end

"""
    gov_loans(gov::AbstractGovernment, model, Y_G)

Computes government new government debt.

# Arguments
- `gov::AbstractGovernment`: government object
- `model`: model object

# Returns
- `L_G`: new government debt
"""
function gov_loans(gov, model)
    # unpack non-government arguments
    r_G = model.cb.r_G
    P_bar_HH = model.agg.P_bar_HH
    H = model.prop.H
    H_inact = model.prop.H_inact
    theta_UB = model.prop.theta_UB

    w_h = model.w_act.w_h
    O_h = model.w_act.O_h

    tot_wages_unemp = sum(w_h[O_h .== 0])
    social_benefits =
        H_inact * gov.sb_inact * P_bar_HH + theta_UB * tot_wages_unemp * P_bar_HH + H * gov.sb_other * P_bar_HH

    # deficit = social benefits + consumption + payments on loans - revenues
    Pi_G = social_benefits + gov.C_j + r_G * gov.L_G - gov.Y_G
    # update government debt
    L_G = gov.L_G + Pi_G

    return L_G
end

"""
    gov_social_benefits(gov::AbstractGovernment, model)

Computes social benefits paid by the government households.

# Arguments
- `gov`: government object
- `model`: model object

# Returns
- `sb_other`: social benefits for other households
- `sb_inact`: social benefits for inactive households
"""
function gov_social_benefits(gov::AbstractGovernment, model)
    gamma_e = model.agg.gamma_e

    sb_other = gov.sb_other * (1 + gamma_e)
    sb_inact = gov.sb_inact * (1 + gamma_e)

    return sb_other, sb_inact
end
