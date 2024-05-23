using MutableNamedTuples
recursive_namedtuple(x::Any) = x
recursive_namedtuple(d::Dict) = MutableNamedTuple(;Dict(k => recursive_namedtuple(v) for (k, v) in d)...)

"""
    initialise_model(parameters, initial_conditions, T, typeInt = Int64, typeFloat = Float64)

Initializes the model with given parameters and initial conditions.

Parameters:
- `parameters`: A dictionary containing the model parameters.
- initial_conditions: A dictionary containing the initial conditions.
- T (integer): The time horizon of the model.
- typeInt: (optional, default: Int64): The data type to be used for integer values.
- typeFloat: (optional, default: Float64): The data type to be used for floating-point values.

Returns:
- model::Model: The initialized model.

"""
function initialise_model(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any}, T, typeInt::DataType = Int64, typeFloat::DataType = Float64)

    ###########################################
    ############# Parameter imports ###########
    ###########################################

    #T = typeInt(parameters["T"])
    #G = typeInt(parameters["G"])
    G = 62

    T_prime = typeInt(parameters["T_prime"])
    T_max = typeInt(parameters["T_max"])

    H_act = typeInt(parameters["H_act"])
    H_inact = typeInt(parameters["H_inact"])
    J = typeInt(parameters["J"])
    L = typeInt(parameters["L"])
    I_s = Vector{typeInt}(vec(parameters["I_s"]))
    I = typeInt(sum(parameters["I_s"]))

    # government related parameters
    tau_INC = parameters["tau_INC"]
    tau_FIRM = parameters["tau_FIRM"]
    tau_VAT = parameters["tau_VAT"]
    tau_SIF = parameters["tau_SIF"]
    tau_SIW = parameters["tau_SIW"]
    tau_EXPORT = parameters["tau_EXPORT"]
    tau_CF = parameters["tau_CF"]
    tau_G = parameters["tau_G"]
    theta_UB = parameters["theta_UB"]
    psi = parameters["psi"]
    psi_H = parameters["psi_H"]
    theta_DIV = parameters["theta_DIV"]
    theta = parameters["theta"]
    zeta = parameters["zeta"]
    zeta_LTV = parameters["zeta_LTV"]
    zeta_b = parameters["zeta_b"]
    mu = parameters["mu"]
    r_G = parameters["r_G"]

    # products related parameters
    b_CF_g = parameters["b_CF_g"]
    b_CFH_g = parameters["b_CFH_g"]
    b_HH_g = parameters["b_HH_g"]
    c_G_g = parameters["c_G_g"]
    c_E_g = parameters["c_E_g"]
    c_I_g = parameters["c_I_g"]
    a_sg = parameters["a_sg"]

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

    alpha_pi_EA = parameters["alpha_pi_EA"]
    beta_pi_EA = parameters["beta_pi_EA"]
    sigma_pi_EA = parameters["sigma_pi_EA"]
    alpha_Y_EA = parameters["alpha_Y_EA"]
    beta_Y_EA = parameters["beta_Y_EA"]
    sigma_Y_EA = parameters["sigma_Y_EA"]

    rho = parameters["rho"]
    r_star = parameters["r_star"]
    xi_pi = parameters["xi_pi"]
    xi_gamma = parameters["xi_gamma"]
    pi_star = parameters["pi_star"]


    alpha_G = parameters["alpha_G"]
    beta_G = parameters["beta_G"]
    sigma_G = parameters["sigma_G"]
    alpha_E = parameters["alpha_E"]
    beta_E = parameters["beta_E"]
    sigma_E = parameters["sigma_E"]
    alpha_I = parameters["alpha_I"]
    beta_I = parameters["beta_I"]
    sigma_I = parameters["sigma_I"]

    C = parameters["C"]
    Y = initial_conditions["Y"]
    pi_ = initial_conditions["pi"]
    r_bar = initial_conditions["r_bar"]
    Y_EA = initial_conditions["Y_EA"]
    gamma_EA = typeFloat(0.0)
    pi_EA = initial_conditions["pi_EA"]

    C_G = Vector{typeFloat}(vec(initial_conditions["C_G"]))
    C_E = Vector{typeFloat}(vec(initial_conditions["C_E"]))
    Y_I = Vector{typeFloat}(vec(initial_conditions["Y_I"]))

    Y = Vector{typeFloat}(vec(vcat(Y, zeros(typeFloat, T))))
    pi_ = Vector{typeFloat}(vec(vcat(pi_, zeros(typeFloat, T))))

    D_H = initial_conditions["D_H"]
    D_I = initial_conditions["D_I"]
    D_RoW = typeFloat(initial_conditions["D_RoW"])
    E_CB = initial_conditions["E_CB"]
    E_k = initial_conditions["E_k"]
    K_H = initial_conditions["K_H"]
    L_G = initial_conditions["L_G"]
    L_I = initial_conditions["L_I"]
    omega = initial_conditions["omega"]
    sb_inact = initial_conditions["sb_inact"]
    sb_other = initial_conditions["sb_other"]
    w_UB = initial_conditions["w_UB"]
    N_s = BeforeIT.round.(Int, initial_conditions["N_s"])

    P_bar = one(typeFloat)
    P_bar_g = ones(typeFloat, G)
    P_bar_HH = one(typeFloat)
    P_bar_CF = one(typeFloat)

    N_i = zeros(typeInt, I)
    for g in 1:G
        N_i[G_i .== g] .= randpl(I_s[g], 2.0, N_s[g])
    end

    Y_i = alpha_bar_i .* N_i
    Q_d_i = copy(Y_i)
    P_i = ones(typeFloat, I)
    S_i = zeros(typeFloat, I)
    K_i = Y_i ./ (omega .* kappa_i)
    M_i = Y_i ./ (omega .* beta_i)
    L_i = L_I .* K_i / sum(K_i)

    pi_bar_i = 1 .- (1 + tau_SIF) .* w_bar_i ./ alpha_bar_i .- delta_i ./ kappa_i .- 1 ./ beta_i .- tau_K_i .- tau_Y_i
    D_i = D_I .* max.(0, pi_bar_i .* Y_i) / sum(max.(0, pi_bar_i .* Y_i))

    r = r_bar + mu
    Pi_i = pi_bar_i .* Y_i - r .* L_i + r_bar .* max.(0, D_i)

    Pi_k = mu * sum(L_i) + r_bar * E_k

    H_W = H_act - I - 1
    w_h = zeros(typeFloat, 1, H_W)
    O_h = zeros(typeInt, 1, H_W)
    V_i = copy(N_i)

    h = one(typeInt)
    for i in 1:I
        while V_i[i] > 0
            O_h[h] = i
            w_h[h] = w_bar_i[i]
            V_i[i] = V_i[i] - 1
            h = h + 1
        end
    end

    w_h[O_h .== 0] .= w_UB / theta_UB

    H = H_act + H_inact
    Y_h = zeros(typeFloat, 1, H)

    for h in 1:H
        if h <= H_W
            if O_h[h] != 0
                Y_h[h] = (w_h[h] * (1 - tau_SIW - tau_INC * (1 - tau_SIW)) + sb_other) * P_bar_HH
            else
                Y_h[h] = (theta_UB * w_h[h] + sb_other) * P_bar_HH
            end
        elseif h > H_W && h <= H_W + H_inact
            Y_h[h] = (sb_inact + sb_other) * P_bar_HH
        elseif h > H_W + H_inact && h <= H_W + H_inact + I
            i = h - (H_W + H_inact)
            Y_h[h] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_i[i]) + sb_other * P_bar_HH
        elseif h > H_W + H_inact + I && h <= H
            Y_h[h] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_k) + sb_other * P_bar_HH

        end
    end

    D_h = D_H * Y_h / sum(Y_h)
    K_h = K_H * Y_h / sum(Y_h)
    D_k = sum(D_i) + sum(D_h) + E_k - sum(L_i)

    H = I + H_W + H_inact + 1
    ###########################################
    ################ ABM setup ################
    ###########################################

    properties = Dict{Symbol, Any}()

    properties[:T] = T
    properties[:G] = G
    properties[:T_prime] = T_prime       # Time interval used to estimate parameters for expectations

    properties[:H_act] = typeInt(H_act)    # Number of economically active persons
    properties[:H_inact] = typeInt(H_inact)  # Number of economically inactive persons
    properties[:J] = typeInt(J)        # Number of government entities
    properties[:L] = typeInt(L)        # Number of foreign consumers
    properties[:I_s] = I_s           # Number of firms/investors in the s-th industry
    properties[:I] = typeInt(I)        # Number of firms
    properties[:H] = typeInt(H)

    properties[:tau_INC] = tau_INC    # Income tax rate
    properties[:tau_FIRM] = tau_FIRM   # Corporate tax rate
    properties[:tau_VAT] = tau_VAT    # Value-added tax rate
    properties[:tau_SIF] = tau_SIF    # Social insurance rate (employers’ contributions)
    properties[:tau_SIW] = tau_SIW    # Social insurance rate (employees’ contributions)
    properties[:tau_EXPORT] = tau_EXPORT # Export tax rate
    properties[:tau_CF] = tau_CF     # Tax rate on capital formation
    properties[:tau_G] = tau_G      # Tax rate on government consumption
    properties[:theta_UB] = theta_UB   # Unemployment benefit replacement rate
    properties[:psi] = psi        # Fraction of income devoted to consumption
    properties[:psi_H] = psi_H      # Fraction of income devoted to investment in housing
    properties[:mu] = mu         # Risk premium on policy rate

    # banking related parameters
    properties[:theta_DIV] = theta_DIV  # Dividend payout ratio
    properties[:theta] = theta      # Rate of installment on debt
    properties[:zeta] = zeta       # Banks’ capital requirement coefficient
    properties[:zeta_LTV] = zeta_LTV   # Loan-to-value (LTV) ratio
    properties[:zeta_b] = zeta_b     # Loan-to-capital ratio for new firms after bankruptcy

    properties[:products] = Dict()
    properties[:products][:b_CF_g] = Vector{typeFloat}(vec(b_CF_g))   # Capital formation coefficient g-th product (firm investment)
    properties[:products][:b_CFH_g] = Vector{typeFloat}(vec(b_CFH_g)) # Household investment coefficient of the g-th product
    properties[:products][:b_HH_g] = Vector{typeFloat}(vec(b_HH_g))   # Consumption coefficient g-th product of households
    properties[:products][:c_G_g] = Vector{typeFloat}(vec(c_G_g))     # Consumption of the g-th product of the government in mln. Euro
    properties[:products][:c_E_g] = Vector{typeFloat}(vec(c_E_g))     # Exports of the g-th product in mln. Euro
    properties[:products][:c_I_g] = Vector{typeFloat}(vec(c_I_g))     # Imports of the gth product in mln. Euro
    properties[:products][:a_sg] = a_sg            # Technology coefficient of the gth product in the sth industry

    properties[:C] = C

    # convert to NamedTuple
    properties = recursive_namedtuple(properties)

    # firms
    ids = Vector{typeInt}(1:I)
    w_i = zeros(typeFloat, I) # initial wages, dummy variable for now, really initialised at runtime
    I_i = zeros(typeFloat, I) # initial investments, dummy variable for now, set at runtime
    Q_i = zeros(typeFloat, I) # goods sold, dummy variable for now, set at runtime
    E_i = zeros(typeFloat, I) # equity, dummy variable for now, set at runtime
    C_d_h = zeros(typeFloat, I)
    I_d_h = zeros(typeFloat, I)
    Y_h_i = Y_h[(H_W + H_inact + 1):(H_W + H_inact + I)]
    C_h = zeros(typeFloat, length(ids))
    I_h = zeros(typeFloat, length(ids))
    P_bar_i = zeros(typeFloat, length(ids))
    P_CF_i = zeros(typeFloat, length(ids))
    DS_i = zeros(typeFloat, length(ids))
    DM_i = zeros(typeFloat, length(ids))

    K_h_i = K_h[(H_W + H_inact + 1):(H_W + H_inact + I)]
    D_h_i = D_h[(H_W + H_inact + 1):(H_W + H_inact + I)]

    Q_s_i = zeros(typeFloat, I)
    I_d_i = zeros(typeFloat, I)
    DM_d_i = zeros(typeFloat, I)
    N_d_i = zeros(typeInt, I)
    Pi_e_i = zeros(typeFloat, I)

    firms = Firms(
        G_i,
        alpha_bar_i,
        beta_i,
        kappa_i,
        w_i,
        w_bar_i,
        delta_i,
        tau_Y_i,
        tau_K_i,
        N_i,
        Y_i,
        Q_i,
        Q_d_i,
        P_i,
        S_i,
        K_i,
        M_i,
        L_i,
        pi_bar_i,
        D_i,
        Pi_i,
        V_i,
        I_i,
        E_i,
        P_bar_i,
        P_CF_i,
        DS_i,
        DM_i,
        zeros(typeFloat, I), # DL_i
        zeros(typeFloat, I), # DL_d_i
        zeros(typeFloat, I), # K_e_i
        zeros(typeFloat, I), # L_e_i
        zeros(typeFloat, I), # Q_s_i
        zeros(typeFloat, I), # I_d_i
        zeros(typeFloat, I), # DM_d_i
        zeros(typeInt, I),   # N_d_i
        zeros(typeFloat, I), # Pi_e_i
        Y_h_i,
        C_d_h,
        I_d_h,
        C_h,
        I_h,
        K_h_i,
        D_h_i,
    )

    ids = Vector{typeInt}((I + 1):(I + H_W))
    C_d_h = zeros(typeFloat, length(ids))
    I_d_h = zeros(typeFloat, length(ids))
    C_h = zeros(typeFloat, length(ids))
    I_h = zeros(typeFloat, length(ids))
    # active workers (both employed and unemployed)
    workers_act = Workers(Y_h[1:H_W], D_h[1:H_W], K_h[1:H_W], w_h[1:H_W], O_h[1:H_W], C_d_h, I_d_h, C_h, I_h)

    # inactive workers
    ids = Vector{typeInt}((I + H_W + 1):(I + H_W + H_inact))
    w_h_inact = zeros(typeFloat, H_inact)
    O_h_inact = -ones(typeInt, H_inact)
    C_d_h = zeros(typeFloat, length(ids))
    I_d_h = zeros(typeFloat, length(ids))
    C_h = zeros(typeFloat, length(ids))
    I_h = zeros(typeFloat, length(ids))
    workers_inact = Workers(
        Y_h[(H_W + 1):(H_W + H_inact)],
        D_h[(H_W + 1):(H_W + H_inact)],
        K_h[(H_W + 1):(H_W + H_inact)],
        w_h_inact,
        O_h_inact,
        C_d_h,
        I_d_h,
        C_h,
        I_h,
    )

    id = typeInt(I + H_W + H_inact + 1)
    Y_h_k = Y_h[H_W + H_inact + I + 1]
    C_d_h = zero(typeFloat)
    I_d_h = zero(typeFloat)
    C_h = zero(typeFloat)
    I_h = zero(typeFloat)
    K_h = K_h[H_W + H_inact + I + 1]
    D_h = D_h[H_W + H_inact + I + 1]
    Pi_e_k = typeFloat(0.0)
    bank = Bank(E_k, Pi_k, Pi_e_k, D_k, r, Y_h_k, C_d_h, I_d_h, C_h, I_h, K_h, D_h)

    id = typeInt(I + H_W + H_inact + 2)
    central_bank = CentralBank(r_bar, r_G, rho, r_star, pi_star, xi_pi, xi_gamma, E_CB)

    id = typeInt(I + H_W + H_inact + 3)
    C_d_j = Vector{typeFloat}(zeros(J))
    C_j = zero(typeFloat)
    P_j = zero(typeFloat)
    Y_G = zero(typeFloat)
    government = Government(alpha_G, beta_G, sigma_G, Y_G, C_G[T_prime], L_G, sb_inact, sb_other, C_d_j, C_j, P_j)

    id = typeInt(I + H_W + H_inact + 4)
    C_d_l = Vector{typeFloat}(zeros(L))
    C_l = zero(typeFloat)
    P_l = zero(typeFloat)
    Y_m = Vector{typeFloat}(zeros(G))
    Q_m = Vector{typeFloat}(zeros(G))
    Q_d_m = Vector{typeFloat}(zeros(G))
    P_m = Vector{typeFloat}(zeros(G))
    rotw = RestOfTheWorld(
        alpha_E,
        beta_E,
        sigma_E,
        alpha_I,
        beta_I,
        sigma_I,
        Y_EA,
        gamma_EA,
        pi_EA,
        alpha_pi_EA,
        beta_pi_EA,
        sigma_pi_EA,
        alpha_Y_EA,
        beta_Y_EA,
        sigma_Y_EA,
        D_RoW,
        Y_I[T_prime],
        C_E[T_prime],
        C_d_l,
        C_l,
        Y_m,
        Q_m,
        Q_d_m,
        P_m,
        P_l,
    )

    P_bar_h = zero(typeFloat)
    P_bar_CF_h = zero(typeFloat)
    t = typeInt(1)
    Y_e = zero(typeFloat)
    gamma_e = zero(typeFloat)
    pi_e = zero(typeFloat)
    epsilon_Y_EA = zero(typeFloat)
    epsilon_E = zero(typeFloat)
    epsilon_I = zero(typeFloat)
    agg = Aggregates(
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
    )
    model = Model(workers_act, workers_inact, firms, bank, central_bank, government, rotw, agg, properties)

    return model

end
