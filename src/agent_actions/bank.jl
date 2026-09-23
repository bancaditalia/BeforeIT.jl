"""
    bank_exposure(model, bank_id; expected = false, overdrafts = true)

Total credit exposure of bank `bank_id`: outstanding loans plus, when
`overdrafts = true`, the drawn overdrafts (negative deposits) of the firms and
households assigned to the bank.

With `expected = true` the loan leg uses `L_e_i`, the book net of this period's
scheduled repayment. The credit market needs that base because new loans are
granted on top of the post-repayment book.
"""
function bank_exposure(model::AbstractModel, bank_id; expected = false, overdrafts = true)
    banks = model.banks
    z = zero(typeFloat)
    exposure = sum(typeFloat[expected ? f.L_e_i : f.L_i for f in banks.firms[bank_id]]; init = z)
    overdrafts || return exposure
    for f in banks.firms[bank_id]
        exposure += max(z, -f.D_i) + max(z, -f.D_h)
    end
    for w in banks.w_act[bank_id]
        exposure += max(z, -w.D_h)
    end
    for w in banks.w_inact[bank_id]
        exposure += max(z, -w.D_h)
    end
    exposure += max(z, -banks.D_h[bank_id])
    return exposure
end

"""
    banks_profits(model)

Calculate the total profits of the banks.

# Returns
- `Pi_k`: The total profits of the banks.

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
function banks_profits(model)
    banks = model.banks
    r_bar = model.cb.r_bar

    Pi_k = zeros(typeFloat, length(banks))
    for bank_id in eachbank(model)
        L_i = typeFloat[f.L_i for f in model.banks.firms[bank_id]]
        D_i = typeFloat[f.D_i for f in model.banks.firms[bank_id]]
        D_h_firms = typeFloat[f.D_h for f in model.banks.firms[bank_id]]
        D_h_act = typeFloat[w.D_h for w in model.banks.w_act[bank_id]]
        D_h_inact = typeFloat[w.D_h for w in model.banks.w_inact[bank_id]]
        D_h = [D_h_act; D_h_inact; D_h_firms; banks.D_h[bank_id]]

        z = zero(typeFloat)
        r_terms = sum(L_i) + sum(max.(z, -D_i)) + sum(max.(z, -D_h))
        r_bar_terms = banks.D_k[bank_id] - sum(max.(z, D_i)) - sum(max.(z, D_h))
        Pi_k[bank_id] = banks.r[bank_id] * r_terms + r_bar * r_bar_terms
    end
    return Pi_k
end
function set_banks_profits!(model)
    return model.banks.Pi_k .= banks_profits(model)
end

"""
    banks_equity(model)

Calculate the net profits of the banks.

# Returns
- `E_k`: The updated equity of the banks.

The net profits `DE_k` are calculated as:

```math
DE_k = \\Pi_k - \\theta_{DIV} \\cdot (1 - \\tau_{FIRM}) \\cdot \\max(0, \\Pi_k) - \\tau_{FIRM} \\cdot \\max(0, \\Pi_k)
```

and the equity `E_k` is updated as:

```math
E_k = E_k + DE_k
```
"""
function banks_equity(model)
    banks = model.banks
    theta_DIV, tau_FIRM = model.prop.theta_DIV, model.prop.tau_FIRM
    DE_k = banks.Pi_k - theta_DIV .* (1 - tau_FIRM) * max.(0, banks.Pi_k) - tau_FIRM .* max.(0, banks.Pi_k)
    E_k = banks.E_k + DE_k
    return E_k
end
function set_banks_equity!(model)
    return model.banks.E_k .= banks_equity(model)
end

"""
    banks_rate(model)

Update the interest rate set by the banks.

# Returns
- `r`: The updated interest rate

```math
r_j = \\bar{r} + \\mu \\text{ for all banks } j
```
"""
function banks_rate(model::AbstractModel)
    r = model.cb.r_bar + model.prop.mu
    return r
end
function set_banks_rate!(model::AbstractModel)
    return model.banks.r .= banks_rate(model)
end

"""
    banks_expected_profits(model)

Calculate the expected profits of the banks.

# Returns
- `E_Pi_k`: Expected profits of the banks

The expected profits `E_Pi_k` are calculated as follows:

```math
E_{\\Pi_k} = \\Pi_k \\cdot (1 + \\pi_e) \\cdot (1 + \\gamma_e)
```

where

- `Pi_k`: Past profits of the bank
- `pi_e`: Expected inflation rate
- `gamma_e`: Expected growth rate
"""
function banks_expected_profits(model::AbstractModel)
    banks = model.banks
    pi_e, gamma_e = model.agg.pi_e, model.agg.gamma_e
    return banks.Pi_k .* (1 + pi_e) .* (1 + gamma_e)
end
function set_banks_expected_profits!(model::AbstractModel)
    return model.banks.Pi_e_k .= banks_expected_profits(model)
end

"""
    finance_insolvent_firms!(model)

Re-finance insolvent firms using their bank's equity.
"""
function finance_insolvent_firms!(model::AbstractModel)
    firms, banks = model.firms, model.banks
    P_bar_CF, zeta_b = model.agg.P_bar_CF, model.prop.zeta_b

    for i in eachfirm(model)
        # firm is insolvent
        if firms.D_i[i] < 0 && firms.E_i[i] < 0
            # finance insolvent firm from their assigned bank
            bank_id = firms.B_i[i]

            refinancing_amount = firms.L_i[i] - firms.D_i[i] - zeta_b * P_bar_CF * firms.K_i[i]
            banks.E_k[bank_id] = banks.E_k[bank_id] - refinancing_amount

            # set variables of newly created firm
            firms.E_i[i] = firms.E_i[i] + refinancing_amount
            firms.L_i[i] = zeta_b * P_bar_CF * firms.K_i[i]
            firms.D_i[i] = 0.0
        end
    end
    return
end

"""
    banks_deposits(model)

Calculate the new deposits of the banks.

# Returns
- `D_k`: New deposits of the banks

The new deposits `D_k` are calculated as the sum of the deposits of the active workers, the inactive workers,
the firms, and the bank owner itself, plus the bank's equity, minus the loans of the firms.
"""
function banks_deposits(model)
    banks = model.banks
    w_act, w_inact, firms = model.w_act, model.w_inact, model.firms
    D_k = zeros(typeFloat, length(model.banks))
    for bank_id in eachbank(model)
        fL_i = typeFloat[f.L_i for f in model.banks.firms[bank_id]]
        fD_i = typeFloat[f.D_i for f in model.banks.firms[bank_id]]
        fD_h = typeFloat[f.D_h for f in model.banks.firms[bank_id]]
        waD_h = typeFloat[w.D_h for w in model.banks.w_act[bank_id]]
        wiD_h = typeFloat[w.D_h for w in model.banks.w_inact[bank_id]]
        bD_h = banks.D_h[bank_id]
        bE_k = banks.E_k[bank_id]

        tot_D_h = sum(waD_h) + sum(wiD_h) + sum(fD_h) + bD_h
        D_k[bank_id] = sum(fD_i) + tot_D_h + bE_k - sum(fL_i)
    end
    return D_k
end
function set_banks_deposits!(model)
    return model.banks.D_k .= banks_deposits(model)
end
