struct Population
    active::Int64      # H_act: economically active persons
    inactive::Int64    # H_inact: economically inactive persons
    total::Int64       # H = active + inactive
end

struct Dimensions
    G::Int64           # Number of products/sectors
    T_prime::Int64     # Time interval for expectations
    J::Int64           # Number of government entities
    L::Int64           # Number of foreign consumers
    I_s::Vector{Int64} # Firms per industry
    I::Int64           # Total number of firms
end

# === Tax Rates ===
struct TaxRates
    income::Float64           # tau_INC
    corporate::Float64        # tau_FIRM
    value_added::Float64      # tau_VAT
    export::Float64           # tau_EXPORT
    capital_formation::Float64 # tau_CF
    government_consumption::Float64 # tau_G
end

# === Social Insurance ===
struct SocialInsurance
    employers_contribution::Float64  # tau_SIF
    employees_contribution::Float64  # tau_SIW
    unemployment_benefit::Float64    # theta_UB
end

# === Household Behavior ===
struct HouseholdParams
    consumption_fraction::Float64    # psi
    housing_investment_fraction::Float64 # psi_H
end

# === Banking Parameters ===
struct BankingParams
    dividend_payout_ratio::Float64   # theta_DIV
    debt_installment_rate::Float64   # theta
    capital_requirement::Float64     # zeta
    loan_to_value_ratio::Float64     # zeta_LTV
    new_firm_loan_ratio::Float64     # zeta_b
    risk_premium::Float64            # mu
end

# === Product/Industry Coefficients ===
struct ProductCoefficients
    capital_formation::Vector{Float64}      # b_CF_g
    household_investment::Vector{Float64}   # b_CFH_g
    household_consumption::Vector{Float64}  # b_HH_g
    government_consumption::Vector{Float64} # c_G_g
    exports::Vector{Float64}                # c_E_g
    imports::Vector{Float64}                # c_I_g
    technology::Matrix{Float64}             # a_sg
    consumption_matrix::Matrix{Float64}     # C
end

# === Initial Conditions ===
struct InitialConditions
    household_debt::Float64        # D_H
    household_capital::Float64     # K_H
    other_subsidies::Float64       # sb_other
    equity_ratio::Float64          # E_k
    policy_rate::Float64           # r_bar
end



mutable struct Properties(Object) <: AbstractProperties
    dimensions::Dimensions
    population::Population
    tax_rates::TaxRates
    social_insurance::SocialInsurance
    household_params::HouseholdParams
    banking_params::BankingParams
    product_coeffs::ProductCoefficients
    initial_conditions::InitialConditions
end

function Properties(parameters::Dict{String, Any}, initial_conditions)

    # Dimensions
    G = Int64(parameters["G"])
    T_prime = Int64(parameters["T_prime"])
    J = Int64(parameters["J"])
    L = Int64(parameters["L"])
    I_s = Vector{Int64}(vec(parameters["I_s"]))
    I = Int64(sum(parameters["I_s"]))
    
    dimensions = Dimensions(G, T_prime, J, L, I_s, I)

    # Population
    H_act = Int64(parameters["H_act"])
    H_inact = Int64(parameters["H_inact"])
    H = H_act + H_inact
    
    population = Population(H_act, H_inact, H)

    # Tax Rates
    tax_rates = TaxRates(
        Float64(parameters["tau_INC"]),
        Float64(parameters["tau_FIRM"]),
        Float64(parameters["tau_VAT"]),
        Float64(parameters["tau_EXPORT"]),
        Float64(parameters["tau_CF"]),
        Float64(parameters["tau_G"])
    )

    # Social Insurance
    social_insurance = SocialInsurance(
        Float64(parameters["tau_SIF"]),
        Float64(parameters["tau_SIW"]),
        Float64(parameters["theta_UB"])
    )

    # Household Parameters
    household_params = HouseholdParams(
        Float64(parameters["psi"]),
        Float64(parameters["psi_H"])
    )

    # Banking Parameters
    banking_params = BankingParams(
        Float64(parameters["theta_DIV"]),
        Float64(parameters["theta"]),
        Float64(parameters["zeta"]),
        Float64(parameters["zeta_LTV"]),
        Float64(parameters["zeta_b"]),
        Float64(parameters["mu"])
    )

    # Product Coefficients
    product_coeffs = ProductCoefficients(
        Vector{Float64}(vec(parameters["b_CF_g"])),
        Vector{Float64}(vec(parameters["b_CFH_g"])),
        Vector{Float64}(vec(parameters["b_HH_g"])),
        Vector{Float64}(vec(parameters["c_G_g"])),
        Vector{Float64}(vec(parameters["c_E_g"])),
        Vector{Float64}(vec(parameters["c_I_g"])),
        Matrix{Float64}(parameters["a_sg"]),
        Matrix{Float64}(parameters["C"])
    )

    # Initial Conditions
    init_conds = InitialConditions(
        Float64(initial_conditions["D_H"]),
        Float64(initial_conditions["K_H"]),
        Float64(initial_conditions["sb_other"]),
        Float64(initial_conditions["E_k"]),
        Float64(initial_conditions["r_bar"])
    )

    return Properties(
        dimensions,
        population,
        tax_rates,
        social_insurance,
        household_params,
        banking_params,
        product_coeffs,
        init_conds
    )
end
