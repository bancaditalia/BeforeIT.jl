

function init_bank(parameters, initial_conditions, firms; typeInt = Int64, typeFloat = Float64)

    theta_DIV = parameters["theta_DIV"]
    tau_INC = parameters["tau_INC"]
    tau_FIRM = parameters["tau_FIRM"]
    mu = parameters["mu"]
    D_H = initial_conditions["D_H"]
    K_H = initial_conditions["K_H"]

    E_k = initial_conditions["E_k"]
    r_bar = initial_conditions["r_bar"]
    sb_other = initial_conditions["sb_other"]

    P_bar_HH = one(typeFloat)
    
    r = r_bar + mu
    
    Pi_k = mu * sum(firms.L_i) + r_bar * E_k

    Y_h = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_k) + sb_other * P_bar_HH

    D_h = D_H * Y_h # Need to normalise wrt sum(Y_h) at the end of initialisation
    K_h = K_H * Y_h # Need to normalise wrt sum(Y_h) at the end of initialisation
    D_k = sum(firms.D_i) + E_k - sum(firms.L_i) # Need to add sum(D_h) at the end of initialisation
    
    C_d_h = zero(typeFloat)
    I_d_h = zero(typeFloat)
    C_h = zero(typeFloat)
    I_h = zero(typeFloat)
    K_h = K_h
    D_h = D_h
    Pi_e_k = typeFloat(0.0)
    bank = Bank(E_k, Pi_k, Pi_e_k, D_k, r, Y_h, C_d_h, I_d_h, C_h, I_h, K_h, D_h)

    return bank
end


function init_central_bank(parameters, initial_conditions; typeInt = Int64, typeFloat = Float64)
    r_bar = initial_conditions["r_bar"]
    r_G = parameters["r_G"]
    rho = parameters["rho"]
    r_star = parameters["r_star"]
    pi_star = parameters["pi_star"]
    xi_pi = parameters["xi_pi"]
    xi_gamma = parameters["xi_gamma"]
    E_CB = initial_conditions["E_CB"]
    
    central_bank = CentralBank(r_bar, r_G, rho, r_star, pi_star, xi_pi, xi_gamma, E_CB)
return central_bank
end