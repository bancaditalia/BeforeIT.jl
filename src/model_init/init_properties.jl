
function Properties(parameters::Dict{String, Any}; typeInt::DataType = Int64, typeFloat::DataType = Float64)
    properties = Dict{Symbol, Any}()
    G = typeInt(parameters["G"])

    properties[:G] = typeInt(G)
    properties[:T_prime] = typeInt(parameters["T_prime"])       # Time interval used to estimate parameters for expectations

    properties[:H_act] = typeInt(parameters["H_act"])    # Number of economically active persons
    properties[:H_inact] = typeInt(parameters["H_inact"])  # Number of economically inactive persons
    # H = I + H_W + H_inact + 1
    
    properties[:J] = typeInt(parameters["J"])       # Number of government entities
    properties[:L] = typeInt(parameters["L"])        # Number of foreign consumers
    properties[:I_s] = Vector{typeInt}(vec(parameters["I_s"]))           # Number of firms/investors in the s-th industry
    properties[:I] = typeInt(sum(parameters["I_s"]))        # Number of firms
    properties[:H] = properties[:H_act] + properties[:H_inact] # Total number of households

    properties[:tau_INC] = typeFloat(parameters["tau_INC"])    # Income tax rate
    properties[:tau_FIRM] = typeFloat(parameters["tau_FIRM"])   # Corporate tax rate
    properties[:tau_VAT] = typeFloat(parameters["tau_VAT"])    # Value-added tax rate
    properties[:tau_SIF] = typeFloat(parameters["tau_SIF"])    # Social insurance rate (employers’ contributions)
    properties[:tau_SIW] = typeFloat(parameters["tau_SIW"])    # Social insurance rate (employees’ contributions)
    properties[:tau_EXPORT] = typeFloat(parameters["tau_EXPORT"]) # Export tax rate
    properties[:tau_CF] = typeFloat(parameters["tau_CF"])     # Tax rate on capital formation
    properties[:tau_G] = typeFloat(parameters["tau_G"])      # Tax rate on government consumption
    properties[:theta_UB] = typeFloat(parameters["theta_UB"])   # Unemployment benefit replacement rate
    properties[:psi] = typeFloat(parameters["psi"])        # Fraction of income devoted to consumption
    properties[:psi_H] = typeFloat(parameters["psi_H"])      # Fraction of income devoted to investment in housing
    properties[:mu] = typeFloat(parameters["mu"])         # Risk premium on policy rate

    # banking related parameters
    properties[:theta_DIV] = typeFloat(parameters["theta_DIV"])  # Dividend payout ratio
    properties[:theta] = typeFloat(parameters["theta"])      # Rate of installment on debt
    properties[:zeta] = typeFloat(parameters["zeta"])       # Banks’ capital requirement coefficient
    properties[:zeta_LTV] = typeFloat(parameters["zeta_LTV"])   # Loan-to-value (LTV) ratio
    properties[:zeta_b] = typeFloat(parameters["zeta_b"])     # Loan-to-capital ratio for new firms after bankruptcy

    # products related parameters
    b_CF_g = parameters["b_CF_g"]  
    b_CFH_g = parameters["b_CFH_g"]
    b_HH_g = parameters["b_HH_g"]
    c_G_g = parameters["c_G_g"]
    c_E_g = parameters["c_E_g"]
    c_I_g = parameters["c_I_g"]
    a_sg = parameters["a_sg"]
    
    properties[:products] = Dict()
    properties[:products][:b_CF_g] = Vector{typeFloat}(vec(b_CF_g))   # Capital formation coefficient g-th product (firm investment)
    properties[:products][:b_CFH_g] = Vector{typeFloat}(vec(b_CFH_g)) # Household investment coefficient of the g-th product
    properties[:products][:b_HH_g] = Vector{typeFloat}(vec(b_HH_g))   # Consumption coefficient g-th product of households
    properties[:products][:c_G_g] = Vector{typeFloat}(vec(c_G_g))     # Consumption of the g-th product of the government in mln. Euro
    properties[:products][:c_E_g] = Vector{typeFloat}(vec(c_E_g))     # Exports of the g-th product in mln. Euro
    properties[:products][:c_I_g] = Vector{typeFloat}(vec(c_I_g))     # Imports of the gth product in mln. Euro
    properties[:products][:a_sg] = a_sg            # Technology coefficient of the gth product in the sth industry

    properties[:C] = parameters["C"]

    # convert to NamedTuple
    properties = recursive_namedtuple(properties)

    return properties
end
