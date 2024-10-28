

"""
    search_and_matching!(model, multi_threading::Bool = false)

This function performs a search and matching algorithm for firms and for retail markets. It takes in a model object 
and an optional boolean argument for multi-threading. The function loops over all goods and performs the firms market 
and retail market operations for each good. Finally, it updates the aggregate variables based on the results of markets.

Args:
- model: The model object
- multi_threading: A boolean indicating whether to use multi-threading for the algorithm. Default is false.

This function updates the model in-place and does not return any value.
"""
function search_and_matching!(model, multi_threading = false)

    # unpack models' variables
    w_act, w_inact, firms, gov, bank, rotw = model.w_act, model.w_inact, model.firms, model.gov, model.bank, model.rotw
    agg, prop = model.agg, model.prop

    # Initialize variables for firms market
    a_sg, b_CF_g, P_f, S_f, S_f_, G_f, I_i_g, DM_i_g, P_bar_i_g, P_CF_i_g =
        initialize_variables_firms_market(firms, rotw, prop)

    # Initialize variables
    I,
    H,
    L,
    J,
    C_d_h,
    I_d_h,
    b_HH_g,
    b_CFH_g,
    c_E_g,
    c_G_g,
    Q_d_i_g,
    Q_d_m_g,
    C_h_g,
    I_h_g,
    C_j_g,
    C_l_g,
    P_bar_h_g,
    P_bar_CF_h_g,
    P_j_g,
    P_l_g = initialize_variables_retail_market(firms, rotw, prop, agg, w_act, w_inact, gov, bank)

    G = size(prop.products.b_HH_g, 1) # number of goods

    # Loop over all goods (internal and foreign)

    function loopBody(g)
        F_g = findall(G_f .== g)
        S_fg = copy(S_f)
        S_fg_ = copy(S_f_)


        perform_firms_market!(
            g,
            firms,
            a_sg,
            b_CF_g,
            P_f,
            S_f,
            S_f_,
            G_f,
            I_i_g,
            DM_i_g,
            P_bar_i_g,
            P_CF_i_g,
            F_g,
            S_fg,
            S_fg_,
        )

        perform_retail_market!(
            g,
            agg,
            gov,
            rotw,
            I,
            H,
            L,
            J,
            C_d_h,
            I_d_h,
            b_HH_g,
            b_CFH_g,
            c_E_g,
            c_G_g,
            Q_d_i_g,
            Q_d_m_g,
            C_h_g,
            I_h_g,
            C_j_g,
            C_l_g,
            P_bar_h_g,
            P_bar_CF_h_g,
            P_j_g,
            P_l_g,
            S_fg,
            S_fg_,
            F_g,
            P_f,
            S_f,
            G_f,
        )
    end


    if multi_threading
        Threads.@threads for g in 1:G
            loopBody(g)
        end
    else
        for g in 1:G
            loopBody(g)
        end
    end

    update_aggregate_variables!(
        agg,
        w_act,
        w_inact,
        firms,
        bank,
        gov,
        rotw,
        P_CF_i_g,
        I_i_g,
        P_bar_i_g,
        DM_i_g,
        C_h_g,
        I_h_g,
        Q_d_i_g,
        Q_d_m_g,
        C_j_g,
        C_l_g,
        P_bar_h_g,
        P_bar_CF_h_g,
        P_j_g,
        P_l_g,
    )

end




function update_aggregate_variables!(
    agg,
    w_act,
    w_inact,
    firms,
    bank,
    gov,
    rotw,
    P_CF_i_g,
    I_i_g,
    P_bar_i_g,
    DM_i_g,
    C_h_g,
    I_h_g,
    Q_d_i_g,
    Q_d_m_g,
    C_j_g,
    C_l_g,
    P_bar_h_g,
    P_bar_CF_h_g,
    P_j_g,
    P_l_g,
)

    I = length(firms)
    H_W = length(w_act)
    H_inact = length(w_inact)
    H = H_W + H_inact + I + 1

    I_i = vec(sum(I_i_g, dims = 1))
    DM_i = vec(sum(DM_i_g, dims = 1))
    P_bar_i = vec(sum(P_bar_i_g, dims = 1))
    P_CF_i = vec(sum(P_CF_i_g, dims = 1))

    Q_d_i = vec(sum(Q_d_i_g, dims = 1))
    Q_d_m = vec(sum(Q_d_m_g, dims = 1))

    C_h = sum(C_h_g, dims = 1)
    I_h = sum(I_h_g, dims = 1)

    gov.C_j = sum(C_j_g)
    rotw.C_l = sum(C_l_g)

    agg.P_bar_h = sum(P_bar_h_g)
    agg.P_bar_CF_h = sum(P_bar_CF_h_g)

    gov.P_j = sum(P_j_g)
    rotw.P_l = sum(P_l_g)

    P_CF_i[I_i .> 0] .= P_CF_i[I_i .> 0] ./ I_i[I_i .> 0]
    P_bar_i[DM_i .> 0] .= P_bar_i[DM_i .> 0] ./ DM_i[DM_i .> 0]

    agg.P_bar_h = sum(C_h) / agg.P_bar_h
    agg.P_bar_CF_h = sum(I_h) / agg.P_bar_CF_h
    gov.P_j = gov.C_j / gov.P_j
    rotw.P_l = rotw.C_l / rotw.P_l

    w_act.C_h .= C_h[1:H_W]
    w_inact.C_h .= C_h[(H_W + 1):(H_W + H_inact)]
    firms.C_h .= C_h[(H_W + H_inact + 1):(H_W + H_inact + I)]
    bank.C_h = C_h[H]

    w_act.I_h .= I_h[1:H_W]
    w_inact.I_h .= I_h[(H_W + 1):(H_W + H_inact)]
    firms.I_h .= I_h[(H_W + H_inact + 1):(H_W + H_inact + I)]
    bank.I_h = I_h[H]

    rotw.Q_d_m .= Q_d_m

    firms.I_i .= I_i
    firms.Q_d_i .= Q_d_i
    firms.P_bar_i .= P_bar_i
    firms.DM_i .= DM_i
    firms.P_CF_i .= P_CF_i

    # compute sales as minimum between supply and demand (internal and external)
    firms.Q_i = min.(firms.Y_i .+ firms.S_i, firms.Q_d_i)
    rotw.Q_m = min.(rotw.Y_m, Q_d_m)

    # update households capital stock with investments
    w_act.K_h .+= w_act.I_h
    w_inact.K_h .+= w_inact.I_h
    firms.K_h .+= firms.I_h
    bank.K_h += bank.I_h

end

function initialize_variables_retail_market(firms, rotw, prop, agg, w_act, w_inact, gov, bank)
    # ... Initialize all the variables ...

    # change some variables according to arguments of matlab function
    b_HH_g = agg.P_bar_g .* prop.products.b_HH_g / sum(agg.P_bar_g .* prop.products.b_HH_g) #prop.products.b_HH_g
    b_CFH_g = agg.P_bar_g .* prop.products.b_CFH_g / sum(agg.P_bar_g .* prop.products.b_CFH_g)   #prop.products.b_CFH_g
    c_G_g = agg.P_bar_g .* prop.products.c_G_g / sum(agg.P_bar_g .* prop.products.c_G_g)   #prop.products.c_G_g
    c_E_g = agg.P_bar_g .* prop.products.c_E_g / sum(agg.P_bar_g .* prop.products.c_E_g)   #prop.products.c_E_g

    G = size(agg.P_bar_g, 1)

    # retrieve some general lengths from existing arrays
    I = size(firms.P_i, 1)            # number of firms
    H_W = length(w_act)           # number of active households
    H_inact = length(w_inact)     # number of inactive households
    H = H_W + H_inact + I + 1      # number of households
    L = size(rotw.C_d_l, 1)        # number of export partners
    J = size(gov.C_d_j, 1)       # number of government entities


    # define a global C_d_h and I_d_h
    C_d_h = [w_act.C_d_h; w_inact.C_d_h; firms.C_d_h; bank.C_d_h]
    I_d_h = [w_act.I_d_h; w_inact.I_d_h; firms.I_d_h; bank.I_d_h]

    # initialise some vectors of variables to zeros
    Q_d_i_g = zeros(G, size(firms.Y_i)...)
    Q_d_m_g = zeros(G, size(rotw.Y_m)...)

    C_h_g = zeros(G, H)
    I_h_g = zeros(G, H)

    C_j_g = zeros(G, 1)
    C_l_g = zeros(G, 1)

    P_bar_h_g = zeros(G, 1)
    P_bar_CF_h_g = zeros(G, 1)

    P_j_g = zeros(G, 1)
    P_l_g = zeros(G, 1)

    return I,
    H,
    L,
    J,
    C_d_h,
    I_d_h,
    b_HH_g,
    b_CFH_g,
    c_E_g,
    c_G_g,
    Q_d_i_g,
    Q_d_m_g,
    C_h_g,
    I_h_g,
    C_j_g,
    C_l_g,
    P_bar_h_g,
    P_bar_CF_h_g,
    P_j_g,
    P_l_g

end

function initialize_variables_firms_market(firms, rotw, prop)
    # ... Initialize all the variables ...

    # copy product variables for convenience
    a_sg = prop.products.a_sg
    b_CF_g = prop.products.b_CF_g

    G = length(prop.products.b_HH_g) # number of goods
    I = length(firms)            # number of firms

    # join internal and foreign firms arrays
    P_f = [firms.P_i; rotw.P_m]                    # price array (firms + foreign firms)) 
    S_f = [firms.Y_i + firms.S_i; rotw.Y_m]        # size array (firms + foreign firms)
    S_i_ = firms.K_i .* firms.kappa_i .- firms.Y_i  # (from matlab inputs)
    S_f_ = [S_i_; ones(size(rotw.Y_m)) .* Inf]      # Join S_i_ with an array of Infs of size(Y_m)
    G_f = [firms.G_i; collect(1:G)]                # enlarge vector of final goods with foreign firms

    I_i_g = zeros(G, I)         # output
    P_CF_i_g = zeros(G, I)
    DM_i_g = zeros(G, I)
    P_bar_i_g = zeros(G, I)

    return a_sg, b_CF_g, P_f, S_f, S_f_, G_f, I_i_g, DM_i_g, P_bar_i_g, P_CF_i_g

end

function perform_firms_market!(
    g,
    firms,
    a_sg,
    b_CF_g,
    P_f,
    S_f,
    S_f_,
    G_f,
    I_i_g,
    DM_i_g,
    P_bar_i_g,
    P_CF_i_g,
    F_g,
    S_fg,
    S_fg_,
)
    # ... Perform the firms market exchange process ...

    ##############################
    ######## FIRMS MARKET ########
    ##############################

    DM_d_ig = a_sg[g, firms.G_i] .* firms.DM_d_i + b_CF_g[g] .* firms.I_d_i
    DM_nominal_ig = zeros(size(DM_d_ig))

    # firms that have demand for good "g" participate as buyers
    I_g = findall(DM_d_ig .> 0)

    # remove firms that have no stock of good "g"
    #F_g[S_fg[F_g] .<= 0] .= []
    to_delete = findall(S_fg[F_g] .<= 0)
    deleteat!(F_g, to_delete)

    # continue exchanges until either demand or supply terminates

    while length(I_g) != 0 && length(F_g) != 0

        # price probability of being selected
        pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))

        # size probability of being selected
        pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
        # total probabilities of being selected

        pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)
        #pr_cum_f = [0; cumsum(pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)]

        # select buyers at random
        shuffle!(I_g)
        for j in eachindex(I_g)
            i = I_g[j]

            # select a random firm according to the probabilities
            e = wsample_single(1:length(F_g), pr_cum_f_)
            #e = randf(pr_cum_f)
            f = F_g[e]

            # selected firm has sufficient stock
            if S_fg[f] > DM_d_ig[i]
                S_fg[f] -= DM_d_ig[i]
                DM_nominal_ig[i] += DM_d_ig[i] .* P_f[f]
                DM_d_ig[i] = 0

            else
                DM_d_ig[i] -= S_fg[f]
                DM_nominal_ig[i] += S_fg[f] .* P_f[f]
                S_fg[f] = 0
                F_g = deleteat!(F_g, e)

                if isempty(F_g)
                    break
                end
                pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
                pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
                pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)
            end
        end
        I_g = findall(DM_d_ig .> 0)
    end


    if !isempty(I_g)
        DM_d_ig_ = copy(DM_d_ig)
        I_g = findall(DM_d_ig_ .> 0)
        F_g = findall(G_f .== g)

        to_delete = findall((S_fg_[F_g] .<= 0.0) .|| (S_f[F_g] .<= 0.0))
        deleteat!(F_g, to_delete)

        while !isempty(I_g) && !isempty(F_g)
            pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
            pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
            pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)

            # I_g = I_g[randperm(length(I_g))]
            shuffle!(I_g)
            for j in eachindex(I_g)
                i = I_g[j]

                e = wsample_single(1:length(F_g), pr_cum_f_)
                f = F_g[e]

                if S_fg_[f] > DM_d_ig_[i]
                    S_fg[f] -= DM_d_ig_[i]
                    S_fg_[f] -= DM_d_ig_[i]
                    DM_d_ig_[i] = 0
                else
                    DM_d_ig_[i] -= S_fg_[f]
                    S_fg[f] -= S_fg_[f]
                    S_fg_[f] = 0
                    deleteat!(F_g, e)
                    if isempty(F_g)
                        break
                    end
                    pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
                    pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
                    pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)
                end
            end
            I_g = findall(DM_d_ig_ .> 0)
        end
    end

    DM_i_g[g, :] .= a_sg[g, firms.G_i] .* firms.DM_d_i .- pos(DM_d_ig .- b_CF_g[g] .* firms.I_d_i)

    I_i_g[g, :] .= pos(b_CF_g[g] .* firms.I_d_i .- DM_d_ig)

    P_bar_i_g[g, :] .= pos(
        DM_nominal_ig .* (a_sg[g, firms.G_i] .* firms.DM_d_i .- pos(DM_d_ig .- b_CF_g[g] .* firms.I_d_i)) ./
        (a_sg[g, firms.G_i] .* firms.DM_d_i .+ b_CF_g[g] .* firms.I_d_i .- DM_d_ig),
    )

    P_CF_i_g[g, :] .= pos(
        DM_nominal_ig .* pos(b_CF_g[g] .* firms.I_d_i .- DM_d_ig) ./
        (a_sg[g, firms.G_i] .* firms.DM_d_i .+ b_CF_g[g] .* firms.I_d_i .- DM_d_ig),
    )

end

function perform_retail_market!(
    g,
    agg,
    gov,
    rotw,
    I,
    H,
    L,
    J,
    C_d_h,
    I_d_h,
    b_HH_g,
    b_CFH_g,
    c_E_g,
    c_G_g,
    Q_d_i_g,
    Q_d_m_g,
    C_h_g,
    I_h_g,
    C_j_g,
    C_l_g,
    P_bar_h_g,
    P_bar_CF_h_g,
    P_j_g,
    P_l_g,
    S_fg,
    S_fg_,
    F_g,
    P_f,
    S_f,
    G_f,
)
    # ... Perform the retail market exchange process ...

    ###############################
    ######## RETAIL MARKET ########
    ###############################
    C_d_hg = [
        b_HH_g[g] .* C_d_h .+ b_CFH_g[g] .* I_d_h
        c_E_g[g] .* rotw.C_d_l
        c_G_g[g] .* gov.C_d_j
    ]
    C_real_hg = zeros(size(C_d_hg))
    H_g = findall(C_d_hg .> 0.0)

    to_delete = findall(S_fg[F_g] .<= 0)
    deleteat!(F_g, to_delete)


    while !isempty(H_g) && !isempty(F_g)
        pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
        pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
        pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)

        shuffle!(H_g)
        for j in eachindex(H_g)
            h = H_g[j]

            e = wsample_single(1:length(F_g), pr_cum_f_)
            f = F_g[e]

            if S_fg[f] > C_d_hg[h] / P_f[f]
                S_fg[f] -= C_d_hg[h] / P_f[f]
                C_real_hg[h] += C_d_hg[h] / P_f[f]
                C_d_hg[h] = 0
            else
                C_d_hg[h] -= S_fg[f] * P_f[f]
                C_real_hg[h] += S_fg[f]
                S_fg[f] = 0
                F_g = F_g[setdiff(1:end, e)]
                if isempty(F_g)
                    break
                end
                pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
                pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
                pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)
            end
        end
        H_g = findall(C_d_hg .> 0)
    end

    if !isempty(H_g)
        C_d_hg_ = copy(C_d_hg)
        H_g = findall(C_d_hg_ .> 0)
        F_g = findall(G_f .== g)
        F_g = F_g[(S_fg_[F_g] .> 0) .& (S_f[F_g] .> 0)]
        while !isempty(H_g) && !isempty(F_g)
            pr_price_f = pos(exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
            pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
            pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)

            H_g = shuffle(H_g)
            for j in eachindex(H_g)
                h = H_g[j]
                e = wsample_single(1:length(F_g), pr_cum_f_)
                f = F_g[e]

                if S_fg_[f] > C_d_hg_[h] / P_f[f]
                    S_fg[f] -= C_d_hg_[h] / P_f[f]
                    S_fg_[f] -= C_d_hg_[h] / P_f[f]
                    C_d_hg_[h] = 0
                else
                    C_d_hg_[h] -= S_fg_[f] * P_f[f]
                    S_fg[f] -= S_fg_[f]
                    S_fg_[f] = 0
                    F_g = deleteat!(F_g, e)
                    if isempty(F_g)
                        break
                    end
                    pr_price_f = max.(0, exp.(-2 .* P_f[F_g]) ./ sum(exp.(-2 .* P_f[F_g])))
                    pr_price_f[isnan.(pr_price_f)] .= 0.0
                    pr_size_f = S_f[F_g] ./ sum(S_f[F_g])
                    pr_cum_f_ = (pr_price_f + pr_size_f) ./ sum(pr_price_f + pr_size_f)

                end
            end
            H_g = findall(C_d_hg_ .> 0)
        end
    end

    Q_d_i_g[g, :] .= S_f[1:I] .- S_fg[1:I]
    Q_d_m_g[g, :] .= S_f[(I + 1):end] .- S_fg[(I + 1):end]

    C_h_g[g, :] .= b_HH_g[g] .* C_d_h .- pos(C_d_hg[1:H] .- b_CFH_g[g] .* I_d_h)
    I_h_g[g, :] .= pos(b_CFH_g[g] .* I_d_h .- view(C_d_hg, 1:H))  #I_h_g[g, :] .= pos(b_CFH_g[g] .* I_d_h .- C_d_hg[1:H])

    C_j_g[g] = sum(c_G_g[g] .* gov.C_d_j) - sum(C_d_hg[(H + L + 1):(H + L + J)])
    C_l_g[g] = sum(c_E_g[g] .* rotw.C_d_l) - sum(C_d_hg[(H + 1):(H + L)])

    a = sum(C_real_hg[1:H])
    b = sum(C_d_h .* b_HH_g[g] .- pos(view(C_d_hg, 1:H) .- b_CFH_g[g] .* I_d_h)) # b = sum(C_d_h .* b_HH_g[g] .- pos(C_d_hg[1:H] .- b_CFH_g[g] .* I_d_h)) # OLD
    c = sum((C_d_h .* b_HH_g[g] .+ b_CFH_g[g] .* I_d_h .- C_d_hg[1:H]))

    P_bar_h_g[g] = pos(a * b / c)

    P_bar_CF_h_g[g] = pos(
        sum(C_real_hg[1:H]) * sum(pos(b_CFH_g[g] .* I_d_h .- C_d_hg[1:H])) /
        sum((C_d_h .* b_HH_g[g] .+ b_CFH_g[g] .* I_d_h .- C_d_hg[1:H])),
    )

    P_j_g[g] = sum(C_real_hg[(H + L + 1):(H + L + J)])
    P_l_g[g] = sum(C_real_hg[(H + 1):(H + L)])

end
