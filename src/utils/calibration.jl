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


function get_params_and_initial_conditions(calibration_object, calibration_date;
                                           scale = 0.001,
                                           use_growth_rate_ar1 = false)
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
    T_calibration_quarterly = findall(calibration_data["quarters_num"] .== date2num(calibration_date))[1][1]
    T_estimation_exo = findall(data["quarters_num"] .== date2num(estimation_date))[1][1]
    T_calibration_exo = findall(data["quarters_num"] .== date2num(calibration_date))[1][1]
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

    # Apply consolidation ratio to exclude intra-group lending from firm debt
    if haskey(calibration_data, "firm_debt_consolidation_ratio_quarterly") &&
            length(calibration_data["firm_debt_consolidation_ratio_quarterly"]) >= T_calibration_quarterly &&
            !ismissing(calibration_data["firm_debt_consolidation_ratio_quarterly"][T_calibration_quarterly])
        firm_debt_quarterly *= calibration_data["firm_debt_consolidation_ratio_quarterly"][T_calibration_quarterly]
    end

    # Check if quarterly interest data available and load accordingly
    # Must verify: (1) key exists, (2) vector is long enough, (3) value at index is not missing
    has_quarterly_firm_interest = haskey(calibration_data, "firm_interest_quarterly") &&
        length(calibration_data["firm_interest_quarterly"]) >= T_calibration_quarterly &&
        !ismissing(calibration_data["firm_interest_quarterly"][T_calibration_quarterly])
    has_quarterly_govt_interest = haskey(calibration_data, "interest_government_debt_quarterly") &&
        length(calibration_data["interest_government_debt_quarterly"]) >= T_calibration_quarterly &&
        !ismissing(calibration_data["interest_government_debt_quarterly"][T_calibration_quarterly])

    # Load firm interest - prefer quarterly if available, otherwise use annual
    # (will convert later). We have warned about this upcoming conversion
    # already in 'import_calibration_data', so no more warnings here.
    if has_quarterly_firm_interest
        firm_interest_quarterly = calibration_data["firm_interest_quarterly"][T_calibration_quarterly]
    else
        firm_interest_quarterly = calibration_data["firm_interest"][T_calibration]
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
    # MATLAB zeros out taxes_products (set_parameters_and_initial_conditions.m:105-106)
    # This is necessary for the GDP expenditure identity (Y = C + G + I + X - M) to hold.
    # In BeforeIT's update_data!(), GDP includes sum(firms.tau_Y_i .* firms.Y_i .* firms.P_i),
    # which would be non-zero with actual taxes_products, breaking the identity since
    # household consumption C = tot_Y_h * psi doesn't adjust accordingly.
    taxes_products = zeros(G)

    # Load government deficit - prefer quarterly if available (to match MATLAB exactly)
    # MATLAB uses: government_deficit_quarterly / timescale
    has_quarterly_govt_deficit = haskey(calibration_data, "government_deficit_quarterly") &&
        length(calibration_data["government_deficit_quarterly"]) >= T_calibration_quarterly &&
        !ismissing(calibration_data["government_deficit_quarterly"][T_calibration_quarterly])

    government_deficit_quarterly = if has_quarterly_govt_deficit
        calibration_data["government_deficit_quarterly"][T_calibration_quarterly]
    else
        @warn "Using annual 'government_deficit' - will NOT apply timescale conversion"
        nothing  # Will use annual directly
    end
    government_deficit_annual = calibration_data["government_deficit"][T_calibration]

    firms = calibration_data["firms"][:, T_calibration]
    employees = calibration_data["employees"][:, T_calibration]
    population = calibration_data["population"][T_calibration]
    r_bar = (data["euribor"][T_calibration_exo] .+ 1.0) .^ (1.0 / 4.0) .- 1

    omega = 0.85

    # Ensure intermediate_consumption is non-negative (robustness)
    intermediate_consumption = max.(0, intermediate_consumption)

    # Calculate variables from production account identity:
    # Output = Intermediate Consumption + Value Added
    # Value Added = D1 + D29-D39 + B2A3G
    # NOTE: capital_consumption is NOT included because operating_surplus (B2A3G) is
    # already GROSS — it includes CFC (P51C). Adding CFC again would double-count.
    # Verified: FIGARO D1 + D29X39 + B2A3G matches GDP B1G within 0.06% for Austria.
    output =
        sum(intermediate_consumption, dims = 1)' .+ taxes_products .+ taxes_production .+ compensation_employees .+
        operating_surplus
    output = output[:, 1]

    # Load capital_consumption (used for delta_s depreciation rate and imports residual)
    capital_consumption = calibration_data["capital_consumption"][:, T_calibration]
    if size(capital_consumption)[1] != G
        # gross_capitalformation_dwellings = calibration_data["gross_capitalformation_dwellings"][T_calibration]
        nace64_capital_consumption = calibration_data["nace64_capital_consumption"][:, T_calibration]
        nominal_nace64_output = calibration_data["nominal_nace64_output"][:, T_calibration]
        capital_consumption = nace64_capital_consumption ./ nominal_nace64_output .* output
        # operating_surplus = operating_surplus - capital_consumption
    end

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
    # NOTE: Do NOT subtract capital_consumption from operating_surplus here.
    # Neither MATLAB codebase (ABM nor DDGABM) does this adjustment.
    # operating_surplus from FIGARO is used as-is.
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
    # Timescale = quarterly GDP / annual GDP proxy
    # The denominator sums the same income components as GDP:
    # D1 + D29-D39 + B2A3G + product taxes on final demand
    # NOTE: capital_consumption is NOT included because operating_surplus (B2A3G) is
    # already GROSS. Including CFC would inflate the denominator by ~20%.
    timescale =
        data["nominal_gdp_quarterly"][T_calibration_exo] / (
        sum(
            compensation_employees .+ operating_surplus .+ taxes_production .+
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
    # Use actual per-sector D11 wages when available for more accurate w_s and pi_bar_s.
    # Fallback: apply aggregate D12/D1 ratio uniformly (assumes identical social contribution
    # structures across sectors). Aggregate sum(wages) is the same either way.
    wages = if has_sectoral_wages
        wages_by_sector
    else
        compensation_employees * (1 - sum(employers_social_contributions) / sum(compensation_employees))
    end
    household_income_tax = income_tax - corporate_tax
    # Government budget identity for other_net_transfers (matching MATLAB exactly)
    # MATLAB: other_net_transfers = ... - interest_government_debt_quarterly/timescale - government_deficit_quarterly/timescale
    # All quarterly data is divided by timescale to convert to annual units
    govt_deficit_term = if has_quarterly_govt_deficit
        government_deficit_quarterly / timescale  # quarterly → annual (like MATLAB)
    else
        government_deficit_annual  # already annual (fallback)
    end
    # Allow negative values (matching MATLAB exactly - no Bit.pos() wrapper)
    # Countries with government deficits can have negative other_net_transfers
    other_net_transfers =
        sum(taxes_products_household) +
        sum(taxes_products_capitalformation_dwellings) +
        sum(taxes_products_export) +
        sum(taxes_products) +
        sum(taxes_production) +
        sum(employers_social_contributions) +
        household_social_contributions +
        household_income_tax +
        corporate_tax +
        capital_taxes -
        social_benefits -
        sum(government_consumption) -
        interest_government_debt_quarterly / timescale -
        govt_deficit_term
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

    # Handle zero-productivity sectors (inactive sectors in small economies like Luxembourg)
    # Set minimum positive values to avoid NaN during BeforeIT initialization.
    # BeforeIT computes per-firm capital as K_i = Y_i / (kappa_s * omega), which produces NaN
    # when kappa_s = 0. Similarly, alpha_s = 0 causes issues with labor allocation.
    MIN_PRODUCTIVITY = 1.0e-6
    alpha_s = max.(alpha_s, MIN_PRODUCTIVITY)
    kappa_s = max.(kappa_s, MIN_PRODUCTIVITY)
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

    # Compute tau_SIF early (needed for model_profit_s calculation)
    tau_SIF = sum(employers_social_contributions) / sum(wages)

    # Compute sectoral profit using BeforeIT's formula (pi_bar_s × Y_s)
    # This matches how BeforeIT will compute profits in init_firms.jl
    # The key insight is that BeforeIT uses this formula for allocating deposits,
    # so we must use the same formula to calibrate theta_DIV and tau_FIRM correctly.
    Y_s = timescale * output
    pi_bar_s = 1 .- (1 .+ tau_SIF) .* w_s ./ alpha_s .- delta_s ./ kappa_s .- 1 ./ beta_s .- tau_K_s .- tau_Y_s
    replace!(pi_bar_s, NaN => 0.0)
    replace!(pi_bar_s, Inf => 0.0)
    replace!(pi_bar_s, -Inf => 0.0)
    model_profit_s = pi_bar_s .* Y_s

    # Deposit allocation using BeforeIT's profit definition
    pos_model_profit_sum = sum(Bit.pos(model_profit_s))
    D_s_alloc = if pos_model_profit_sum > 0
        Bit.pos(model_profit_s) ./ pos_model_profit_sum
    else
        zeros(length(model_profit_s))
    end
    # Loan allocation (K_i / sum(K_i) = fixed_assets / sum(fixed_assets))
    L_s_alloc = fixed_assets_other_than_dwellings ./ sum(fixed_assets_other_than_dwellings)
    # Sectoral profit after interest (matching BeforeIT's Pi_i formula)
    profit_after_interest_s = model_profit_s .-
        (r_bar .+ mu) .* firm_debt_quarterly .* L_s_alloc .+
        r_bar .* firm_cash_quarterly .* D_s_alloc

    tau_FIRM =
        timescale * corporate_tax / (
        sum(Bit.pos(profit_after_interest_s)) +
            firm_interest_quarterly - r_bar * (firm_debt_quarterly - bank_equity_quarterly)
    )
    tau_VAT = taxes_products_household / sum(household_consumption)
    # tau_SIF is computed earlier (line 437) for model_profit_s calculation
    tau_SIW = household_social_contributions / sum(wages)
    tau_EXPORT = sum(taxes_products_export) / sum(exports - reexports)
    tau_CF = sum(taxes_products_capitalformation_dwellings) / sum(capitalformation_dwellings)
    tau_G = sum(taxes_products_government) / sum(government_consumption)
    psi = (sum(household_consumption) + sum(taxes_products_household)) / disposable_income
    psi_H = (sum(capitalformation_dwellings) + sum(taxes_products_capitalformation_dwellings)) / disposable_income
    theta_DIV =
        timescale * (mixed_income + property_income) / (
        sum(Bit.pos(profit_after_interest_s)) +
            firm_interest_quarterly - r_bar * (firm_debt_quarterly - bank_equity_quarterly) -
            timescale * corporate_tax
    )
    r_G = interest_government_debt_quarterly / government_debt_quarterly
    theta_UB = 0.55 * (1 - tau_INC) * (1 - tau_SIW)
    theta = 0.05
    zeta = 0.03
    zeta_LTV = 0.6
    zeta_b = 0.5

    # Inflation is always estimated on growth rates (diff of log) - this is already correct
    alpha_pi_EA, beta_pi_EA, sigma_pi_EA, epsilon_pi_EA = Bit.estimate_for_calibration_script(
        diff(log.(ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo])),
    )

    # Taylor rule estimation (always uses growth rates for inflation/output gap)
    a1 = (data["euribor"][T_estimation_exo:T_calibration_exo] .+ 1) .^ (1 / 4) .- 1
    a2 = exp.(diff(log.(ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))) .- 1
    a3 = exp.(diff(log.(ea["real_gdp_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))) .- 1
    rho, r_star, xi_pi, xi_gamma, pi_star = Bit.estimate_taylor_rule(a1, a2, a3)

    # Level series for G, E, I (needed for initial conditions)
    G_est_levels =
        timescale * sum(government_consumption) .*
        data["real_government_consumption_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_government_consumption_quarterly"][T_calibration_exo]

    E_est_levels =
        timescale * sum(exports - reexports) .* data["real_exports_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_exports_quarterly"][T_calibration_exo]

    I_est_levels =
        timescale * sum(imports) .* data["real_imports_quarterly"][T_estimation_exo:T_calibration_exo] ./
        data["real_imports_quarterly"][T_calibration_exo]

    # EA GDP series
    Y_EA_series_raw = ea["real_gdp_quarterly"][T_estimation_exo:T_calibration_exo]

    # Initialize growth rate initial values (will be set if use_growth_rate_ar1 is true)
    g_G_init = 0.0
    g_E_init = 0.0
    g_I_init = 0.0

    # EA GDP/inflation: ALWAYS use log-level AR(1) regardless of use_growth_rate_ar1
    # This keeps Taylor rule inputs consistent with how the Taylor rule parameters
    # (rho, xi_pi, xi_gamma) were estimated. The growth-rate mode only affects
    # domestic exogenous variables (G, E, I), not EA variables.
    alpha_Y_EA, beta_Y_EA, sigma_Y_EA, epsilon_Y_EA =
        Bit.estimate_for_calibration_script(log.(Y_EA_series_raw))

    if use_growth_rate_ar1
        # GROWTH-RATE AR(1) ESTIMATION for DOMESTIC variables only
        # Estimate AR(1) on first differences of log (growth rates)
        # This gives stationary parameters with α typically in 0.2-0.5 range

        # Government consumption growth rates
        G_growth = diff(log.(G_est_levels))
        alpha_G, beta_G, sigma_G, epsilon_G = Bit.estimate_for_calibration_script(G_growth)
        g_G_init = G_growth[end]

        # Exports growth rates
        E_growth = diff(log.(E_est_levels))
        alpha_E, beta_E, sigma_E, epsilon_E = Bit.estimate_for_calibration_script(E_growth)
        g_E_init = E_growth[end]

        # Imports growth rates
        I_growth = diff(log.(I_est_levels))
        alpha_I, beta_I, sigma_I, epsilon_I = Bit.estimate_for_calibration_script(I_growth)
        g_I_init = I_growth[end]
    else
        # ORIGINAL LOG-LEVEL AR(1) ESTIMATION for domestic variables
        # Estimate AR(1) on log-levels (may give near-unit-root or explosive parameters)
        G_est = log.(G_est_levels)
        alpha_G, beta_G, sigma_G, epsilon_G = Bit.estimate_for_calibration_script(G_est)

        E_est = log.(E_est_levels)
        alpha_E, beta_E, sigma_E, epsilon_E = Bit.estimate_for_calibration_script(E_est)

        I_est = log.(I_est_levels)
        alpha_I, beta_I, sigma_I, epsilon_I = Bit.estimate_for_calibration_script(I_est)
    end

    # Covariance matrix calculation
    # When use_growth_rate_ar1=true, epsilon_E and epsilon_I come from diff(log()) estimation
    # and have length N-1, while epsilon_Y_EA (always log-level) has length N.
    # We need to align them by dropping the first element of epsilon_Y_EA.
    if use_growth_rate_ar1
        # Align lengths: drop first element of epsilon_Y_EA to match growth-rate epsilons
        epsilon_Y_EA_aligned = epsilon_Y_EA[2:end]
        C = cov([epsilon_Y_EA_aligned epsilon_E epsilon_I])
    else
        C = cov([epsilon_Y_EA epsilon_E epsilon_I])
    end

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
        "C" => C,
        "use_growth_rate_ar1" => use_growth_rate_ar1
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

    # Add initial growth rates for domestic variables if using growth-rate AR(1)
    # Note: EA variables (g_Y_EA) are NOT included here because we always use
    # log-level AR(1) for EA to keep Taylor rule inputs consistent.
    if use_growth_rate_ar1
        initial_conditions["g_G"] = g_G_init
        initial_conditions["g_E"] = g_E_init
        initial_conditions["g_I"] = g_I_init
    end

    return params, initial_conditions

end
