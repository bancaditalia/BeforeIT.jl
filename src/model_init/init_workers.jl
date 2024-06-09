

function init_workers(parameters, initial_conditions, firms; typeInt = Int64, typeFloat = Float64)
 
    H_act = typeInt(parameters["H_act"])
    H_inact = typeInt(parameters["H_inact"])
    I = typeInt(sum(parameters["I_s"]))
    theta_UB = parameters["theta_UB"]
    tau_SIW = parameters["tau_SIW"]
    tau_INC = parameters["tau_INC"]

    sb_other = initial_conditions["sb_other"]
    sb_inact = initial_conditions["sb_inact"]
    w_UB = initial_conditions["w_UB"]
    D_H = initial_conditions["D_H"]
    K_H = initial_conditions["K_H"]

    
    H_W = H_act - I - 1
    P_bar_HH = one(typeFloat)
    w_h = zeros(typeFloat, 1, H_W)
    O_h = zeros(typeInt, 1, H_W)

    h = one(typeInt)

    # copy V_i to avoid changing the original
    V_i_new = copy(firms.V_i)
    w_bar_i = firms.w_bar_i
    for i in 1:I
        while V_i_new[i] > 0
            O_h[h] = i
            w_h[h] = w_bar_i[i]
            V_i_new[i] = V_i_new[i] - 1
            h = h + 1
        end
    end

    w_h[O_h .== 0] .= w_UB / theta_UB
    
    Y_h = zeros(typeFloat, 1, H_W)

    for h in 1:H_W
        if O_h[h] != 0
            Y_h[h] = (w_h[h] * (1 - tau_SIW - tau_INC * (1 - tau_SIW)) + sb_other) * P_bar_HH
        else
            Y_h[h] = (theta_UB * w_h[h] + sb_other) * P_bar_HH
        end
    end

    D_h = D_H * Y_h #/ sum(Y_h)
    K_h = K_H * Y_h #/ sum(Y_h)

    ids = Vector{typeInt}((I + 1):(I + H_W))
    C_d_h = zeros(typeFloat, length(ids))
    I_d_h = zeros(typeFloat, length(ids))
    C_h = zeros(typeFloat, length(ids))
    I_h = zeros(typeFloat, length(ids))
    # active workers (both employed and unemployed)
    workers_act = Workers(Y_h[1:H_W], D_h[1:H_W], K_h[1:H_W], w_h[1:H_W], O_h[1:H_W], C_d_h, I_d_h, C_h, I_h)
    
    # inactive workers
    ids = Vector{typeInt}((I + H_W + 1):(I + H_W + H_inact))


    Y_h = zeros(typeFloat, H_inact)
    for h in 1:H_inact
        Y_h[h] = (sb_inact + sb_other) * P_bar_HH
    end
    D_h = D_H * Y_h #/ sum(Y_h)
    K_h = K_H * Y_h #/ sum(Y_h)

    w_h_inact = zeros(typeFloat, H_inact)
    O_h_inact = -ones(typeInt, H_inact)
    C_d_h = zeros(typeFloat, length(ids))
    I_d_h = zeros(typeFloat, length(ids))
    C_h = zeros(typeFloat, length(ids))
    I_h = zeros(typeFloat, length(ids))
    workers_inact = Workers(
        Y_h,
        D_h,
        K_h,
        w_h_inact,
        O_h_inact,
        C_d_h,
        I_d_h,
        C_h,
        I_h,
    )

    return workers_act, workers_inact, V_i_new
end
