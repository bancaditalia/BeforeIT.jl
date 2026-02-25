using Dates

"""
     datenum(d::Dates.DateTime)
Converts a Julia DateTime to a MATLAB style DateNumber.
MATLAB represents time as DateNumber, a double precision floating
point number being the the number of days since January 0, 0000
Example
    datenum(now())
"""
date2num(d::Dates.DateTime) = Dates.value(d - MATLAB_EPOCH) / (1000 * 60 * 60 * 24)

# inverse function of the above
const MATLAB_EPOCH = Dates.DateTime(-1, 12, 31)
num2date(n::Number) = MATLAB_EPOCH + Dates.Millisecond(round(Int64, n * 1000 * 60 * 60 * 24))

"""
    get_valid_calibration_quarters(calibration_object)

Determine which quarters have sufficient data for calibration by checking
all required data sources. Returns a vector of (year, quarter) tuples.
"""
function get_valid_calibration_quarters(calibration_object)
    calibration_data = calibration_object.calibration
    figaro = calibration_object.figaro
    data = calibration_object.data
    max_calibration_date = calibration_object.max_calibration_date
    estimation_date = calibration_object.estimation_date

    valid_quarters = Tuple{Int, Int}[]

    # Get year range from FIGARO data
    years_num = calibration_data["years_num"]
    quarters_num = calibration_data["quarters_num"]

    # Determine min/max years from FIGARO
    min_figaro_year = year(num2date(minimum(years_num)))
    max_figaro_year = year(num2date(maximum(years_num)))

    # Get min/max quarters from quarterly data
    min_quarter_date = num2date(minimum(quarters_num))
    max_quarter_date = num2date(maximum(quarters_num))

    # Also need estimation_date to have enough historical data
    min_estimation_year = year(estimation_date)

    for cal_year in min_figaro_year:max_figaro_year
        for cal_quarter in 1:4
            cal_month = cal_quarter * 3
            cal_day = cal_month in [3, 12] ? 31 : 30
            calibration_date = DateTime(cal_year, cal_month, cal_day)

            # Skip if before estimation date (need historical data)
            if calibration_date <= estimation_date
                continue
            end

            # Check if quarterly data is available
            if calibration_date < min_quarter_date || calibration_date > max_quarter_date
                continue
            end

            # Check if we have the quarterly index
            T_calibration_quarterly_matches = findall(quarters_num .== date2num(calibration_date))
            if isempty(T_calibration_quarterly_matches)
                continue
            end
            T_calibration_quarterly = T_calibration_quarterly_matches[1]

            # Check if we have the annual index (capped by max_calibration_date)
            capped_date = min(calibration_date, max_calibration_date)
            T_calibration_matches = findall(years_num .== date2num(DateTime(year(capped_date), 12, 31)))
            if isempty(T_calibration_matches)
                continue
            end
            T_calibration = T_calibration_matches[1]

            # Check key quarterly variables are not missing
            key_quarterly_vars = [
                ("household_cash_quarterly", T_calibration_quarterly),
                ("firm_cash_quarterly", T_calibration_quarterly),
                ("firm_debt_quarterly", T_calibration_quarterly),
                ("government_debt_quarterly", T_calibration_quarterly),
                ("bank_equity_quarterly", T_calibration_quarterly),
            ]

            all_valid = true
            for (var_name, idx) in key_quarterly_vars
                if !haskey(calibration_data, var_name)
                    all_valid = false
                    break
                end
                vec = calibration_data[var_name]
                if length(vec) < idx || ismissing(vec[idx])
                    all_valid = false
                    break
                end
            end

            if !all_valid
                continue
            end

            # Check key annual variables
            key_annual_vars = [
                ("property_income", T_calibration),
                ("mixed_income", T_calibration),
                ("corporate_tax", T_calibration),
            ]

            for (var_name, idx) in key_annual_vars
                if !haskey(calibration_data, var_name)
                    all_valid = false
                    break
                end
                vec = calibration_data[var_name]
                if length(vec) < idx || ismissing(vec[idx])
                    all_valid = false
                    break
                end
            end

            if !all_valid
                continue
            end

            # Check external data (national accounts)
            T_calibration_exo_matches = findall(data["quarters_num"] .== date2num(calibration_date))
            if isempty(T_calibration_exo_matches)
                continue
            end

            push!(valid_quarters, (cal_year, cal_quarter))
        end
    end

    return valid_quarters
end


function get_params_and_initial_conditions(calibration_object, calibration_date; scale = 0.001)
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
    )[1][1] # Extract integer index from CartesianIndex
    T_calibration_quarterly = findall(calibration_data["quarters_num"] .== date2num(calibration_date))[1][1] # Extract integer index from CartesianIndex
    T_estimation_exo = findall(data["quarters_num"] .== date2num(estimation_date))[1][1] #[1]
    T_calibration_exo = findall(data["quarters_num"] .== date2num(calibration_date))[1][1] #[1]
    T_calibration_exo_max = length(data["quarters_num"])
    intermediate_consumption = figaro["intermediate_consumption"][:, :, T_calibration]
    G = size(intermediate_consumption)[1]
    S = G
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

    # Check if quarterly interest data available and load accordingly
    # Must verify: (1) key exists, (2) vector is long enough, (3) value at index is not missing
    has_quarterly_firm_interest = haskey(calibration_data, "firm_interest_quarterly") &&
        length(calibration_data["firm_interest_quarterly"]) >= T_calibration_quarterly &&
        !ismissing(calibration_data["firm_interest_quarterly"][T_calibration_quarterly])
    has_quarterly_govt_interest = haskey(calibration_data, "interest_government_debt_quarterly") &&
        length(calibration_data["interest_government_debt_quarterly"]) >= T_calibration_quarterly &&
        !ismissing(calibration_data["interest_government_debt_quarterly"][T_calibration_quarterly])

    # Load firm interest - prefer quarterly if available, otherwise use annual (will convert later)
    firm_interest_quarterly = if has_quarterly_firm_interest
        calibration_data["firm_interest_quarterly"][T_calibration_quarterly]
    else
        @warn "Using annual 'firm_interest' - will apply timescale conversion"
        calibration_data["firm_interest"][T_calibration]
    end

    government_debt_quarterly = calibration_data["government_debt_quarterly"][T_calibration_quarterly]

    # Load government interest - prefer quarterly if available, otherwise use annual (will convert later)
    interest_government_debt_quarterly = if has_quarterly_govt_interest
        calibration_data["interest_government_debt_quarterly"][T_calibration_quarterly]
    else
        @warn "Using annual 'interest_government_debt' - will apply timescale conversion"
        calibration_data["interest_government_debt"][T_calibration]
    end

    government_consumption = figaro["government_consumption"][:, T_calibration]
    social_benefits = calibration_data["social_benefits"][T_calibration]
    unemployment_benefits = calibration_data["unemployment_benefits"][T_calibration]
    pension_benefits = calibration_data["pension_benefits"][T_calibration]
    corporate_tax = calibration_data["corporate_tax"][T_calibration]

    # Check for sectoral wages data (new approach) vs scalar wages (old approach)
    has_sectoral_wages = haskey(calibration_data, "wages_by_sector") &&
        size(calibration_data["wages_by_sector"], 2) >= T_calibration

    wages_by_sector = if has_sectoral_wages
        calibration_data["wages_by_sector"][:, T_calibration]  # Sectoral wages (D11)
    else
        # Fallback: estimate sectoral wages from aggregate wages proportional to compensation
        @warn "wages_by_sector not available, estimating from aggregate wages"
        wages_scalar = calibration_data["wages"][T_calibration]
        wages_scalar .* (compensation_employees ./ sum(compensation_employees))
    end

    taxes_products_household = figaro["taxes_products_household"][T_calibration]
    social_contributions = calibration_data["social_contributions"][T_calibration]
    income_tax = calibration_data["income_tax"][T_calibration]
    capital_taxes = calibration_data["capital_taxes"][T_calibration]
    taxes_products_fixed_capitalformation = figaro["taxes_products_capitalformation"][T_calibration]
    taxes_production = figaro["taxes_production"][:, T_calibration]
    taxes_products_government = figaro["taxes_products_government"][T_calibration]
    bank_equity_quarterly = calibration_data["bank_equity_quarterly"][T_calibration_quarterly]
    taxes_products = figaro["taxes_products"][:, T_calibration]

    # Load government deficit - prefer quarterly if available, otherwise use annual (will convert later)
    has_quarterly_govt_deficit = haskey(calibration_data, "government_deficit_quarterly") &&
        length(calibration_data["government_deficit_quarterly"]) >= T_calibration_quarterly &&
        !ismissing(calibration_data["government_deficit_quarterly"][T_calibration_quarterly])

    government_deficit_quarterly = if has_quarterly_govt_deficit
        calibration_data["government_deficit_quarterly"][T_calibration_quarterly]
    else
        calibration_data["government_deficit"][T_calibration]  # Will convert later
    end

    firms = calibration_data["firms"][:, T_calibration]
    employees = calibration_data["employees"][:, T_calibration]
    population = calibration_data["population"][T_calibration]
    r_bar = (data["euribor"][T_calibration_exo] .+ 1.0) .^ (1.0 / 4.0) .- 1

    omega = 0.85

    # Ensure intermediate_consumption is non-negative (robustness)
    intermediate_consumption = max.(0, intermediate_consumption)

    # Calculate variables from accounting identity
    output =
        sum(intermediate_consumption, dims = 1)' .+ taxes_products .+ taxes_production .+ compensation_employees .+
        operating_surplus
    output = output[:, 1]

    ## If fixed_assets and dwellings are given on industry-level
    if size(calibration_data["fixed_assets"])[1] == G &
            size(calibration_data["dwellings"])[1] == G
        fixed_assets = calibration_data["fixed_assets"][:, T_calibration]
        dwellings = calibration_data["dwellings"][:, T_calibration]
        fixed_assets_other_than_dwellings =
            (fixed_assets - dwellings)
    else
        fixed_assets = calibration_data["fixed_assets"][T_calibration]
        dwellings = calibration_data["dwellings"][T_calibration]
        fixed_assets_eu7 = calibration_data["fixed_assets_eu7"][:, T_calibration]
        dwellings_eu7 = calibration_data["dwellings_eu7"][:, T_calibration]
        nominal_nace64_output_eu7 = calibration_data["nominal_nace64_output_eu7"][:, T_calibration]
        fixed_assets_other_than_dwellings =
            (fixed_assets - dwellings) * ((fixed_assets_eu7 - dwellings_eu7) ./ nominal_nace64_output_eu7 .* output) /
            sum((fixed_assets_eu7 - dwellings_eu7) ./ nominal_nace64_output_eu7 .* output, dims = 1)
    end

    # ## OR [2025-09-15 Mo]: capital_consumption is already computed in
    # ## `import_calibration_data` (for all years), so not necessary to do here
    # ## again. Instead, we just extract the correct year-vector from the
    # ## capital-consumption-matrix.
    # Handle capital_consumption: Zenodo format has pre-computed sectoral data,
    # but ITALY_CALIBRATION needs the original calculation
    if size(calibration_data["capital_consumption"], 1) == size(compensation_employees, 1)
        # Zenodo format: capital_consumption is already sectoral
        capital_consumption = calibration_data["capital_consumption"][:, T_calibration]
    else
        # ITALY_CALIBRATION format: need to compute sectoral capital_consumption
        nace64_capital_consumption = calibration_data["nace64_capital_consumption"][:, T_calibration]
        nominal_nace64_output = calibration_data["nominal_nace64_output"][:, T_calibration]
        capital_consumption = nace64_capital_consumption ./ nominal_nace64_output .* output
    end

    unemployment_rate_quarterly = data["unemployment_rate_quarterly"][T_calibration_exo]
    operating_surplus = operating_surplus - capital_consumption
    taxes_products_export = 0 # TODO: unelegant hard coded zero
    # Employers' social contributions (D12) = Compensation (D1) - Wages (D11)
    # Handle both old (scalar wages) and new (sectoral wages_by_sector) formats
    if has_sectoral_wages
        # New Zenodo format: both are sectoral vectors
        employers_social_contributions = compensation_employees - wages_by_sector
    else
        # Old ITALY_CALIBRATION format: estimate sectoral contributions from scalar wages
        # First calculate scalar employers' social contributions
        scalar_employers_contributions = min(social_contributions, sum(compensation_employees) - wages_scalar)
        # Then distribute proportionally to compensation_employees to create a sectoral vector
        employers_social_contributions = scalar_employers_contributions .* (compensation_employees ./ sum(compensation_employees))
    end
    fixed_capitalformation = Bit.pos(fixed_capitalformation)
    gross_capitalformation_dwellings = calibration_data["gross_capitalformation_dwellings"][T_calibration]
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

    # Convert annual data to quarterly using timescale (only if loaded as annual)
    if !has_quarterly_firm_interest
        firm_interest_quarterly = timescale * firm_interest_quarterly
    end
    if !has_quarterly_govt_interest
        interest_government_debt_quarterly = timescale * interest_government_debt_quarterly
    end
    if !has_quarterly_govt_deficit
        government_deficit_quarterly = timescale * government_deficit_quarterly
    end

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
    household_social_contributions = social_contributions - sum(employers_social_contributions)
    wages = compensation_employees * (1 - sum(employers_social_contributions) / sum(compensation_employees))
    household_income_tax = income_tax - corporate_tax
    # Government budget identity for other_net_transfers
    # Note: interest and deficit are quarterly values, divide by timescale for annual-equivalent
    # to match units with other annual variables (taxes, benefits, etc.)
    other_net_transfers = Bit.pos(
        sum(taxes_products_household) +
            sum(taxes_products_capitalformation_dwellings) +
            sum(taxes_products_export) +
            sum(taxes_products) +
            sum(taxes_production) +
            sum(employers_social_contributions) +
            household_social_contributions +
            household_income_tax +
            corporate_tax +
            capital_taxes - social_benefits - sum(government_consumption) -
            interest_government_debt_quarterly / timescale -
            government_deficit_quarterly / timescale,
    )
    disposable_income =
        sum(wages) + mixed_income + property_income + social_benefits + other_net_transfers -
        household_social_contributions - household_income_tax - capital_taxes
    # Prefer census counts if available, otherwise calculate from rates
    unemployed = if haskey(calibration_data, "unemployed_census")
        calibration_data["unemployed_census"]
    else
        matlab_round((unemployment_rate_quarterly * sum(employees)) / (1 - unemployment_rate_quarterly))
    end

    inactive = if haskey(calibration_data, "inactive_census")
        calibration_data["inactive_census"]
    else
        population - sum(max.(max.(1, firms), employees)) - unemployed - sum(max.(1, firms)) - 1
    end


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
    # Handle NaN for sectors with zero employees or fixed assets
    replace!(alpha_s, NaN => 0.0)
    replace!(kappa_s, NaN => 0.0)
    replace!(w_s, NaN => 0.0)
    replace!(beta_s, NaN => 0.0)
    tau_Y_s = taxes_products ./ output
    tau_K_s = taxes_production ./ output
    # Handle NaN for sectors with zero output
    replace!(tau_Y_s, NaN => 0.0)
    replace!(tau_K_s, NaN => 0.0)
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
    H_act = sum(employees) + unemployed + sum(firms) + 1
    H_inact = inactive
    # Matlab:
    # J=round(sum(firms)/(sum(government_consumption)/sum(output)));
    J = matlab_round(sum(firms) / 4)
    # Matlab:
    # L=round(sum(firms)/(sum(exports-reexports)/sum(output)));
    L = matlab_round(sum(firms) / 2)
    mu = firm_interest_quarterly / firm_debt_quarterly - r_bar
    tau_INC =
        (household_income_tax + capital_taxes) /
        (sum(wages) + property_income + mixed_income - household_social_contributions)
    tau_FIRM =
        timescale * corporate_tax / (
        sum(
            Bit.pos(
                timescale * operating_surplus -
                    firm_interest_quarterly * fixed_assets_other_than_dwellings /
                    sum(fixed_assets_other_than_dwellings) +
                    r_bar * firm_cash_quarterly * Bit.pos(operating_surplus) /
                    sum(Bit.pos(operating_surplus)),
            ),
        ) + firm_interest_quarterly - r_bar * (firm_debt_quarterly - bank_equity_quarterly)
    )
    tau_VAT = taxes_products_household / sum(household_consumption)
    tau_SIF = sum(employers_social_contributions) / sum(wages)
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
                    firm_interest_quarterly * fixed_assets_other_than_dwellings /
                    sum(fixed_assets_other_than_dwellings) +
                    r_bar * firm_cash_quarterly * Bit.pos(operating_surplus) /
                    sum(Bit.pos(operating_surplus)),
            ),
        ) + firm_interest_quarterly - r_bar * (firm_debt_quarterly - bank_equity_quarterly) -
            timescale * corporate_tax
    )
    r_G = interest_government_debt_quarterly / government_debt_quarterly
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
    params = Dict(
        "T" => T,
        "T_max" => T_max,
        "S" => S,
        "G" => G,
        "H_act" => H_act,
        "H_inact" => H_inact,
        "J" => J,
        "L" => L,
        "tau_INC" => tau_INC,
        "tau_FIRM" => tau_FIRM,
        "tau_VAT" => tau_VAT,
        "tau_SIF" => tau_SIF,
        "tau_SIW" => tau_SIW,
        "tau_EXPORT" => tau_EXPORT,
        "tau_CF" => tau_CF,
        "tau_G" => tau_G,
        "theta_UB" => theta_UB,
        "psi" => psi,
        "psi_H" => psi_H,
        "theta_DIV" => theta_DIV,
        "theta" => theta,
        "mu" => mu,
        "r_G" => r_G,
        "zeta" => zeta,
        "zeta_LTV" => zeta_LTV,
        "zeta_b" => zeta_b,
        "I_s" => I_s,
        "alpha_s" => alpha_s,
        "beta_s" => beta_s,
        "kappa_s" => kappa_s,
        "delta_s" => delta_s,
        "w_s" => w_s,
        "tau_Y_s" => tau_Y_s,
        "tau_K_s" => tau_K_s,
        "b_CF_g" => b_CF_g,
        "b_CFH_g" => b_CFH_g,
        "b_HH_g" => b_HH_g,
        "c_G_g" => c_G_g,
        "c_E_g" => c_E_g,
        "c_I_g" => c_I_g,
        "a_sg" => a_sg,
        "T_prime" => T_prime,
        "alpha_pi_EA" => alpha_pi_EA,
        "beta_pi_EA" => beta_pi_EA,
        "sigma_pi_EA" => sigma_pi_EA,
        "alpha_Y_EA" => alpha_Y_EA,
        "beta_Y_EA" => beta_Y_EA,
        "sigma_Y_EA" => sigma_Y_EA,
        "rho" => rho,
        "r_star" => r_star,
        "xi_pi" => xi_pi,
        "xi_gamma" => xi_gamma,
        "pi_star" => pi_star,
        "alpha_G" => alpha_G,
        "beta_G" => beta_G,
        "sigma_G" => sigma_G,
        "alpha_E" => alpha_E,
        "beta_E" => beta_E,
        "sigma_E" => sigma_E,
        "alpha_I" => alpha_I,
        "beta_I" => beta_I,
        "sigma_I" => sigma_I,
        "C" => C
    )

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
    C_G = [
        timescale *
            sum(government_consumption) *
            data["real_government_consumption_quarterly"][
            T_estimation_exo:min(
                T_calibration_exo + T,
                T_calibration_exo_max,
            ),
        ] / data["real_government_consumption_quarterly"][T_calibration_exo]
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

    # data series needed for CANVAS
    Y_EA_series = timescale * sum(output) .* ea["real_gdp_quarterly"][T_estimation_exo:T_calibration_exo] ./ ea["real_gdp_quarterly"][T_calibration_exo]
    pi_EA_series = diff(log.(ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))
    r_bar_series = (data["euribor"][T_estimation_exo:T_calibration_exo] .+ 1.0) .^ (1.0 / 4.0) .- 1

    # define a dictionary of parameters to save in jld2 format
    initial_conditions = Dict(
        "D_I" => D_I,
        "L_I" => L_I,
        "omega" => omega,
        "w_UB" => w_UB,
        "sb_inact" => sb_inact,
        "sb_other" => sb_other,
        "D_H" => D_H,
        "K_H" => K_H,
        "L_G" => L_G,
        "E_k" => E_k,
        "E_CB" => E_CB,
        "D_RoW" => D_RoW,
        "N_s" => N_s,
        "Y" => Y,
        "pi" => pi,
        "Y_EA" => Y_EA,
        "pi_EA" => pi_EA,
        "r_bar" => r_bar,
        "C_G" => C_G,
        "C_E" => C_E,
        "Y_I" => Y_I,
        "Y_EA_series" => Y_EA_series,
        "pi_EA_series" => pi_EA_series,
        "r_bar_series" => r_bar_series
    )

    return params, initial_conditions

end
