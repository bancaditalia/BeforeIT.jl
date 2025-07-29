
# update wages for workers
function update_workers_wages!(w_act, w_i)
    T = eltype(w_act.O_h)
    for (i, h) in enumerate(w_act.O_h)
        if h != zero(T)
            w_act.w_h[i] = w_i[h]
        end
    end
end

function _income_w_act(w_h, O_h, tau_SIW, tau_INC, theta_UB, sb_other, P_bar_HH; pi_e = 0.0)
    Y_h = zeros(typeFloat, length(w_h))
    for h in eachindex(w_h)
        if O_h[h] != 0
            Y_h[h] = (w_h[h] * (1 - tau_SIW - tau_INC * (1 - tau_SIW)) + sb_other) *
                     P_bar_HH * (1 + pi_e)
        else
            Y_h[h] = (theta_UB * w_h[h] + sb_other) * P_bar_HH * (1 + pi_e)
        end
    end
    return Y_h
end

function households_income_act(w_act::AbstractWorkers, model)
    _income_w_act(
        w_act.w_h,
        w_act.O_h,
        model.prop.tau_SIW,
        model.prop.tau_INC,
        model.prop.theta_UB,
        model.gov.sb_other,
        model.agg.P_bar_HH
    )
end

function _income_w_inact(H_inact, sb_inact, sb_other, P_bar_HH; pi_e = 0.0)
    Y_h = zeros(typeFloat, H_inact)
    for h in 1:H_inact
        Y_h[h] = (sb_inact + sb_other) * P_bar_HH * (1 + pi_e)
    end
    return Y_h
end

function households_income_inact(w_inact::AbstractWorkers, model)
    _income_w_inact(
        length(w_inact), model.gov.sb_inact, model.gov.sb_other, model.agg.P_bar_HH)
end

function _income_fowner(Pi_i, tau_INC, tau_FIRM, theta_DIV, sb_other, P_bar_HH; pi_e = 0.0)
    Y_h = zeros(typeFloat, length(Pi_i))
    for i in eachindex(Pi_i)
        Y_h[i] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_i[i]) +
                 sb_other * P_bar_HH * (1 + pi_e)
    end
    return Y_h
end

function households_income(firms::AbstractFirms, model)
    _income_fowner(
        firms.Pi_i,
        model.prop.tau_INC,
        model.prop.tau_FIRM,
        model.prop.theta_DIV,
        model.gov.sb_other,
        model.agg.P_bar_HH
    )
end

function _income_bowner(Pi_k, tau_INC, tau_FIRM, theta_DIV, sb_other, P_bar_HH; pi_e = 0.0)
    Y_h = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_k) +
          sb_other * P_bar_HH * (1 + pi_e)
    return Y_h
end

function households_income(bank::AbstractBank, model)
    _income_bowner(
        bank.Pi_k,
        model.prop.tau_INC,
        model.prop.tau_FIRM,
        model.prop.theta_DIV,
        model.gov.sb_other,
        model.agg.P_bar_HH
    )
end

function _budget_w_act(w_h, O_h, psi, psi_H, tau_VAT, tau_CF, sb_other,
        P_bar_HH, pi_e, tau_SIW, tau_INC, theta_UB)
    Y_e_h = _income_w_act(
        w_h, O_h, tau_SIW, tau_INC, theta_UB, sb_other, P_bar_HH; pi_e = pi_e)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end

function households_budget_act(w_act::AbstractWorkers, model)
    _budget_w_act(
        w_act.w_h,
        w_act.O_h,
        model.prop.psi,
        model.prop.psi_H,
        model.prop.tau_VAT,
        model.prop.tau_CF,
        model.gov.sb_other,
        model.agg.P_bar_HH,
        model.agg.pi_e,
        model.prop.tau_SIW,
        model.prop.tau_INC,
        model.prop.theta_UB
    )
end

function _budget_w_inact(
        H_inact, psi, psi_H, tau_VAT, tau_CF, sb_inact, sb_other, P_bar_HH, pi_e)
    Y_e_h = _income_w_inact(H_inact, sb_inact, sb_other, P_bar_HH; pi_e = pi_e)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end

function households_budget_inact(w_inact::AbstractWorkers, model)
    _budget_w_inact(
        length(w_inact),
        model.prop.psi,
        model.prop.psi_H,
        model.prop.tau_VAT,
        model.prop.tau_CF,
        model.gov.sb_inact,
        model.gov.sb_other,
        model.agg.P_bar_HH,
        model.agg.pi_e
    )
end

function _budget_fowner(psi, psi_H, tau_VAT, tau_CF, tau_INC, tau_FIRM,
        theta_DIV, Pi_e_i, sb_other, P_bar_HH, pi_e)
    Y_e_h = _income_fowner(
        Pi_e_i, tau_INC, tau_FIRM, theta_DIV, sb_other, P_bar_HH; pi_e = pi_e)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end

function households_budget(firms::AbstractFirms, model)
    _budget_fowner(
        model.prop.psi,
        model.prop.psi_H,
        model.prop.tau_VAT,
        model.prop.tau_CF,
        model.prop.tau_INC,
        model.prop.tau_FIRM,
        model.prop.theta_DIV,
        firms.Pi_e_i,
        model.gov.sb_other,
        model.agg.P_bar_HH,
        model.agg.pi_e
    )
end

function _budget_bowner(psi, psi_H, tau_VAT, tau_CF, tau_INC, tau_FIRM,
        theta_DIV, Pi_e_k, sb_other, P_bar_HH, pi_e)
    Y_e_h = _income_bowner(
        Pi_e_k, tau_INC, tau_FIRM, theta_DIV, sb_other, P_bar_HH; pi_e = pi_e)
    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end

function households_budget(bank::AbstractBank, model)
    _budget_bowner(
        model.prop.psi,
        model.prop.psi_H,
        model.prop.tau_VAT,
        model.prop.tau_CF,
        model.prop.tau_INC,
        model.prop.tau_FIRM,
        model.prop.theta_DIV,
        bank.Pi_e_k,
        model.gov.sb_other,
        model.agg.P_bar_HH,
        model.agg.pi_e
    )
end

function households_deposits(households, model)
    tau_VAT, tau_CF = model.prop.tau_VAT, model.prop.tau_CF
    r_bar = model.cb.r_bar
    r = model.bank.r

    DD_h = households.Y_h - (1 + tau_VAT) * households.C_h - (1 + tau_CF) * households.I_h +
           r_bar * max.(0, households.D_h) - r * max.(0, -households.D_h)
    D_h = households.D_h + DD_h
    return D_h
end
