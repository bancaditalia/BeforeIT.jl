"""
--------- CANVAS model by overwriting ---------

There are 4 major changes from the Poledna et al. (2023) to the CANVAS model (Hommes et al., 2025)

1) Increased heterogeneity with respect to consumer behaviour and initiasation
2) Increased heterogeniety with respect to firm initialisation
3) Demand pull firm level price and quanitity setting
4) Adaptive learning for the central bank to learn the parameters of the Taylor rule

This script implements changes 3 and 4 by overwriting the methods that govern that behaviour. 
To introduce changes 1 and 2 we need dissagregated data at the household and firm level.
"""

import BeforeIT as Bit
using Plots, Dates, FileIO


T = 12

year_i = 2019
quarter = 1

function Bit.get_params_and_initial_conditions(calibration_object, calibration_date; scale = 0.001)
    calibration_data = calibration_object.calibration
    figaro = calibration_object.figaro
    data = calibration_object.data
    ea = calibration_object.ea
    max_calibration_date = calibration_object.max_calibration_date
    estimation_date = calibration_object.estimation_date

    # Calculate GDP deflator from levels
    data["gdp_deflator_quarterly"] = data["nominal_gdp_quarterly"] ./ data["real_gdp_quarterly"]
    ea["gdp_deflator_quarterly"] = ea["nominal_gdp_quarterly"] ./ ea["real_gdp_quarterly"]


    T_calibration = findall(
        calibration_data["years_num"] .== date2num(DateTime(year(min(calibration_date, max_calibration_date)), 12, 31)),
    )[1][1]
    T_calibration_quarterly = findall(calibration_data["quarters_num"] .== date2num(calibration_date))[1][2] # TODO: This indexing might not be correct
    T_estimation_exo = findall(data["quarters_num"] .== date2num(estimation_date))[1][1]
    T_calibration_exo = findall(data["quarters_num"] .== date2num(calibration_date))[1][1]
    T_calibration_exo_max = length(data["quarters_num"])
    intermediate_consumption = figaro["intermediate_consumption"][:, :, T_calibration]
    household_consumption = figaro["household_consumption"][:, T_calibration]
    fixed_capitalformation = figaro["fixed_capitalformation"][:, T_calibration]
    exports = figaro["exports"][:, T_calibration]
    compensation_employees = figaro["compensation_employees"][:, T_calibration]
    household_cash_quarterly = calibration_data["household_cash_quarterly"][T_calibration_quarterly]
    property_income = calibration_data["property_income"][T_calibration]
    mixed_income = calibration_data["mixed_income"][T_calibration]
    operating_surplus = figaro["operating_surplus"][:, T_calibration]
    firm_cash_quarterly = calibration_data["firm_cash_quarterly"][T_calibration_quarterly]
    firm_debt_quarterly = calibration_data["firm_debt_quarterly"][T_calibration_quarterly]
    firm_interest = calibration_data["firm_interest"][T_calibration]
    government_debt_quarterly = calibration_data["government_debt_quarterly"][T_calibration_quarterly]
    interest_government_debt = calibration_data["interest_government_debt"][T_calibration]
    government_consumption = figaro["government_consumption"][:, T_calibration]
    social_benefits = calibration_data["social_benefits"][T_calibration]
    unemployment_benefits = calibration_data["unemployment_benefits"][T_calibration]
    pension_benefits = calibration_data["pension_benefits"][T_calibration]
    corporate_tax = calibration_data["corporate_tax"][T_calibration]
    wages = calibration_data["wages"][T_calibration]
    taxes_products_household = figaro["taxes_products_household"][T_calibration]
    social_contributions = calibration_data["social_contributions"][T_calibration]
    income_tax = calibration_data["income_tax"][T_calibration]
    capital_taxes = calibration_data["capital_taxes"][T_calibration]
    taxes_products_fixed_capitalformation = figaro["taxes_products_capitalformation"][T_calibration]
    taxes_production = figaro["taxes_production"][:, T_calibration]
    taxes_products_government = figaro["taxes_products_government"][T_calibration]
    bank_equity_quarterly = calibration_data["bank_equity_quarterly"][T_calibration_quarterly]
    taxes_products = figaro["taxes_products"][:, T_calibration]
    government_deficit = calibration_data["government_deficit"][T_calibration]
    firms = calibration_data["firms"][:, T_calibration]
    employees = calibration_data["employees"][:, T_calibration]
    population = calibration_data["population"][T_calibration]
    r_bar = (data["euribor"][T_calibration_exo] .+ 1.0) .^ (1.0 / 4.0) .- 1

    omega = 0.85
    fixed_assets = calibration_data["fixed_assets"][T_calibration]
    dwellings = calibration_data["dwellings"][T_calibration]
    fixed_assets_eu7 = calibration_data["fixed_assets_eu7"][:, T_calibration]
    dwellings_eu7 = calibration_data["dwellings_eu7"][:, T_calibration]
    nominal_nace64_output_eu7 = calibration_data["nominal_nace64_output_eu7"][:, T_calibration]
    gross_capitalformation_dwellings = calibration_data["gross_capitalformation_dwellings"][T_calibration]
    nace64_capital_consumption = calibration_data["nace64_capital_consumption"][:, T_calibration]
    nominal_nace64_output = calibration_data["nominal_nace64_output"][:, T_calibration]
    unemployment_rate_quarterly = data["unemployment_rate_quarterly"][T_calibration_exo]


    # Calculate variables from accounting indentities
    output =
        sum(intermediate_consumption, dims = 1)' .+ taxes_products .+ taxes_production .+ compensation_employees .+
        operating_surplus# .+ capital_consumption #TODO: check whether this is this needed or not
    output = output[:, 1]

    capital_consumption = nace64_capital_consumption ./ nominal_nace64_output .* output
    operating_surplus = operating_surplus - capital_consumption
    taxes_products_export = 0 # TODO: unelegant hard coded zero
    employers_social_contributions = min(social_contributions, sum(compensation_employees) - wages)
    fixed_capitalformation = Bit.pos(fixed_capitalformation)
    taxes_products_capitalformation_dwellings =
        gross_capitalformation_dwellings *
        (1 - 1 / (1 + taxes_products_fixed_capitalformation / sum(fixed_capitalformation)))
    timescale =
        data["nominal_gdp_quarterly"][T_calibration_exo] / (
            sum(
                compensation_employees .+ operating_surplus .+ capital_consumption .+ taxes_production .+
                taxes_products,
            ) .+ taxes_products_household .+ taxes_products_capitalformation_dwellings .+ taxes_products_government .+
            taxes_products_export
        )
    fixed_assets_other_than_dwellings =
        (fixed_assets - dwellings) * ((fixed_assets_eu7 - dwellings_eu7) ./ nominal_nace64_output_eu7 .* output) /
        sum((fixed_assets_eu7 - dwellings_eu7) ./ nominal_nace64_output_eu7 .* output)
    capitalformation_dwellings =
        (gross_capitalformation_dwellings - taxes_products_capitalformation_dwellings) * fixed_capitalformation /
        sum(fixed_capitalformation)
    fixed_capital_formation_other_than_dwellings = fixed_capitalformation - capitalformation_dwellings
    exports = Bit.pos(exports)
    imports = Bit.pos(
        sum(intermediate_consumption, dims = 2) +
        household_consumption +
        government_consumption +
        fixed_capital_formation_other_than_dwellings * sum(capital_consumption) /
        sum(fixed_capital_formation_other_than_dwellings) +
        capitalformation_dwellings +
        exports - output,
    )
    reexports = Bit.neg(
        sum(intermediate_consumption, dims = 2) +
        household_consumption +
        government_consumption +
        fixed_capital_formation_other_than_dwellings * sum(capital_consumption) /
        sum(fixed_capital_formation_other_than_dwellings) +
        capitalformation_dwellings +
        exports - output,
    )
    household_social_contributions = social_contributions - employers_social_contributions
    wages = compensation_employees * (1 - employers_social_contributions / sum(compensation_employees)) # Note: owerwrighting the wages variable here!
    household_income_tax = income_tax - corporate_tax
    other_net_transfers = Bit.pos(
        sum(taxes_products_household) +
        sum(taxes_products_capitalformation_dwellings) +
        sum(taxes_products_export) +
        sum(taxes_products) +
        sum(taxes_production) +
        employers_social_contributions +
        household_social_contributions +
        household_income_tax +
        corporate_tax +
        capital_taxes - social_benefits - sum(government_consumption) - interest_government_debt -
        government_deficit,
    )
    disposable_income =
        sum(wages) + mixed_income + property_income + social_benefits + other_net_transfers -
        household_social_contributions - household_income_tax - capital_taxes
    unemployed = matlab_round(unemployment_rate_quarterly * sum(employees))
    inactive = population - sum(max.(max.(1, firms), employees)) - unemployed - sum(max.(1, firms)) - 1


    # Scale number of firms and employees
    firms = max.(1, matlab_round.(scale * firms))
    employees = max.(firms, matlab_round.(scale * employees))
    inactive = max.(1, matlab_round.(scale * inactive))
    unemployed = max.(1, matlab_round.(scale * unemployed))


    # Sector parameters
    I_s = firms
    alpha_s = timescale * output ./ employees
    beta_s = output ./ sum(intermediate_consumption, dims = 1)'
    kappa_s = timescale * output ./ fixed_assets_other_than_dwellings / omega
    delta_s = timescale * capital_consumption ./ fixed_assets_other_than_dwellings / omega
    replace!(delta_s, NaN => 0.0)
    w_s = timescale * wages ./ employees
    tau_Y_s = taxes_products ./ output
    tau_K_s = taxes_production ./ output
    b_CF_g = fixed_capital_formation_other_than_dwellings / sum(fixed_capital_formation_other_than_dwellings)
    b_CFH_g = capitalformation_dwellings / sum(capitalformation_dwellings)
    b_HH_g = household_consumption / sum(household_consumption)
    a_sg = intermediate_consumption ./ sum(intermediate_consumption, dims = 1)
    replace!(a_sg, NaN => 0.0)
    c_G_g = government_consumption / sum(government_consumption)
    c_E_g = (exports - reexports) / sum(exports - reexports)
    c_I_g = imports / sum(imports)


    # Parameters
    T_prime = T_calibration_exo - T_estimation_exo + 1
    T = 12
    T_max = T - max(0, T_calibration_exo + T - T_calibration_exo_max)
    G = size(intermediate_consumption)[1]
    S = G
    H_act = sum(employees) + unemployed + sum(firms) + 1
    H_inact = inactive
    J = matlab_round(sum(firms) / 4)
    L = matlab_round(sum(firms) / 2)
    mu = timescale * firm_interest / firm_debt_quarterly - r_bar
    tau_INC =
        (household_income_tax + capital_taxes) /
        (sum(wages) + property_income + mixed_income - household_social_contributions)
    tau_FIRM =
        timescale * corporate_tax / (
            sum(
                Bit.pos(
                    timescale * operating_surplus -
                    timescale * firm_interest * fixed_assets_other_than_dwellings /
                    sum(fixed_assets_other_than_dwellings) +
                    r_bar * firm_cash_quarterly * Bit.pos(operating_surplus) /
                    sum(Bit.pos(operating_surplus)),
                ),
            ) + timescale * firm_interest - r_bar * (firm_debt_quarterly - bank_equity_quarterly)
        )
    tau_VAT = taxes_products_household / sum(household_consumption)
    tau_SIF = employers_social_contributions / sum(wages)
    tau_SIW = household_social_contributions / sum(wages)
    tau_EXPORT = sum(taxes_products_export) / sum(exports - reexports)
    tau_CF = sum(taxes_products_capitalformation_dwellings) / sum(capitalformation_dwellings)
    tau_G = sum(taxes_products_government) / sum(government_consumption)
    psi = (sum(household_consumption) + sum(taxes_products_household)) / disposable_income
    psi_H = (sum(capitalformation_dwellings) + sum(taxes_products_capitalformation_dwellings)) / disposable_income
    theta_DIV =
        timescale * (mixed_income + property_income) / (
            sum(
                Bit.pos(
                    timescale * operating_surplus -
                    timescale * firm_interest * fixed_assets_other_than_dwellings /
                    sum(fixed_assets_other_than_dwellings) +
                    r_bar * firm_cash_quarterly * Bit.pos(operating_surplus) /
                    sum(Bit.pos(operating_surplus)),
                ),
            ) + timescale * firm_interest - r_bar * (firm_debt_quarterly - bank_equity_quarterly) -
            timescale * corporate_tax
        )
    r_G = timescale * interest_government_debt / government_debt_quarterly
    theta_UB = 0.55 * (1 - tau_INC) * (1 - tau_SIW)
    theta = 0.05
    zeta = 0.03
    zeta_LTV = 0.6
    zeta_b = 0.5

    alpha_pi_EA, beta_pi_EA, sigma_pi_EA, epsilon_pi_EA = Bit.estimate_for_calibration_script(
        diff(log.(ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo])),
    )
    alpha_Y_EA, beta_Y_EA, sigma_Y_EA, epsilon_Y_EA =
        Bit.estimate_for_calibration_script(log.(ea["real_gdp_quarterly"][T_estimation_exo:T_calibration_exo]))

    a1 = (data["euribor"][T_estimation_exo:T_calibration_exo] .+ 1) .^ (1 / 4) .- 1
    a2 = exp.(diff(log.(ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))) .- 1
    a3 = exp.(diff(log.(ea["real_gdp_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))) .- 1

    rho, r_star, xi_pi, xi_gamma, pi_star = Bit.estimate_taylor_rule(a1, a2, a3)


    G_est =
        timescale * sum(government_consumption) .*
        data["real_government_consumption_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_government_consumption_quarterly"][T_calibration_exo]
    G_est = log.(G_est)

    E_est =
        timescale * sum(exports - reexports) .* data["real_exports_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_exports_quarterly"][T_calibration_exo]
    E_est = log.(E_est)

    I_est =
        timescale * sum(imports) .* data["real_imports_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_imports_quarterly"][T_calibration_exo]
    I_est = log.(I_est)

    alpha_G, beta_G, sigma_G, epsilon_G = Bit.estimate_for_calibration_script(G_est)
    alpha_E, beta_E, sigma_E, epsilon_E = Bit.estimate_for_calibration_script(E_est)
    alpha_I, beta_I, sigma_I, epsilon_I = Bit.estimate_for_calibration_script(I_est)

    C = cov([epsilon_Y_EA epsilon_E epsilon_I])

    # define a dictionary of parameters to save in jld2 format
    params = [
        ("T", T),
        ("T_max", T_max),
        ("S", S),
        ("G", G),
        ("H_act", H_act),
        ("H_inact", H_inact),
        ("J", J),
        ("L", L),
        ("tau_INC", tau_INC),
        ("tau_FIRM", tau_FIRM),
        ("tau_VAT", tau_VAT),
        ("tau_SIF", tau_SIF),
        ("tau_SIW", tau_SIW),
        ("tau_EXPORT", tau_EXPORT),
        ("tau_CF", tau_CF),
        ("tau_G", tau_G),
        ("theta_UB", theta_UB),
        ("psi", psi),
        ("psi_H", psi_H),
        ("theta_DIV", theta_DIV),
        ("theta", theta),
        ("mu", mu),
        ("r_G", r_G),
        ("zeta", zeta),
        ("zeta_LTV", zeta_LTV),
        ("zeta_b", zeta_b),
        ("I_s", I_s),
        ("alpha_s", alpha_s),
        ("beta_s", beta_s),
        ("kappa_s", kappa_s),
        ("delta_s", delta_s),
        ("w_s", w_s),
        ("tau_Y_s", tau_Y_s),
        ("tau_K_s", tau_K_s),
        ("b_CF_g", b_CF_g),
        ("b_CFH_g", b_CFH_g),
        ("b_HH_g", b_HH_g),
        ("c_G_g", c_G_g),
        ("c_E_g", c_E_g),
        ("c_I_g", c_I_g),
        ("a_sg", a_sg),
        ("T_prime", T_prime),
        ("alpha_pi_EA", alpha_pi_EA),
        ("beta_pi_EA", beta_pi_EA),
        ("sigma_pi_EA", sigma_pi_EA),
        ("alpha_Y_EA", alpha_Y_EA),
        ("beta_Y_EA", beta_Y_EA),
        ("sigma_Y_EA", sigma_Y_EA),
        ("rho", rho),
        ("r_star", r_star),
        ("xi_pi", xi_pi),
        ("xi_gamma", xi_gamma),
        ("pi_star", pi_star),
        ("alpha_G", alpha_G),
        ("beta_G", beta_G),
        ("sigma_G", sigma_G),
        ("alpha_E", alpha_E),
        ("beta_E", beta_E),
        ("sigma_E", sigma_E),
        ("alpha_I", alpha_I),
        ("beta_I", beta_I),
        ("sigma_I", sigma_I),
        ("C", C),
    ]

    params = Dict(params)

    # Sector initial conditions
    N_s = employees
    D_I = firm_cash_quarterly
    L_I = firm_debt_quarterly
    w_UB = timescale * unemployment_benefits / unemployed
    sb_inact = timescale * pension_benefits / inactive
    sb_other =
        timescale * (social_benefits + other_net_transfers - unemployment_benefits - pension_benefits) /
        (sum(employees) + unemployed + inactive + sum(firms) + 1)
    D_H = household_cash_quarterly
    K_H = sum(dwellings)
    L_G = government_debt_quarterly
    E_k = bank_equity_quarterly
    E_CB = L_G + L_I - D_I - D_H - E_k
    D_RoW = 0.0

    # Initial conditions
    Y =
        timescale * sum(output) .* data["real_gdp_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_gdp_quarterly"][T_calibration_exo]
    pi = diff(log.(data["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))
    Y_EA = ea["real_gdp_quarterly"][T_calibration_exo]
    pi_EA = ea["gdp_deflator_quarterly"][T_calibration_exo] / ea["gdp_deflator_quarterly"][T_calibration_exo - 1] - 1

    # new data series for CANVAS
    Y_EA_series = timescale * sum(output) .* ea["real_gdp_quarterly"][T_estimation_exo:T_calibration_exo] ./
    ea["real_gdp_quarterly"][T_calibration_exo]
    pi_EA_series = diff(log.(ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))
    r_bar_series = r_bar_series = (data["euribor"][T_estimation_exo:T_calibration_exo] .+ 1.0) .^ (1.0 / 4.0) .- 1


    C_G = [
        timescale *
        sum(government_consumption) *
        data["real_government_consumption_quarterly"][T_estimation_exo:min(
            T_calibration_exo + T,
            T_calibration_exo_max,
        )] / data["real_government_consumption_quarterly"][T_calibration_exo]
        fill(NaN, max(0, T_calibration_exo + T - T_calibration_exo_max), 1)
    ]
    C_E = [
        timescale *
        sum(exports - reexports) *
        data["real_exports_quarterly"][T_estimation_exo:min(T_calibration_exo + T, T_calibration_exo_max)] /
        data["real_exports_quarterly"][T_calibration_exo]
        fill(NaN, max(0, T_calibration_exo + T - T_calibration_exo_max), 1)
    ]
    Y_I = [
        timescale *
        sum(imports) *
        data["real_imports_quarterly"][T_estimation_exo:min(T_calibration_exo + T, T_calibration_exo_max)] /
        data["real_imports_quarterly"][T_calibration_exo]
        fill(NaN, max(0, T_calibration_exo + T - T_calibration_exo_max), 1)
    ]

    # define a dictionary of parameters to save in jld2 format
    initial_conditions = [
        ("D_I", D_I),
        ("L_I", L_I),
        ("omega", omega),
        ("w_UB", w_UB),
        ("sb_inact", sb_inact),
        ("sb_other", sb_other),
        ("D_H", D_H),
        ("K_H", K_H),
        ("L_G", L_G),
        ("E_k", E_k),
        ("E_CB", E_CB),
        ("D_RoW", D_RoW),
        ("N_s", N_s),
        ("Y", Y),
        ("pi", pi),
        ("Y_EA", Y_EA),
        ("pi_EA", pi_EA),
        ("r_bar", r_bar),
        ("Y_EA_series", Y_EA_series),
        ("pi_EA_series", pi_EA_series),
        ("r_bar_series", r_bar_series),
        ("C_G", C_G),
        ("C_E", C_E),
        ("Y_I", Y_I),
    ]
    initial_conditions = Dict(initial_conditions)

    return params, initial_conditions
end

cal = Bit.ITALY_CALIBRATION
start_calibration_date = DateTime(2010, 03, 31)
end_calibration_date = DateTime(2019, 12, 31)

date2num = Bit.date2num
matlab_round = Bit.matlab_round
cov = Bit.cov
randpl = Bit.randpl
Firms = Bit.Firms

for calibration_date in collect(start_calibration_date:Dates.Month(3):end_calibration_date)
    params, init_conds = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.0005)
    save(
        "data/italy/parameters/" *
        string(year(calibration_date)) *
        "Q" *
        string(Dates.quarterofyear(calibration_date)) *
        ".jld2",
        params,
    )
    save(
        "data/italy/initial_conditions/" *
        string(year(calibration_date)) *
        "Q" *
        string(Dates.quarterofyear(calibration_date)) *
        ".jld2",
        init_conds,
    )
end

parameters = load("data/italy/parameters/" * string(year_i) * "Q" * string(quarter) * ".jld2")
initial_conditions = load("data/italy/initial_conditions/" * string(year_i) * "Q" * string(quarter) * ".jld2")

# Overwrite initalisation to ensure that the necessary data is available
function Bit.init_aggregates(parameters, initial_conditions, T; typeInt = Int64, typeFloat = Float64)
    
    Y = initial_conditions["Y"]
    pi_ = initial_conditions["pi"]
    Y = Vector{typeFloat}(vec(vcat(Y, zeros(typeFloat, T))))
    pi_ = Vector{typeFloat}(vec(vcat(pi_, zeros(typeFloat, T))))

    Y_EA_series = initial_conditions["Y_EA_series"]
    pi_EA_series = initial_conditions["pi_EA_series"]
    r_bar_series = initial_conditions["r_bar_series"]
    Y_EA_series = Vector{typeFloat}(vec(vcat(Y_EA_series, zeros(typeFloat, T))))
    pi_EA_series = Vector{typeFloat}(vec(vcat(pi_EA_series, zeros(typeFloat, T))))
    r_bar_series = Vector{typeFloat}(vec(vcat(r_bar_series, zeros(typeFloat, T))))

    G = typeInt(parameters["G"])


    P_bar = one(typeFloat)
    P_bar_g = ones(typeFloat, G)
    P_bar_HH = one(typeFloat)
    P_bar_CF = one(typeFloat)

    P_bar_h = zero(typeFloat)
    P_bar_CF_h = zero(typeFloat)
    t = typeInt(1)
    Y_e = zero(typeFloat)
    gamma_e = zero(typeFloat)
    pi_e = zero(typeFloat)
    epsilon_Y_EA = zero(typeFloat)
    epsilon_E = zero(typeFloat)
    epsilon_I = zero(typeFloat)

    agg_args = (
        Y,
        pi_,
        P_bar,
        P_bar_g,
        P_bar_HH,
        P_bar_CF,
        P_bar_h,
        P_bar_CF_h,
        Y_e,
        gamma_e,
        pi_e,
        epsilon_Y_EA,
        epsilon_E,
        epsilon_I,
        t,
        Y_EA_series,
        pi_EA_series,
        r_bar_series,
    )

    agg = Bit.Aggregates(agg_args...)

    return agg, agg_args
end

# Overwrite firm initialisation to prevent division by zero
function Bit.init_firms(parameters, initial_conditions; typeInt = Int64, typeFloat = Float64)

    # unpacking useful parameters
    I_s = Vector{typeInt}(vec(parameters["I_s"]))
    I = typeInt(sum(parameters["I_s"])) # number of firms
    G = typeInt(parameters["G"])
    tau_SIF = parameters["tau_SIF"]
    mu = parameters["mu"]
    theta_DIV = parameters["theta_DIV"]
    tau_INC = parameters["tau_INC"]
    tau_FIRM = parameters["tau_FIRM"]
    
    sb_other = initial_conditions["sb_other"]
    r_bar = initial_conditions["r_bar"]
    D_I = initial_conditions["D_I"]
    L_I = initial_conditions["L_I"]
    omega = initial_conditions["omega"]
    N_s = round.(Int, initial_conditions["N_s"])
    r_bar = initial_conditions["r_bar"]
    D_H = initial_conditions["D_H"]
    K_H = initial_conditions["K_H"]

    P_bar_HH = one(typeFloat)

    # computation of parameters for each firm
    alpha_bar_i = zeros(typeFloat, I)
    beta_i = zeros(typeFloat, I)
    kappa_i = zeros(typeFloat, I)
    w_bar_i = zeros(typeFloat, I)
    delta_i = zeros(typeFloat, I)
    tau_Y_i = zeros(typeFloat, I)
    tau_K_i = zeros(typeFloat, I)

    G_i = zeros(typeInt, I)
    for g in 1:G
        i = typeInt(sum(parameters["I_s"][1:(g - 1)]))
        j = typeInt(parameters["I_s"][g])
        G_i[(i + 1):(i + j)] .= typeInt(g)
    end

    for i in 1:I
        g = typeInt(G_i[i])
        alpha_bar_i[i] = parameters["alpha_s"][g]
        beta_i[i] = parameters["beta_s"][g]
        kappa_i[i] = parameters["kappa_s"][g]
        delta_i[i] = parameters["delta_s"][g]
        w_bar_i[i] = parameters["w_s"][g]
        tau_Y_i[i] = parameters["tau_Y_s"][g]
        tau_K_i[i] = parameters["tau_K_s"][g]
    end


    N_i = zeros(typeInt, I)
    for g in 1:G
        N_i[G_i .== g] .= randpl(I_s[g], 2.0, N_s[g])
    end


    Y_i = alpha_bar_i .* N_i
    Q_d_i = copy(Y_i)
    Q_s_i = copy(Y_i) # Initialise to Q_d_i, otherwise it will generate Infs
    P_i = ones(typeFloat, I)
    S_i = zeros(typeFloat, I)
    K_i = Y_i ./ (omega .* kappa_i)
    M_i = Y_i ./ (omega .* beta_i)
    L_i = L_I .* K_i / sum(K_i)

    pi_bar_i = 1 .- (1 + tau_SIF) .* w_bar_i ./ alpha_bar_i .- delta_i ./ kappa_i .- 1 ./ beta_i .- tau_K_i .- tau_Y_i
    D_i = D_I .* max.(0, pi_bar_i .* Y_i) / sum(max.(0, pi_bar_i .* Y_i))

    r = r_bar + mu
    Pi_i = pi_bar_i .* Y_i - r .* L_i + r_bar .* max.(0, D_i)

    V_i = copy(N_i)

    Y_h = zeros(typeFloat, I)
    for i in 1:I
        Y_h[i] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_i[i]) + sb_other * P_bar_HH
    end

    # firms
    ids = Vector{typeInt}(1:I)
    w_i = zeros(typeFloat, I) # initial wages, dummy variable for now, really initialised at runtime
    I_i = zeros(typeFloat, I) # initial investments, dummy variable for now, set at runtime
    Q_i = zeros(typeFloat, I) # goods sold, dummy variable for now, set at runtime
    E_i = zeros(typeFloat, I) # equity, dummy variable for now, set at runtime
    C_d_h = zeros(typeFloat, I)
    I_d_h = zeros(typeFloat, I)

    C_h = zeros(typeFloat, length(ids))
    I_h = zeros(typeFloat, length(ids))
    P_bar_i = zeros(typeFloat, length(ids))
    P_CF_i = zeros(typeFloat, length(ids))
    DS_i = zeros(typeFloat, length(ids))
    DM_i = zeros(typeFloat, length(ids))

    K_h = K_H * Y_h # TODO: K_h[(H_W + H_inact + 1):(H_W + H_inact + I)]
    D_h = D_H * Y_h # TODO: D_h[(H_W + H_inact + 1):(H_W + H_inact + I)]

    # additional tracking variables initialised to zero
    DL_i = zeros(typeFloat, I)
    DL_d_i = zeros(typeFloat, I)
    K_e_i = zeros(typeFloat, I)
    L_e_i = zeros(typeFloat, I)
    #Q_s_i = zeros(typeFloat, I)
    I_d_i = zeros(typeFloat, I)
    DM_d_i = zeros(typeFloat, I)
    N_d_i = zeros(typeInt, I)
    Pi_e_i = zeros(typeFloat, I)


    firms_args = (G_i, alpha_bar_i, beta_i, kappa_i, w_i, w_bar_i, delta_i, tau_Y_i, tau_K_i, N_i, Y_i, Q_i, Q_d_i, 
                      P_i, S_i, K_i, M_i, L_i, pi_bar_i, D_i, Pi_i, V_i, I_i, E_i, P_bar_i, P_CF_i, DS_i, DM_i, DL_i, 
                      DL_d_i, K_e_i, L_e_i, Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, Y_h, C_d_h, I_d_h, C_h, I_h, K_h, D_h)

    firms = Firms(firms_args...)
    return firms, firms_args
end


# Overwrite firm price and quantity setting mechanism
function Bit.firms_expectations_and_decisions(firms, model)

    # unpack non-firm variables
    tau_SIF = model.prop.tau_SIF
    tau_FIRM = model.prop.tau_FIRM
    theta = model.prop.theta
    theta_DIV = model.prop.theta_DIV
    P_bar_HH = model.agg.P_bar_HH
    P_bar_CF = model.agg.P_bar_CF
    P_bar_g = model.agg.P_bar_g
    a_sg = model.prop.products.a_sg
    gamma_e = model.agg.gamma_e
    pi_e = model.agg.pi_e

    # Individual firm quantity and price adjustments
    I = length(firms.G_i);
    gamma_d_i = zeros(I);
    pi_d_i = zeros(I);

    for i=1:I
        if firms.Q_s_i[i] <= firms.Q_d_i[i] && firms.P_i[i] >= P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i]-1;
            pi_d_i[i]=0;
        elseif firms.Q_s_i[i] <= firms.Q_d_i[i] && firms.P_i[i] < P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = 0;
            pi_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1;
        elseif firms.Q_s_i[i] > firms.Q_d_i[i] && firms.P_i[i] >= P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = 0;
            pi_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1;
        elseif firms.Q_s_i[i] > firms.Q_d_i[i] && firms.P_i[i] < P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1;
            pi_d_i[i] = 0;
        end
    end
    #pi_d_i = min.(pi_d_i, 0.3) # cap the price adjustment to 30%. Otherwise it can reach 200% in some cases

    Q_s_i = firms.Q_s_i .* (1 .+ gamma_e) .* (1 .+ gamma_d_i)

    # price setting
    # dividing equation for pi_c_i into smaller pieces
    pi_l_i = (1 + tau_SIF) .* firms.w_bar_i ./ firms.alpha_bar_i .* (P_bar_HH ./ firms.P_i .- 1)
    term = dropdims(sum(a_sg[:, firms.G_i] .* P_bar_g, dims = 1), dims = 1)
    pi_k_i = firms.delta_i ./ firms.kappa_i .* (P_bar_CF ./ firms.P_i .- 1)

    pi_m_i =  1 ./ firms.beta_i .* (term ./ firms.P_i .- 1)

    pi_c_i = pi_l_i .+ pi_k_i .+ pi_m_i

    new_P_i = firms.P_i .* (1 .+ pi_c_i) .* (1 + pi_e) .* (1 .+ pi_d_i)

    I_d_i = firms.delta_i ./ firms.kappa_i .* min(Q_s_i, firms.K_i .* firms.kappa_i)

    # intermediate goods to purchase
    DM_d_i = min.(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.beta_i

    # target employment
    N_d_i = max.(1.0, round.(min(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.alpha_bar_i))

    # expected profits 
    Pi_e_i = firms.Pi_i .* (1 + pi_e) * (1 + gamma_e)

    # target loans
    DD_e_i =
        Pi_e_i .- theta .* firms.L_i .- tau_FIRM .* max.(0, Pi_e_i) .- (theta_DIV .* (1 .- tau_FIRM)) .* max.(0, Pi_e_i) # expected future cash flow
    DL_d_i = max.(0, -DD_e_i - firms.D_i)

    # expected capital
    K_e_i = P_bar_CF .* (1 + pi_e) .* firms.K_i

    # expected loans
    L_e_i = (1 - theta) .* firms.L_i

    return Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, new_P_i, pi_d_i, pi_c_i, pi_l_i, pi_k_i, pi_m_i

end

# Overwrite the main loop to ensure that the central bank reupdates the Taylor rule parameters
function CANVAS_step!(model; multi_threading = false, shock = NoShock())

    gov = model.gov # government
    cb = model.cb # central bank
    rotw = model.rotw # rest of the world
    firms = model.firms # firms
    bank = model.bank # bank
    w_act = model.w_act # active workers
    w_inact = model.w_inact # inactive workers
    agg = model.agg # aggregates
    prop = model.prop # model properties

    # return an error if t is greater than T
    if agg.t > prop.T + 1
        error("The model has already reached the final time step.")
    end

    Bit.finance_insolvent_firms!(firms, bank, model)

    ####### GENERAL ESTIMATIONS #######
    # expectation on economic growth and inflation
    try
        agg.Y_e, agg.gamma_e, agg.pi_e = Bit.growth_inflation_expectations(model)
    catch e
        println("Error in growth and inflation expectations: ", e)
        println("Y: ", agg.Y, ", pi: ", agg.pi_)
    end
    # update growth and inflation of economic area

    agg.epsilon_Y_EA, agg.epsilon_E, agg.epsilon_I = Bit.epsilon(prop.C)

    rotw.Y_EA, rotw.gamma_EA, rotw.pi_EA = Bit.growth_inflation_EA(rotw, model)

    a1 = model.agg.r_bar_series[1:(prop.T_prime + agg.t - 1)]
    a2 = model.agg.Y_EA_series[1:(prop.T_prime + agg.t - 1)]
    a3 = model.agg.pi_EA_series[1:(prop.T_prime + agg.t - 1)]

    # update central bank parameters
    rho, r_star, xi_pi, xi_gamma, pi_star = Bit.estimate_taylor_rule(a1, a2, a3)
    model.cb.rho = rho
    model.cb.r_star = r_star
    model.cb.xi_pi = xi_pi
    model.cb.xi_gamma = xi_gamma
    model.cb.pi_star = pi_star
    
    # set central bank rate via the Taylor rule
    cb.r_bar = Bit.central_bank_rate(cb, model)

    # apply an eventual shock to the model, the default does nothing
    shock(model)

    # update rate on loans and morgages
    bank.r = Bit.bank_rate(bank, model)

    ####### FIRM EXPECTATIONS AND DECISIONS #######

    # compute firm quantity, price, investment and intermediate-goods, employment decisions, expected profits, and desired/expected loans and capital
    Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, P_i =
        Bit.firms_expectations_and_decisions(firms, model)

    firms.Q_s_i .= Q_s_i
    firms.I_d_i .= I_d_i
    firms.DM_d_i .= DM_d_i
    firms.N_d_i .= N_d_i
    firms.Pi_e_i .= Pi_e_i
    firms.P_i .= P_i
    firms.DL_d_i .= DL_d_i
    firms.K_e_i .= K_e_i
    firms.L_e_i .= L_e_i

    ####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

    # firms acquire new loans in a search and match market for credit
    firms.DL_i .= Bit.search_and_matching_credit(firms, model) # actual new loans obtained

    # firms acquire labour in the search and match market for labour
    N_i, Oh = Bit.search_and_matching_labour(firms, model)
    firms.N_i .= N_i
    w_act.O_h .= Oh


    # update wages and productivity of labour and compute production function (Leontief technology)
    firms.w_i .= Bit.firms_wages(firms)
    firms.Y_i .= Bit.firms_production(firms)


    # update wages for workers
    Bit.update_workers_wages!(w_act, firms.w_i)


    ####### CONSUMPTION AND INVESTMENT BUDGET #######

    # update social benefits
    gov.sb_other, gov.sb_inact = Bit.gov_social_benefits(gov, model)

    # compute expected bank profits
    bank.Pi_e_k = Bit.bank_expected_profits(bank, model)

    # compute consumption and investment budget for all hauseholds
    C_d_h, I_d_h = Bit.households_budget_act(w_act, model)
    w_act.C_d_h .= C_d_h
    w_act.I_d_h .= I_d_h
    C_d_h, I_d_h = Bit.households_budget_inact(w_inact, model)
    w_inact.C_d_h .= C_d_h
    w_inact.I_d_h .= I_d_h
    C_d_h, I_d_h = Bit.households_budget(firms, model)
    firms.C_d_h .= C_d_h
    firms.I_d_h .= I_d_h
    bank.C_d_h, bank.I_d_h = Bit.households_budget(bank, model)


    ####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

    # compute gov expenditure
    C_G, C_d_j = Bit.gov_expenditure(gov, model)
    gov.C_G = C_G
    gov.C_d_j .= C_d_j

    # compute demand for export and supply of imports 
    C_E, Y_I, C_d_l, Y_m, P_m = Bit.rotw_import_export(rotw, model)
    rotw.C_E = C_E
    rotw.Y_I = Y_I
    rotw.C_d_l .= C_d_l
    rotw.Y_m .= Y_m
    rotw.P_m .= P_m

    ####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######

    Bit.search_and_matching!(model, multi_threading)

    ####### FINAL GENERAL ACCOUNTING #######

    # update inflation and update global price index
    agg.pi_[prop.T_prime + agg.t], agg.P_bar = Bit.inflation_priceindex(firms.P_i, firms.Y_i, agg.P_bar)

    # update sector-specific price index
    agg.P_bar_g .= Bit.sector_specific_priceindex(firms, rotw, prop.G)

    # update CF index and HH (CPI) index
    agg.P_bar_CF = sum(prop.products.b_CF_g .* agg.P_bar_g)
    agg.P_bar_HH = sum(prop.products.b_HH_g .* agg.P_bar_g)

    # update firms stocks
    K_i, M_i, DS_i, S_i = Bit.firms_stocks(firms)
    firms.K_i .= K_i
    firms.M_i .= M_i
    firms.DS_i .= DS_i
    firms.S_i .= S_i

    # update firms profits
    firms.Pi_i .= Bit.firms_profits(firms, model)

    # update bank profits
    bank.Pi_k = Bit.bank_profits(bank, model)

    # update bank equity
    bank.E_k = Bit.bank_equity(bank, model)

    # update actual income of all households
    w_act.Y_h .= Bit.households_income_act(w_act, model)
    w_inact.Y_h .= Bit.households_income_inact(w_inact, model)
    firms.Y_h .= Bit.households_income(firms, model)
    bank.Y_h = Bit.households_income(bank, model)

    # update savings (deposits) of all households
    w_act.D_h .= Bit.households_deposits(w_act, model)
    w_inact.D_h .= Bit.households_deposits(w_inact, model)
    firms.D_h .= Bit.households_deposits(firms, model)
    bank.D_h = Bit.households_deposits(bank, model)

    # compute central bank equity
    cb.E_CB = Bit.central_bank_equity(cb, model)

    # compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
    gov.Y_G = Bit.gov_revenues(model)

    # compute government deficit/surplus and update the government debt
    gov.L_G = Bit.gov_loans(gov, model)

    # compute firms deposits, loans and equity
    firms.D_i .= Bit.firms_deposits(firms, model)

    firms.L_i .= Bit.firms_loans(firms, model)

    firms.E_i .= Bit.firms_equity(firms, model)

    # update net credit/debit position of rest of the world
    rotw.D_RoW = Bit.rotw_deposits(rotw, model)

    # update bank net credit/debit position
    bank.D_k = Bit.bank_deposits(bank, model)

    # update GDP with the results of the time step
    agg.Y[prop.T_prime + agg.t] = sum(firms.Y_i)

    agg.t += 1
end

# Overwrite such that we use the new step method.
function CANVAS_run!(model; multi_threading = false, shock = NoShock())

    data = Bit.init_data(model)

    T = model.prop.T

    for _ in 1:T
        CANVAS_step!(model; multi_threading = multi_threading, shock = shock)
        Bit.update_data!(data, model)
    end

    return data
end

# Overwrite such that the run method is used
function CANVAS_ensemblerun(model, n_sims; multi_threading = false, shock = Bit.NoShock())

    data_vector = Vector{Bit.Data}(undef, n_sims)

    if multi_threading
        Threads.@threads for i in 1:n_sims
            model_i = deepcopy(model)
            data = CANVAS_run!(model_i; shock = shock)
            data_vector[i] = data
        end
    else
        for i in 1:n_sims
            model_i = deepcopy(model)
            data = CANVAS_run!(model_i; shock = shock)
            data_vector[i] = data
        end
    end

    # transform the vector of data objects into a DataVector
    data_vector = Bit.DataVector(data_vector)

    return data_vector
end


model = Bit.init_model(parameters, initial_conditions, T);
data_vector = CANVAS_ensemblerun(model, 25)

ps = Bit.plot_data_vector(data_vector)
plot(ps..., layout = (3, 3))

