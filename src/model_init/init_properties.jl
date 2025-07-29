
abstract type AbstractProperties <: AbstractObject end
Bit.@object mutable struct Properties(Object) <: AbstractProperties
    G::Bit.typeInt
    T_prime::Bit.typeInt
    H_act::Bit.typeInt
    H_inact::Bit.typeInt
    J::Bit.typeInt
    L::Bit.typeInt
    I_s::Vector{Bit.typeInt}
    I::Bit.typeInt
    H::Bit.typeInt
    tau_INC::Bit.typeFloat
    tau_FIRM::Bit.typeFloat
    tau_VAT::Bit.typeFloat
    tau_SIF::Bit.typeFloat
    tau_SIW::Bit.typeFloat
    tau_EXPORT::Bit.typeFloat
    tau_CF::Bit.typeFloat
    tau_G::Bit.typeFloat
    theta_UB::Bit.typeFloat
    psi::Bit.typeFloat
    psi_H::Bit.typeFloat
    mu::Bit.typeFloat
    theta_DIV::Bit.typeFloat
    theta::Bit.typeFloat
    zeta::Bit.typeFloat
    zeta_LTV::Bit.typeFloat
    zeta_b::Bit.typeFloat
    b_CF_g::Vector{Bit.typeFloat}
    b_CFH_g::Vector{Bit.typeFloat}
    b_HH_g::Vector{Bit.typeFloat}
    c_G_g::Vector{Bit.typeFloat}
    c_E_g::Vector{Bit.typeFloat}
    c_I_g::Vector{Bit.typeFloat}
    a_sg::Matrix{Bit.typeFloat}
    C::Matrix{Bit.typeFloat}
    D_H::Bit.typeFloat
    K_H::Bit.typeFloat
    sb_other::Bit.typeFloat
    E_k::Bit.typeFloat
    r_bar::Bit.typeFloat
end

function Properties(parameters::Dict{String, Any}, initial_conditions)
    G = typeInt(parameters["G"])
    T_prime = typeInt(parameters["T_prime"])       # Time interval used to estimate parameters for expectations

    H_act = typeInt(parameters["H_act"])    # Number of economically active persons
    H_inact = typeInt(parameters["H_inact"])  # Number of economically inactive persons
    # H = I + H_W + H_inact + 1

    J = typeInt(parameters["J"])       # Number of government entities
    L = typeInt(parameters["L"])        # Number of foreign consumers
    I_s = Vector{typeInt}(vec(parameters["I_s"]))           # Number of firms/investors in the s-th industry
    I = typeInt(sum(parameters["I_s"]))        # Number of firms
    H = H_act + H_inact # Total number of households

    tau_INC = typeFloat(parameters["tau_INC"])    # Income tax rate
    tau_FIRM = typeFloat(parameters["tau_FIRM"])   # Corporate tax rate
    tau_VAT = typeFloat(parameters["tau_VAT"])    # Value-added tax rate
    tau_SIF = typeFloat(parameters["tau_SIF"])    # Social insurance rate (employers’ contributions)
    tau_SIW = typeFloat(parameters["tau_SIW"])    # Social insurance rate (employees’ contributions)
    tau_EXPORT = typeFloat(parameters["tau_EXPORT"]) # Export tax rate
    tau_CF = typeFloat(parameters["tau_CF"])     # Tax rate on capital formation
    tau_G = typeFloat(parameters["tau_G"])      # Tax rate on government consumption
    theta_UB = typeFloat(parameters["theta_UB"])   # Unemployment benefit replacement rate
    psi = typeFloat(parameters["psi"])        # Fraction of income devoted to consumption
    psi_H = typeFloat(parameters["psi_H"])      # Fraction of income devoted to investment in housing
    mu = typeFloat(parameters["mu"])         # Risk premium on policy rate

    # banking related parameters
    theta_DIV = typeFloat(parameters["theta_DIV"])  # Dividend payout ratio
    theta = typeFloat(parameters["theta"])      # Rate of installment on debt
    zeta = typeFloat(parameters["zeta"])       # Banks’ capital requirement coefficient
    zeta_LTV = typeFloat(parameters["zeta_LTV"])   # Loan-to-value (LTV) ratio
    zeta_b = typeFloat(parameters["zeta_b"])     # Loan-to-capital ratio for new firms after bankruptcy

    # products related parameters
    b_CF_g = Vector{typeFloat}(vec(parameters["b_CF_g"]))   # Capital formation coefficient g-th product (firm investment)
    b_CFH_g = Vector{typeFloat}(vec(parameters["b_CFH_g"])) # Household investment coefficient of the g-th product
    b_HH_g = Vector{typeFloat}(vec(parameters["b_HH_g"]))   # Consumption coefficient g-th product of households
    c_G_g = Vector{typeFloat}(vec(parameters["c_G_g"]))     # Consumption of the g-th product of the government in mln. Euro
    c_E_g = Vector{typeFloat}(vec(parameters["c_E_g"]))     # Exports of the g-th product in mln. Euro
    c_I_g = Vector{typeFloat}(vec(parameters["c_I_g"]))     # Imports of the gth product in mln. Euro
    a_sg = Matrix{typeFloat}(parameters["a_sg"])            # Technology coefficient of the gth product in the sth industry

    C = Matrix{typeFloat}(parameters["C"])

    D_H = typeFloat(initial_conditions["D_H"])
    K_H = typeFloat(initial_conditions["K_H"])
    sb_other = typeFloat(initial_conditions["sb_other"])
    E_k = typeFloat(initial_conditions["E_k"])
    r_bar = typeFloat(initial_conditions["r_bar"])

    return Properties(G, T_prime, H_act, H_inact, J, L, I_s, I, H, tau_INC, tau_FIRM,
        tau_VAT, tau_SIF,
        tau_SIW, tau_EXPORT, tau_CF, tau_G, theta_UB, psi,
        psi_H, mu, theta_DIV, theta, zeta, zeta_LTV,
        zeta_b, b_CF_g, b_CFH_g, b_HH_g, c_G_g, c_E_g, c_I_g,
        a_sg, C, D_H, K_H, sb_other, E_k, r_bar)
end
