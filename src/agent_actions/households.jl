# update wages for workers
function update_workers_wages!(model::AbstractModel)
    w_act, firms = model.w_act, model.firms
    w_i = firms.w_i
    for (i, h) in enumerate(w_act.O_h)
        if h != zero(typeInt)
            w_act.w_h[i] = w_i[h]
        end
    end
    return
end

function households_income_act(model; expected = false)
    w_act = model.w_act

    w_h, O_h, tau_SIW, tau_INC = w_act.w_h, w_act.O_h, model.prop.tau_SIW, model.prop.tau_INC
    theta_UB, sb_other, P_bar_HH = model.prop.theta_UB, model.gov.sb_other, model.agg.P_bar_HH

    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, length(w_h))
    for h in eachindex(w_h)
        if O_h[h] != 0
            Y_h[h] = (w_h[h] * (1 - tau_SIW - tau_INC * (1 - tau_SIW)) + sb_other) * P_bar_HH * (1 + pi_e)
        else
            Y_h[h] = (theta_UB * w_h[h] + sb_other) * P_bar_HH * (1 + pi_e)
        end
    end
    return Y_h
end
function set_households_income_act!(model; expected = false)
    return model.w_act.Y_h .= households_income_act(model; expected)
end

function households_income_inact(model::AbstractModel; expected = false)
    w_inact = model.w_inact

    H_inact, sb_inact = length(w_inact), model.gov.sb_inact
    sb_other, P_bar_HH = model.gov.sb_other, model.agg.P_bar_HH

    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, H_inact)
    for h in 1:H_inact
        Y_h[h] = (sb_inact + sb_other) * P_bar_HH * (1 + pi_e)
    end
    return Y_h
end
function set_households_income_inact!(model; expected = false)
    return model.w_inact.Y_h .= households_income_inact(model; expected)
end

function households_income_firms(model::AbstractModel; expected = false)
    firms = model.firms
    tau_INC, tau_FIRM, theta_DIV = model.prop.tau_INC, model.prop.tau_FIRM, model.prop.theta_DIV
    sb_other, P_bar_HH = model.gov.sb_other, model.agg.P_bar_HH

    Pi_i = expected ? firms.Pi_e_i : firms.Pi_i
    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, length(Pi_i))
    for i in eachindex(Pi_i)
        Y_h[i] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_i[i]) + sb_other * P_bar_HH * (1 + pi_e)
    end
    return Y_h
end
function set_households_income_firms!(model; expected = false)
    return model.firms.Y_h .= households_income_firms(model; expected)
end

function households_income_bank(model; expected = false)
    bank = model.bank

    tau_INC, tau_FIRM, theta_DIV = model.prop.tau_INC, model.prop.tau_FIRM, model.prop.theta_DIV
    sb_other, P_bar_HH = model.gov.sb_other, model.agg.P_bar_HH

    Pi_k = expected ? bank.Pi_e_k : bank.Pi_k
    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_k) + sb_other * P_bar_HH * (1 + pi_e)
    return Y_h
end
function set_households_income_bank!(model; expected = false)
    return model.bank.Y_h = households_income_bank(model; expected)
end

function households_budget_act(model::AbstractModel)
    w_act = model.w_act

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_act(model; expected = true)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_act!(model::AbstractModel)
    w_act = model.w_act
    C_d_h, I_d_h = households_budget_act(model)
    w_act.C_d_h .= C_d_h
    return w_act.I_d_h .= I_d_h
end

function households_budget_inact(model::AbstractModel)
    w_inact = model.w_inact

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_inact(model; expected = true)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_inact!(model::AbstractModel)
    w_inact = model.w_inact
    C_d_h, I_d_h = households_budget_inact(model)
    w_inact.C_d_h .= C_d_h
    return w_inact.I_d_h .= I_d_h
end

function households_budget_firms(model::AbstractModel)
    firms = model.firms

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_firms(model; expected = true)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_firms!(model::AbstractModel)
    firms = model.firms
    C_d_h, I_d_h = households_budget_firms(model)
    firms.C_d_h .= C_d_h
    return firms.I_d_h .= I_d_h
end

function households_budget_bank(model)
    bank = model.bank

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_bank(model; expected = true)
    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_bank!(model)
    bank = model.bank
    C_d_h, I_d_h = households_budget_bank(model)
    bank.C_d_h = C_d_h
    return bank.I_d_h = I_d_h
end

function set_households_deposits_act!(model)
    D_h = households_deposits(model.w_act, model)
    return model.w_act.D_h .= D_h
end
function set_households_deposits_inact!(model)
    D_h = households_deposits(model.w_inact, model)
    return model.w_inact.D_h .= D_h
end
function set_households_deposits_firms!(model)
    D_h = households_deposits(model.firms, model)
    return model.firms.D_h .= D_h
end
function set_households_deposits_bank!(model)
    D_h = households_deposits(model.bank, model)
    return model.bank.D_h = D_h
end

function households_deposits(households, model)
    tau_VAT, tau_CF = model.prop.tau_VAT, model.prop.tau_CF
    r_bar = model.cb.r_bar
    r = model.bank.r

    DD_h =
        households.Y_h - (1 + tau_VAT) * households.C_h - (1 + tau_CF) * households.I_h +
        r_bar * max.(0, households.D_h) - r * max.(0, -households.D_h)
    D_h = households.D_h + DD_h
    return D_h
end
