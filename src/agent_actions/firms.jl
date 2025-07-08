
function cost_push_inflation(firms::AbstractFirms, model::AbstractModel)
    # unpack non-firm variables
    P_bar_HH = model.agg.P_bar_HH
    P_bar_CF = model.agg.P_bar_CF
    P_bar_g = model.agg.P_bar_g
    tau_SIF = model.prop.tau_SIF
    a_sg = model.prop.a_sg

    # compute the cost-push inflation
    term = dropdims(sum(a_sg[:, realpart.(firms.G_i)] .* P_bar_g, dims=1), dims=1)
    
    labour_costs = (1+tau_SIF) .* firms.w_bar_i ./ firms.alpha_bar_i .* (P_bar_HH ./ firms.P_i .- 1)
    material_costs = 1 ./ firms.beta_i .* (term ./ firms.P_i .- 1)
    capital_costs = firms.delta_i ./ firms.kappa_i .* (P_bar_CF ./ firms.P_i .- 1)
    cost_push_inflation = labour_costs .+ material_costs .+ capital_costs
    return cost_push_inflation
end

function desired_capital_material_employment(firms::AbstractFirms, Q_s_i)
    
    # target investments in capital
    I_d_i = firms.delta_i ./ firms.kappa_i .* min(Q_s_i, firms.K_i .* firms.kappa_i)

    # intermediate goods to purchase
    DM_d_i = min.(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.beta_i

    # target employment
    N_d_i = max.(1.0, round.(min(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.alpha_bar_i))
    return I_d_i, DM_d_i, N_d_i
end

function expected_deposits_capital_loans(firms::AbstractFirms, model::AbstractModel, Pi_e_i)
    # unpack non-firm variables
    tau_FIRM = model.prop.tau_FIRM
    theta = model.prop.theta
    theta_DIV = model.prop.theta_DIV
    P_bar_CF = model.agg.P_bar_CF
    pi_e = model.agg.pi_e

    # expected deposits
    DD_e_i =
        Pi_e_i .- theta .* firms.L_i .- tau_FIRM .* max.(0, Pi_e_i) .- (theta_DIV .* (1 .- tau_FIRM)) .* max.(0, Pi_e_i) # expected future cash flow
    
    # expected capital
    K_e_i = P_bar_CF .* (1 + pi_e) .* firms.K_i

    # expected loans
    L_e_i = (1 - theta) .* firms.L_i

    return DD_e_i, K_e_i, L_e_i
end

"""
    firms_expectations_and_decisions(firms, model)

Calculate the expectations and decisions of firms.
That is: compute firm quantity, price, investment and intermediate-goods, 
employment decisions, expected profits, and desired/expected loans and capital.


# Arguments
- `firms`: Firms object
- `model`: Model object

# Returns
- `Q_s_i`: Vector of desired quantities
- `I_d_i`: Vector of desired investments
- `DM_d_i`: Vector of desired intermediate goods
- `N_d_i`: Vector of desired employment
- `Pi_e_i`: Vector of expected profits
- `DL_d_i`: Vector of desired new loans
- `K_e_i`: Vector of expected capital
- `L_e_i`: Vector of expected loans
- `P_i`: Vector of  prices
"""
function firms_expectations_and_decisions(firms, model)
    # unpack variables not related to firms
    gamma_e = model.agg.gamma_e
    pi_e = model.agg.pi_e

    # target quantity
    Q_s_i = firms.Q_d_i * (1 + gamma_e)

    # cost put inflation
    pi_c_i = cost_push_inflation(firms, model) 

    # price setting
    new_P_i = firms.P_i .* (1 .+ pi_c_i) .* (1 + pi_e)

    # target investments in capital, intermediate goods to purchase and employment
    I_d_i, DM_d_i, N_d_i = desired_capital_material_employment(firms, Q_s_i)

    # expected profits 
    Pi_e_i = firms.Pi_i .* (1 + pi_e) * (1 + gamma_e)

    # expected deposits, capital and loans
    DD_e_i, K_e_i, L_e_i = expected_deposits_capital_loans(firms, model, Pi_e_i)
    
    # target loans
    DL_d_i = max.(0, -DD_e_i - firms.D_i)

    return Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, new_P_i
end

"""
    firms_wages(firms)

Calculate the wages set by firms.

# Arguments
- `firms`: Firms object

# Returns
- `w_i`: Vector of wages
"""
function firms_wages(firms::AbstractFirms)

    Q_s_i = firms.Q_s_i

    w_i =
        firms.w_bar_i .*
        min.(
            1.5,
            min.(Q_s_i, min.(firms.K_i .* firms.kappa_i, firms.M_i .* firms.beta_i)) ./
            (firms.N_i .* firms.alpha_bar_i),
        )
    return w_i
end

"""
    firms_production(firms)

Calculate the production of firms.

# Arguments
- `firms`: Firms object

# Returns
- `Y_i`: Vector of production

The production `Y_i` is computed using a Leontief technology.
"""
function firms_production(firms::AbstractFirms)
    Q_s_i = firms.Q_s_i
    # compute productivity of labour
    alpha_i =
        firms.alpha_bar_i .*
        min.(
            1.5,
            min.(Q_s_i, min.(firms.K_i .* firms.kappa_i, firms.M_i .* firms.beta_i)) ./
            (firms.N_i .* firms.alpha_bar_i),
        )

    # compute production function of firms (Leontief technology)
    Y_i = leontief_production(Q_s_i, firms.N_i, alpha_i, firms.K_i, firms.kappa_i, firms.M_i, firms.beta_i)

    return Y_i

end

"""
    leontief_production(Q_s_i, N_i, alpha_i, K_i, kappa_i, M_i, beta_i)

Calculate the production function of firms.

# Arguments
- `Q_s_i`: Vector of desired quantities
- `N_i`: Vector of employment
- `alpha_i`: Vector of labour productivity
- `K_i`: Vector of capital stock
- `kappa_i`: Vector of capital productivity
- `M_i`: Vector of intermediate goods
- `beta_i`: Vector of intermediate goods productivity

# Returns
- `Y_i`: Vector of production

The Leontief production function `Y_i` is calculated as follows:

```math
Y_i = \\min(Q_s_i, \\min(N_i \\cdot \\alpha_i, \\min(K_i \\cdot \\kappa_i, M_i \\cdot \\beta_i)))
```
"""
function leontief_production(Q_s_i, N_i, alpha_i, K_i, kappa_i, M_i, beta_i)
    Y_i = min.(Q_s_i, min.(N_i .* alpha_i, min.(K_i .* kappa_i, M_i .* beta_i)))
    return Y_i
end


"""
    firms_profits(firms, model)

Calculate the profits of firms.

# Arguments
- `firms`: Firms object
- `model`: Model object

# Returns
- `Pi_i`: Vector of profits

The profits `Pi_i` are calculated as follows:

```julia
Pi_i = in_sales + in_deposits - out_wages - out_expenses - out_depreciation - out_taxes_prods - out_taxes_capital - out_loans
```

where:
- `in_sales = P_i * Q_i + P_i * DS_i`
- `in_deposits = r_bar * pos(D_i)`
- `out_wages = (1 + tau_SIF) * w_i * N_i * P_bar_HH`
- `out_expenses = 1 / beta_i * P_bar_i * Y_i`
- `out_depreciation = delta_i / kappa_i * P_CF_i * Y_i`
- `out_taxes_prods = tau_Y_i * P_i * Y_i`
- `out_taxes_capital = tau_K_i * P_i * Y_i`
- `out_loans = r * (L_i + pos(-D_i))`
"""
function firms_profits(firms::AbstractFirms, model::AbstractModel)

    # unpack variables not related to firms
    P_bar_HH = model.agg.P_bar_HH
    tau_SIF = model.prop.tau_SIF
    r = model.bank.r
    r_bar = model.cb.r_bar

    in_sales = firms.P_i .* firms.Q_i .+ firms.P_i .* firms.DS_i
    in_deposits = r_bar .* pos(firms.D_i)
    out_wages = (1.0 + tau_SIF) .* firms.w_i .* firms.N_i .* P_bar_HH
    out_expenses = 1.0 ./ firms.beta_i .* firms.P_bar_i .* firms.Y_i
    out_depreciation = firms.delta_i ./ firms.kappa_i .* firms.P_CF_i .* firms.Y_i
    out_taxes_prods = firms.tau_Y_i .* firms.P_i .* firms.Y_i
    out_taxes_capital = firms.tau_K_i .* firms.P_i .* firms.Y_i
    out_loans = r .* (firms.L_i .+ pos(-firms.D_i))

    Pi_i =
        in_sales + in_deposits - out_wages - out_expenses - out_depreciation - out_taxes_prods - out_taxes_capital -
        out_loans

    return Pi_i
end

"""
    firms_deposits(firms, model)

Calculate the new deposits of firms.

# Arguments
- `firms`: Firms object
- `model`: Model object

# Returns
- `DD_i`: Vector of new deposits

The new deposits `DD_i` are calculated as follows:

```julia
DD_i = sales + labour_cost + material_cost + taxes_products + taxes_production + corporate_tax + dividend_payments + interest_payments + interest_received + investment_cost + new_credit + debt_installment
```

where:
- `sales = P_i * Q_i`
- `labour_cost = (1 + tau_SIF) * w_i * N_i * P_bar_HH`
- `material_cost = -DM_i * P_bar_i`
- `taxes_products = -tau_Y_i * P_i * Y_i`
- `taxes_production = -tau_K_i * P_i * Y_i`
- `corporate_tax = -tau_FIRM * pos(Pi_i)`
- `dividend_payments = -theta_DIV * (1 - tau_FIRM) * pos(Pi_i)`
- `interest_payments = -r * (L_i + pos(-D_i))`
- `interest_received = r_bar * pos(D_i)`
- `investment_cost = -P_CF_i * I_i`
- `new_credit = DL_i`
- `debt_installment = -theta * L_i`
"""
function firms_deposits(firms, model)

    # unpack arguments not related to firms
    tau_FIRM = model.prop.tau_FIRM
    tau_SIF = model.prop.tau_SIF
    theta_DIV = model.prop.theta_DIV
    theta = model.prop.theta

    r = model.bank.r
    r_bar = model.cb.r_bar
    P_bar_HH = model.agg.P_bar_HH


    sales = firms.P_i .* firms.Q_i
    labour_cost = -(1 + tau_SIF) * firms.w_i .* firms.N_i * P_bar_HH
    material_cost = -firms.DM_i .* firms.P_bar_i
    taxes_products = -firms.tau_Y_i .* firms.P_i .* firms.Y_i
    taxes_production = -firms.tau_K_i .* firms.P_i .* firms.Y_i
    corporate_tax = -tau_FIRM .* pos.(firms.Pi_i)
    dividend_payments = -theta_DIV .* (1 - tau_FIRM) .* pos.(firms.Pi_i)
    interest_payments = -r .* (firms.L_i .+ pos.(-firms.D_i))
    interest_received = +r_bar .* pos.(firms.D_i)
    investment_cost = -firms.P_CF_i .* firms.I_i
    new_credit = +firms.DL_i
    debt_installment = -theta .* firms.L_i

    DD_i =
        sales +
        labour_cost +
        material_cost +
        taxes_products +
        taxes_production +
        corporate_tax +
        dividend_payments +
        interest_payments +
        interest_received +
        investment_cost +
        new_credit +
        debt_installment

    D_i = firms.D_i .+ DD_i
    return D_i
end

"""
    firms_equity(firms, model)

Calculate the equity of firms.

# Arguments
- `firms`: Firms object
- `model`: Model object

# Returns
- `E_i`: Vector of equity

The equity `E_i` is calculated as follows:

```math
E_i = D_i + M_i * \\sum(a_{sg}[:, G_i] * \\bar{P}_g) + P_i * S_i + \\bar{P}_{CF} * K_i - L_i
```

where:
- `D_i`: Deposits
- `M_i`: Intermediate goods
- `a_sg`: Technology coefficient of the gth product in the sth industry
- `G_i`: Vector of goods
- `P_bar_g`: Producer price index for principal good g
- `P_i`: Price
- `S_i`: Stock
- `P_bar_CF`: Capital price index
- `K_i`: Capital stock
- `L_i`: Loans
"""
function firms_equity(firms, model)

    # unpack variables not related to firms
    a_sg = model.prop.a_sg
    P_bar_g = model.agg.P_bar_g
    P_bar_CF = model.agg.P_bar_CF

    E_i =
        firms.D_i + firms.M_i .* sum(a_sg[:, realpart.(firms.G_i)] .* P_bar_g, dims = 1)' .+ firms.P_i .* firms.S_i +
        P_bar_CF * firms.K_i - firms.L_i

    return E_i
end

"""
    firms_loans(firms, model)

Calculate the new loans of firms.

# Arguments
- `firms`: Firms object
- `model`: Model object

# Returns
- `L_i`: Vector of new loans

The new loans `L_i` are calculated as follows:

```math
L_i = (1 - theta) * L_i + DL_i
```

where:
- `theta`: Rate of repayment
- `L_i`: Loans
- `DL_i`: Acquired new loans
"""
function firms_loans(firms, model)
    theta = model.prop.theta
    L_i = (1 - theta) * firms.L_i + firms.DL_i
    return L_i
end

"""
    firms_stocks(firms)

Calculate the stocks of firms.

# Arguments
- `firms`: Firms object

# Returns
- `K_i`: Vector of capital stock
- `M_i`: Vector of intermediate goods
- `DS_i`: Vector of differneces in stock of final goods
- `S_i`: Vector of stock of final goods

The stocks are calculated as follows:

```julia
K_i = K_i - delta_i / kappa_i * Y_i + I_i
M_i = M_i - Y_i / beta_i + DM_i
DS_i = Y_i - Q_i
S_i = S_i + DS_i
```
"""
function firms_stocks(firms)
    # depreciate firms capital stock
    K_i = firms.K_i - firms.delta_i ./ firms.kappa_i .* firms.Y_i + firms.I_i

    # update firms intermediate goods and materials
    M_i = firms.M_i - firms.Y_i ./ firms.beta_i + firms.DM_i

    # compute stock of consumer goods (DS_i = production - sales) 
    DS_i = firms.Y_i - firms.Q_i
    S_i = firms.S_i + DS_i

    return K_i, M_i, DS_i, S_i
end
