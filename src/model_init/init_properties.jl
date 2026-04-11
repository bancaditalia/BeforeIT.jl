# === DIMENSIONS ===
struct Dimensions
    sectors::Int64                               # G
    T::Int64                                     # T
    interval_for_expectation_estimation::Int64   # T_prime
    maximum_periods::Int64                       # T_max
    government_entities::Int64                   # J
    foreign_consumers::Int64                     # L
    firms_per_sector::Vector{Int64}              # I_s
    total_firms::Int64                           # I
end

# === POPULATION ===
struct Population
    active::Int64               # H_act: economically active persons
    inactive::Int64             # H_inact: economically inactive persons
    total::Int64                # H = active + inactive (derived)
end

# === TAX RATES ===
struct TaxRates
    income::Float64             # tau_INC: income tax rate
    corporate::Float64          # tau_FIRM: corporate tax rate
    value_added::Float64        # tau_VAT: VAT rate
    exports::Float64             # tau_EXPORT: export tax rate
    capital_formation::Float64  # tau_CF: tax on capital formation
    government_consumption::Float64 # tau_G: tax on government consumption
end

# === SECTOR-SPECIFIC TAX RATES ===
struct SectorTaxRates
    output::Vector{Float64}     # tau_Y_s: output tax by sector
    capital::Vector{Float64}    # tau_K_s: capital tax by sector
end

# === SOCIAL INSURANCE ===
struct SocialInsurance
    employers_contribution::Float64  # tau_SIF: employer social insurance rate
    employees_contribution::Float64  # tau_SIW: employee social insurance rate
    unemployment_benefit::Float64    # theta_UB: unemployment benefit replacement rate
end

# === HOUSEHOLD BEHAVIOR ===
struct HouseholdParams
    consumption_share::Float64       # psi: fraction of income for consumption
    housing_investment_share::Float64 # psi_H: fraction for housing investment
end

# === BANKING PARAMETERS ===
struct BankingParams
    dividend_payout_ratio::Float64   # theta_DIV: dividend payout ratio
    debt_installment_rate::Float64   # theta: rate of installment on debt
    capital_requirement::Float64     # zeta: bank capital requirement coefficient
    loan_to_value_ratio::Float64     # zeta_LTV: loan-to-value ratio
    new_firm_loan_ratio::Float64     # zeta_b: loan-to-capital for new firms post-bankruptcy
    risk_premium::Float64            # mu: risk premium on policy rate
end

# === MONETARY POLICY ===
struct MonetaryPolicy
    inflation_target::Float64        # pi_star: central bank inflation target
    interest_rate_smoothing::Float64 # rho: interest rate smoothing parameter
    response_to_inflation::Float64   # xi_pi: Taylor rule coefficient on inflation
    response_to_output::Float64      # xi_gamma: Taylor rule coefficient on output gap
    natural_rate::Float64            # r_star: natural rate of interest
end

# === FISCAL POLICY ===
struct FiscalPolicy
    government_interest_rate::Float64 # r_G: interest rate on government debt
    consumption_autoregression::Float64 # alpha_G: AR(1) coefficient for gov consumption
    consumption_shock_sd::Float64    # sigma_G: std dev of gov consumption shocks
    exports_autoregression::Float64  # beta_E: AR(1) for exports (if applicable)
    exports_response_to_foreign_output::Float64 # alpha_E: exports response to foreign output
    exports_shock_sd::Float64        # sigma_E: std dev of export shocks
end

# === PRODUCT/INPUT-OUTPUT COEFFICIENTS ===
struct ProductCoefficients
    # Consumption baskets
    household_consumption::Vector{Float64}   # b_HH_g: household consumption by product
    household_investment::Vector{Float64}    # b_CFH_g: household housing investment by product
    government_consumption::Vector{Float64}  # c_G_g: government consumption by product
    exports::Vector{Float64}                 # c_E_g: exports by product
    imports::Vector{Float64}                 # c_I_g: imports by product
    
    # Investment coefficients
    capital_formation::Vector{Float64}       # b_CF_g: firm investment by product
    
    # Technology
    technology_matrix::Matrix{Float64}       # a_sg: input-output coefficients
    consumption_matrix::Matrix{Float64}      # C: consumption share matrix
end

# === SECTORAL PRODUCTION PARAMETERS ===
struct SectoralParams
    output_elasticity::Vector{Float64}       # alpha_s: labor productivity/output elasticity
    material_coefficient::Vector{Float64}    # beta_s: material input coefficient
    capital_coefficient::Vector{Float64}     # kappa_s: capital coefficient
    depreciation_rate::Vector{Float64}       # delta_s: depreciation rate
    wage_rate::Vector{Float64}               # w_s: base wage rate by sector
    
    # Investment dynamics
    investment_autoregression::Float64       # alpha_I: AR(1) for investment
    investment_response_to_utilization::Float64 # beta_I: investment response to capacity utilization
    investment_shock_sd::Float64             # sigma_I: std dev of investment shocks
end

# === EXTERNAL SECTOR / FOREIGN ECONOMY ===
struct ExternalParams
    # Foreign output dynamics
    output_autoregression::Float64           # alpha_Y_EA: AR(1) for foreign output
    output_shock_sd::Float64                 # sigma_Y_EA: std dev of foreign output shocks
    
    # Foreign inflation dynamics
    inflation_autoregression::Float64        # alpha_pi_EA: AR(1) for foreign inflation
    inflation_response_to_output_gap::Float64 # beta_pi_EA: Phillips curve coefficient
    inflation_shock_sd::Float64              # sigma_pi_EA: std dev of foreign inflation shocks
    
    # Trade elasticities
    export_elasticity::Float64               # beta_E: export elasticity (alternative naming)
end

# === INITIAL CONDITIONS (as previously defined) ===
struct SectorInitialConditions
    employment::Vector{Float64}
end

struct FirmInitialConditions
    total_debt::Float64
    total_loans::Float64
    capacity_utilization::Float64
    output::Vector{Float64}
end

struct HouseholdInitialConditions
    debt::Float64
    capital::Float64
    unemployment_benefit::Float64
end

struct GovernmentInitialConditions
  consumption::Vector{Float64}
    debt::Float64
    subsidies_inactive::Float64
    subsidies_other::Float64
end

struct BankingInitialConditions
    central_bank_equity::Float64
    equity_ratio::Float64
    policy_rate::Float64
end

struct ExternalInitialConditions
    debt::Float64
    exports::Vector{Float64}
    foreign_output::Float64
    foreign_inflation::Float64
end

struct EconomyInitialConditions
    total_output::Vector{Float64}
    inflation::Vector{Float64}
end

struct InitialConditions
    sectors::SectorInitialConditions
    firms::FirmInitialConditions
    households::HouseholdInitialConditions
    government::GovernmentInitialConditions
    banking::BankingInitialConditions
    external::ExternalInitialConditions
    economy::EconomyInitialConditions
end


struct Properties
    # Core dimensions and demographics
    dimensions::Dimensions
    population::Population
    
    # Policy parameters
    tax_rates::TaxRates
    sector_tax_rates::SectorTaxRates
    social_insurance::SocialInsurance
    monetary_policy::MonetaryPolicy
    fiscal_policy::FiscalPolicy
    
    # Behavioral parameters
    household_params::HouseholdParams
    banking_params::BankingParams
    
    # Technical coefficients
    product_coeffs::ProductCoefficients
    sectoral_params::SectoralParams
    
    # External sector
    external_params::ExternalParams
    
    # Initial conditions
    initial_conditions::InitialConditions
end

function Properties(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any})
    
    # === DIMENSIONS ===
    G = Int64(parameters["G"])
    T = Int64(parameters["T"])
    T_prime = Int64(parameters["T_prime"])
    T_max = Int64(parameters["T_max"])
    J = Int64(parameters["J"])
    L = Int64(parameters["L"])
    I_s = Vector{Int64}(vec(parameters["I_s"]))
    I = Int64(sum(I_s))
    
    dimensions = Dimensions(G, T, T_prime, T_max, J, L, I_s, I)
    
    # === POPULATION ===
    H_act = Int64(parameters["H_act"])
    H_inact = Int64(parameters["H_inact"])
    H = H_act + H_inact
    
    population = Population(H_act, H_inact, H)
    
    # === TAX RATES ===
    tax_rates = TaxRates(
        Float64(parameters["tau_INC"]),
        Float64(parameters["tau_FIRM"]),
        Float64(parameters["tau_VAT"]),
        Float64(parameters["tau_EXPORT"]),
        Float64(parameters["tau_CF"]),
        Float64(parameters["tau_G"])
    )
    
    sector_tax_rates = SectorTaxRates(
        Vector{Float64}(vec(parameters["tau_Y_s"])),
        Vector{Float64}(vec(parameters["tau_K_s"]))
    )
    
    # === SOCIAL INSURANCE ===
    social_insurance = SocialInsurance(
        Float64(parameters["tau_SIF"]),
        Float64(parameters["tau_SIW"]),
        Float64(parameters["theta_UB"])
    )
    
    # === HOUSEHOLD BEHAVIOR ===
    household_params = HouseholdParams(
        Float64(parameters["psi"]),
        Float64(parameters["psi_H"])
    )
    
    # === BANKING PARAMETERS ===
    banking_params = BankingParams(
        Float64(parameters["theta_DIV"]),
        Float64(parameters["theta"]),
        Float64(parameters["zeta"]),
        Float64(parameters["zeta_LTV"]),
        Float64(parameters["zeta_b"]),
        Float64(parameters["mu"])
    )
    
    # === MONETARY POLICY ===
    monetary_policy = MonetaryPolicy(
        Float64(parameters["pi_star"]),
        Float64(parameters["rho"]),
        Float64(parameters["xi_pi"]),
        Float64(parameters["xi_gamma"]),
        Float64(parameters["r_star"])
    )
    
    # === FISCAL POLICY ===
    fiscal_policy = FiscalPolicy(
        Float64(parameters["r_G"]),
        Float64(parameters["alpha_G"]),
        Float64(parameters["sigma_G"]),
        Float64(parameters["beta_E"]),
        Float64(parameters["alpha_E"]),
        Float64(parameters["sigma_E"])
    )
    
    # === PRODUCT COEFFICIENTS ===
    product_coeffs = ProductCoefficients(
        Vector{Float64}(vec(parameters["b_HH_g"])),
        Vector{Float64}(vec(parameters["b_CFH_g"])),
        Vector{Float64}(vec(parameters["c_G_g"])),
        Vector{Float64}(vec(parameters["c_E_g"])),
        Vector{Float64}(vec(parameters["c_I_g"])),
        Vector{Float64}(vec(parameters["b_CF_g"])),
        Matrix{Float64}(parameters["a_sg"]),
        Matrix{Float64}(parameters["C"])
    )
    
    # === SECTORAL PARAMETERS ===
    sectoral_params = SectoralParams(
        Vector{Float64}(vec(parameters["alpha_s"])),
        Vector{Float64}(vec(parameters["beta_s"])),
        Vector{Float64}(vec(parameters["kappa_s"])),
        Vector{Float64}(vec(parameters["delta_s"])),
        Vector{Float64}(vec(parameters["w_s"])),
        Float64(parameters["alpha_I"]),
        Float64(parameters["beta_I"]),
        Float64(parameters["sigma_I"])
    )
    
    # === EXTERNAL PARAMETERS ===
    external_params = ExternalParams(
        Float64(parameters["alpha_Y_EA"]),
        Float64(parameters["sigma_Y_EA"]),
        Float64(parameters["alpha_pi_EA"]),
        Float64(parameters["beta_pi_EA"]),
        Float64(parameters["sigma_pi_EA"]),
        Float64(parameters["beta_E"])
    )
    
    # === INITIAL CONDITIONS ===
    init_conds = InitialConditions(
        SectorInitialConditions(
            Vector{Float64}(vec(initial_conditions["N_s"]))
        ),
        FirmInitialConditions(
            Float64(initial_conditions["D_I"]),
            Float64(initial_conditions["L_I"]),
            Float64(initial_conditions["omega"]),
            Vector{Float64}(vec(initial_conditions["Y_I"]))
        ),
        HouseholdInitialConditions(
            Float64(initial_conditions["D_H"]),
            Float64(initial_conditions["K_H"]),
            Float64(initial_conditions["w_UB"])
        ),
        GovernmentInitialConditions(
            Vector{Float64}(vec(initial_conditions["C_G"])),
            Float64(initial_conditions["L_G"]),
            Float64(initial_conditions["sb_inact"]),
            Float64(initial_conditions["sb_other"])
        ),
        BankingInitialConditions(
            Float64(initial_conditions["E_CB"]),
            Float64(initial_conditions["E_k"]),
            Float64(initial_conditions["r_bar"])
        ),
        ExternalInitialConditions(
            Float64(initial_conditions["D_RoW"]),
            Vector{Float64}(vec(initial_conditions["C_E"])),
            Float64(initial_conditions["Y_EA"]),
            Float64(initial_conditions["pi_EA"])
        ),
        EconomyInitialConditions(
            Vector{Float64}(vec(initial_conditions["Y"])),
            Vector{Float64}(vec(initial_conditions["pi"]))
        )
    )
    
    return Properties(
        dimensions,
        population,
        tax_rates,
        sector_tax_rates,
        social_insurance,
        monetary_policy,
        fiscal_policy,
        household_params,
        banking_params,
        product_coeffs,
        sectoral_params,
        external_params,
        init_conds
    )
end
