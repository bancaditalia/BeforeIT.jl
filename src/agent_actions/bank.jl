"""
    bank_profits(model)

Calculate the total profits of the bank.

# Returns
- `Pi_k`: The total profits of the bank.

The total profits `Pi_k` are calculated as:

```math
\\Pi_k = r \\cdot \\sum_i(L_i + \\max(0, -D_i)) + r \\cdot \\sum_h(\\max(0, -D_h)) + r_{bar}
\\cdot \\max(0, D_k) - r_{bar} \\cdot \\sum_i(\\max(0, D_i)) - r_{bar} \\cdot
\\sum_h(\\max(0, D_h)) - r_{bar} \\cdot \\max(0, -D_k)
```

where

- `L_i`: Array of loans provided by the bank
- `D_i`: Array of deposits from firms
- `D_h`: Array of deposits from households
- `D_k`: Residual and balancing item on the bank’s balance sheet
- `r_bar`: Base interest rate
- `r`: Interest rate set by the bank
"""
function bank_profits(model)
    bank = model.bank

    L_i, D_i, r_bar = model.firms.L_i, model.firms.D_i, model.cb.r_bar
    D_h = [model.w_act.D_h; model.w_inact.D_h; model.firms.D_h; bank.D_h]

    z = zero(typeFloat)
    r_terms = sum(L_i) + sum(max.(z, -D_i)) + sum(max.(z, -D_h))
    r_bar_terms = sum(abs.(bank.D_k)) - sum(max.(z, D_i)) - sum(max.(z, D_h))
    Pi_k = bank.r * r_terms + r_bar * r_bar_terms
    return Pi_k
end
function set_bank_profits!(model)
    return model.bank.Pi_k = bank_profits(model)
end

"""
    bank_equity(model)

Calculate the net profits of the bank.

# Returns
- `E_k`: The updated equity of the bank.

The net profits `DE_k` are calculated as:

```math
DE_k = \\Pi_k - \\theta_{DIV} \\cdot (1 - \\tau_{FIRM}) \\cdot \\max(0, \\Pi_k) - \\tau_{FIRM} \\cdot \\max(0, \\Pi_k)
```

and the equity `E_k` is updated as:

```math
E_k = E_k + DE_k
```
"""
function bank_equity(model)
    bank = model.bank
    theta_DIV, tau_FIRM = model.prop.theta_DIV, model.prop.tau_FIRM
    DE_k = bank.Pi_k - theta_DIV * (1 - tau_FIRM) * max(0, bank.Pi_k) - tau_FIRM * max(0, bank.Pi_k)
    E_k = bank.E_k + DE_k
    return E_k
end
function set_bank_equity!(model)
    return model.bank.E_k = bank_equity(model)
end

"""
    bank_rate(model)

Update the interest rate set by the bank.

# Returns
- `r`: The updated interest rate

```math
r = \\bar{r} + \\mu
```
"""
function bank_rate(model::AbstractModel)
    bank = model.bank
    r = model.cb.r_bar + model.prop.mu
    return r
end
function set_bank_rate!(model::AbstractModel)
    return model.bank.r = bank_rate(model)
end

"""
    bank_expected_profits(model)

Calculate the expected profits of a bank.

# Returns
- `E_Pi_k`: Expected profits of the bank

The expected profits `E_Pi_k` are calculated as follows:

```math
E_{\\Pi_k} = \\Pi_k \\cdot (1 + \\pi_e) \\cdot (1 + \\gamma_e)
```

where

- `Pi_k`: Past profits of the bank
- `pi_e`: Expected inflation rate
- `gamma_e`: Expected growth rate
"""
function bank_expected_profits(model::AbstractModel)
    bank = model.bank
    pi_e, gamma_e = model.agg.pi_e, model.agg.gamma_e
    return bank.Pi_k * (1 + pi_e) * (1 + gamma_e)
end
function set_bank_expected_profits!(model::AbstractModel)
    return model.bank.Pi_e_k = bank_expected_profits(model)
end

"""
    finance_insolvent_firms!(model)

Re-finance insolvent firms using bank equity.
"""
function finance_insolvent_firms!(model::AbstractModel)
    firms, bank = model.firms, model.bank
    P_bar_CF, zeta_b = model.agg.P_bar_CF, model.prop.zeta_b

    for i in eachfirm(model)
        # firm is insolvent
        if firms.D_i[i] < 0 && firms.E_i[i] < 0
            # finance insolvent firm from bank
            bank.E_k = bank.E_k - (firms.L_i[i] - firms.D_i[i] - zeta_b * P_bar_CF * firms.K_i[i])

            # set variables of newly created firm
            firms.E_i[i] = firms.E_i[i] + (firms.L_i[i] - firms.D_i[i] - zeta_b * P_bar_CF * firms.K_i[i])
            firms.L_i[i] = zeta_b * P_bar_CF * firms.K_i[i]
            firms.D_i[i] = 0.0
        end
    end
    return
end

"""
    bank_deposits(model)

Calculate the new deposits of a bank.

# Returns
- `D_k`: New deposits of the bank

The new deposits `D_k` are calculated as the sum of the deposits of the active workers, the inactive workers,
the firms, and the bank owner itself, plus the bank's equity, minus the loans of the firms.
"""
function bank_deposits(model)
    bank = model.bank
    w_act, w_inact, firms = model.w_act, model.w_inact, model.firms
    waD_h, wiD_h, fD_h, bD_h, fD_i = w_act.D_h, w_inact.D_h, firms.D_h, bank.D_h, firms.D_i
    bE_k, fL_i = bank.E_k, firms.L_i

    tot_D_h = sum(waD_h) + sum(wiD_h) + sum(fD_h) + bD_h
    D_k = sum(fD_i) + tot_D_h + bE_k - sum(fL_i)
    return D_k
end
function set_bank_deposits!(model)
    return model.bank.D_k = bank_deposits(model)
end
