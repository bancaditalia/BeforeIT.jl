
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
function search_and_matching!(model::AbstractModel, multi_threading = false)

    # unpack models' variables
    w_act, w_inact, firms, gov = model.w_act, model.w_inact, model.firms, model.gov
    bank, rotw, agg, prop = model.bank, model.rotw, model.agg, model.prop

    # Initialize variables for firms market
    a_sg, b_CF_g, P_f, S_f, S_f_, G_f, I_i_g, DM_i_g, P_bar_i_g,
    P_CF_i_g = initialize_variables_firms_market(firms, rotw, prop)

    # Initialize variables
    I, H, L, J, C_d_h, I_d_h, b_HH_g, b_CFH_g, c_E_g, c_G_g,
    Q_d_i_g, Q_d_m_g, C_h_t, I_h_t, C_j_g, C_l_g, P_bar_h_g, 
    P_bar_CF_h_g, P_j_g, P_l_g = initialize_variables_retail_market(
        firms, rotw, prop, agg, w_act, w_inact, gov, bank, multi_threading
    )

    G = size(prop.b_HH_g, 1) # number of goods

    # Loop over all goods (internal and foreign)
    function perform_market!(i, g)
        # retrieve all indices with good g
        F_g = findall(x -> x == g, G_f)
        S_fg = copy(S_f)
        S_fg_ = copy(S_f_)

        perform_firms_market!(
            g, firms, a_sg, b_CF_g, P_f, S_f, S_f_, I_i_g, DM_i_g,
            P_bar_i_g, P_CF_i_g, F_g, S_fg, S_fg_, G_f
        )

        perform_retail_market!(
            i, g, agg, gov, rotw, I, H, L, J, C_d_h, I_d_h,
            b_HH_g, b_CFH_g, c_E_g, c_G_g, Q_d_i_g, Q_d_m_g,
            C_h_t, I_h_t, C_j_g, C_l_g, P_bar_h_g, P_bar_CF_h_g,
            P_j_g, P_l_g, S_fg, S_fg_, F_g, P_f, S_f, G_f
        )
    end

    if multi_threading
        Threads.@threads for (i, gs) in enumerate(chunks(shuffle(1:G); n=Threads.nthreads()))
            for g in gs
                perform_market!(i, g)
            end
        end
    else
        for g in 1:G
            perform_market!(1, g)
        end
    end

    update_aggregate_variables!(
        agg, w_act, w_inact, firms, bank, gov, rotw, P_CF_i_g, I_i_g,
        P_bar_i_g, DM_i_g, C_h_t, I_h_t, Q_d_i_g, Q_d_m_g, C_j_g,
        C_l_g, P_bar_h_g, P_bar_CF_h_g, P_j_g, P_l_g,
    )
end

function update_aggregate_variables!(
    agg, w_act, w_inact, firms, bank, gov, rotw, P_CF_i_g, I_i_g,
    P_bar_i_g, DM_i_g, C_h_t, I_h_t, Q_d_i_g, Q_d_m_g, C_j_g, C_l_g,
    P_bar_h_g, P_bar_CF_h_g, P_j_g, P_l_g,
)

    I = length(firms)
    H_W = length(w_act)
    H_inact = length(w_inact)
    H = H_W + H_inact + I + 1

    I_i = vec(sum(I_i_g, dims = 2))
    DM_i = vec(sum(DM_i_g, dims = 2))
    P_bar_i = vec(sum(P_bar_i_g, dims = 2))
    P_CF_i = vec(sum(P_CF_i_g, dims = 2))

    Q_d_i = vec(sum(Q_d_i_g, dims = 2))
    Q_d_m = vec(sum(Q_d_m_g, dims = 2))

    C_h = sum(C_h_t, dims = 2)
    I_h = sum(I_h_t, dims = 2)

    gov.C_j = sum(C_j_g)
    rotw.C_l = sum(C_l_g)

    agg.P_bar_h = sum(P_bar_h_g)
    agg.P_bar_CF_h = sum(P_bar_CF_h_g)

    gov.P_j = sum(P_j_g)
    rotw.P_l = sum(P_l_g)

    P_CF_i[I_i .> 0] .= @view(P_CF_i[I_i .> 0]) ./ @view(I_i[I_i .> 0])
    P_bar_i[DM_i .> 0] .= @view(P_bar_i[DM_i .> 0]) ./ @view(DM_i[DM_i .> 0])

    agg.P_bar_h = sum(C_h) / agg.P_bar_h
    agg.P_bar_CF_h = sum(I_h) / agg.P_bar_CF_h
    gov.P_j = gov.C_j / gov.P_j
    rotw.P_l = rotw.C_l / rotw.P_l

    w_act.C_h .= @view(C_h[1:H_W])
    w_inact.C_h .= @view(C_h[(H_W + 1):(H_W + H_inact)])
    firms.C_h .= @view(C_h[(H_W + H_inact + 1):(H_W + H_inact + I)])
    bank.C_h = C_h[H]

    w_act.I_h .= @view(I_h[1:H_W])
    w_inact.I_h .= @view(I_h[(H_W + 1):(H_W + H_inact)])
    firms.I_h .= @view(I_h[(H_W + H_inact + 1):(H_W + H_inact + I)])
    bank.I_h = I_h[H]

    rotw.Q_d_m .= Q_d_m

    firms.I_i .= I_i
    firms.Q_d_i .= Q_d_i
    firms.P_bar_i .= P_bar_i
    firms.DM_i .= DM_i
    firms.P_CF_i .= P_CF_i

    # compute sales as minimum between supply and demand (internal and external)
    firms.Q_i .= min.(firms.Y_i .+ firms.S_i, firms.Q_d_i)
    rotw.Q_m = min.(rotw.Y_m, Q_d_m)

    # update households capital stock with investments
    w_act.K_h .+= w_act.I_h
    w_inact.K_h .+= w_inact.I_h
    firms.K_h .+= firms.I_h
    bank.K_h += bank.I_h
end

function initialize_variables_retail_market(firms, rotw, prop, agg, w_act, w_inact, gov, bank, multi_threading)
    # ... Initialize all the variables ...

    # change some variables according to arguments of matlab function
    b_HH_g = agg.P_bar_g .* prop.b_HH_g / sum(agg.P_bar_g .* prop.b_HH_g)    #prop.b_HH_g
    b_CFH_g = agg.P_bar_g .* prop.b_CFH_g / sum(agg.P_bar_g .* prop.b_CFH_g) #prop.b_CFH_g
    c_G_g = agg.P_bar_g .* prop.c_G_g / sum(agg.P_bar_g .* prop.c_G_g)       #prop.c_G_g
    c_E_g = agg.P_bar_g .* prop.c_E_g / sum(agg.P_bar_g .* prop.c_E_g)       #prop.c_E_g

    G = size(agg.P_bar_g, 1)

    # retrieve some general lengths from existing arrays
    I = size(firms.P_i, 1)        # number of firms
    H_W = length(w_act)           # number of active households
    H_inact = length(w_inact)     # number of inactive households
    H = H_W + H_inact + I + 1     # number of households
    L = size(rotw.C_d_l, 1)       # number of export partners
    J = size(gov.C_d_j, 1)        # number of government entities

    # define a global C_d_h and I_d_h
    C_d_h = [w_act.C_d_h; w_inact.C_d_h; firms.C_d_h; bank.C_d_h]
    I_d_h = [w_act.I_d_h; w_inact.I_d_h; firms.I_d_h; bank.I_d_h]

    # initialise some vectors of variables to zeros
    Q_d_i_g = zeros(typeFloat, size(firms.Y_i)..., G)
    Q_d_m_g = zeros(typeFloat, size(rotw.Y_m)..., G)

    C_h_t = zeros(typeFloat, H, multi_threading ? Threads.nthreads() : 1)
    I_h_t = zeros(typeFloat, H, multi_threading ? Threads.nthreads() : 1)

    C_j_g = zeros(typeFloat, 1, G)
    C_l_g = zeros(typeFloat, 1, G)

    P_bar_h_g = zeros(typeFloat, 1, G)
    P_bar_CF_h_g = zeros(typeFloat, 1, G)

    P_j_g = zeros(typeFloat, 1, G)
    P_l_g = zeros(typeFloat, 1, G)

    return I, H, L, J, C_d_h, I_d_h, b_HH_g, b_CFH_g, c_E_g, c_G_g, Q_d_i_g,
        Q_d_m_g, C_h_t, I_h_t, C_j_g, C_l_g, P_bar_h_g, P_bar_CF_h_g, P_j_g,
        P_l_g
end

function initialize_variables_firms_market(firms, rotw, prop)
    # ... Initialize all the variables ...

    # copy product variables for convenience
    a_sg = prop.a_sg
    b_CF_g = prop.b_CF_g

    G = length(prop.b_HH_g) # number of goods
    I = length(firms)                # number of firms

    # join internal and foreign firms arrays
    P_f = [firms.P_i; rotw.P_m]                     # price array (firms + foreign firms)) 
    S_f = [firms.Y_i + firms.S_i; rotw.Y_m]         # size array (firms + foreign firms)
    S_i_ = firms.K_i .* firms.kappa_i .- firms.Y_i  # (from matlab inputs)
    S_f_ = [S_i_; ones(size(rotw.Y_m)) .* Inf]      # Join S_i_ with an array of Infs of size(Y_m)
    G_f = [firms.G_i; collect(1:G)]                 # enlarge vector of final goods with foreign firms

    I_i_g = zeros(typeFloat, I, G)         # output
    P_CF_i_g = zeros(typeFloat, I, G)
    DM_i_g = zeros(typeFloat, I, G)
    P_bar_i_g = zeros(typeFloat, I, G)

    return a_sg, b_CF_g, P_f, S_f, S_f_, G_f, I_i_g, DM_i_g, P_bar_i_g, P_CF_i_g
end

"""
Perform the firms market exchange process
"""
function perform_firms_market!(
    g, firms, a_sg, b_CF_g, P_f, S_f, S_f_, I_i_g, DM_i_g, P_bar_i_g, P_CF_i_g,
    F_g, S_fg, S_fg_, G_f,
)
    ##############################
    ######## FIRMS MARKET ########
    ##############################
    
    DM_d_ig = @view(a_sg[g, realpart.(firms.G_i)]) .* firms.DM_d_i + b_CF_g[g] .* firms.I_d_i
    DM_nominal_ig = zeros(typeFloat, size(DM_d_ig))

    # firms that have demand for good "g" participate as buyers
    I_g = findall(x -> x > 0.0, DM_d_ig)

    # keep firms that have positive stock of good "g"
    filter!(i -> S_fg[i] > 0.0, F_g)

    # continue exchanges until either demand or supply terminates

    # weights according to size and price
    F_g_active = create_weighted_sampler(P_f, S_f, F_g)

    while !isempty(I_g) && !isempty(F_g_active)

        # select buyers at random
        shuffle!(I_g)
        for i in I_g
            # select a random firm according to the probabilities
            e = rand(F_g_active)
            f = F_g[e]

            # selected firm has sufficient stock
            if S_fg[f] > DM_d_ig[i]
                S_fg[f] -= DM_d_ig[i]
                DM_nominal_ig[i] += DM_d_ig[i] * P_f[f]
                DM_d_ig[i] = 0.0
            else
                DM_d_ig[i] -= S_fg[f]
                DM_nominal_ig[i] += S_fg[f] * P_f[f]
                S_fg[f] = 0.0
                delete!(F_g_active, e)
                isempty(F_g_active) && break
            end
        end
        filter!(i -> DM_d_ig[i] > 0.0, I_g)
    end

    if !isempty(I_g)
        DM_d_ig_ = copy(DM_d_ig)
        F_g_ = findall(x -> x == g, G_f)
        filter!(i -> S_fg_[i] > 0.0 && S_f[i] > 0.0, F_g_)

        # weights according to size and price
        F_g_active = create_weighted_sampler(P_f, S_f, F_g_)

        while !isempty(I_g) && !isempty(F_g_active)

            shuffle!(I_g)
            for i in I_g
                e = rand(F_g_active)
                f = F_g_[e]

                if S_fg_[f] > DM_d_ig_[i]
                    S_fg[f] -= DM_d_ig_[i]
                    S_fg_[f] -= DM_d_ig_[i]
                    DM_d_ig_[i] = 0.0
                else
                    DM_d_ig_[i] -= S_fg_[f]
                    S_fg[f] -= S_fg_[f]
                    S_fg_[f] = 0.0
                    delete!(F_g_active, e)
                    isempty(F_g_active) && break
                end
            end
            filter!(i -> DM_d_ig_[i] > 0.0, I_g)
        end
    end

    s = @view(a_sg[g, realpart.(firms.G_i)])
    a = @~ s .* firms.DM_d_i .- pos.(DM_d_ig .- b_CF_g[g] .* firms.I_d_i)
    b = @~ pos.(b_CF_g[g] .* firms.I_d_i .- DM_d_ig)
    c = @~ s .* firms.DM_d_i .+ b_CF_g[g] .* firms.I_d_i .- DM_d_ig

    @~ DM_i_g[:, g] .= a
    @~ I_i_g[:, g] .= b

    @~ P_bar_i_g[:, g] .= pos.(DM_nominal_ig .* a ./ c)
    @~ P_CF_i_g[:, g] .= pos.(DM_nominal_ig .* b ./ c)
end

"""
Perform the retail market exchange process
"""
function perform_retail_market!(
    i, g, agg, gov, rotw, I, H, L, J, C_d_h, I_d_h, b_HH_g, b_CFH_g,
    c_E_g, c_G_g, Q_d_i_g, Q_d_m_g, C_h_t, I_h_t, C_j_g, C_l_g, P_bar_h_g,
    P_bar_CF_h_g, P_j_g, P_l_g, S_fg, S_fg_, F_g, P_f, S_f, G_f,
)
    ###############################
    ######## RETAIL MARKET ########
    ###############################

    C_d_hg = [
        b_HH_g[g] .* C_d_h .+ b_CFH_g[g] .* I_d_h
        c_E_g[g] .* rotw.C_d_l
        c_G_g[g] .* gov.C_d_j
    ]
    C_real_hg = zeros(typeFloat, size(C_d_hg))
    H_g = findall(x -> x > 0.0, C_d_hg)

    filter!(i -> S_fg[i] > 0.0, F_g)

    # weights according to size and price
    F_g_active = create_weighted_sampler(P_f, S_f, F_g)

    while !isempty(H_g) && !isempty(F_g_active)

        shuffle!(H_g)
        for h in H_g
            e = rand(F_g_active)
            f = F_g[e]

            if S_fg[f] > C_d_hg[h] / P_f[f]
                S_fg[f] -= C_d_hg[h] / P_f[f]
                C_real_hg[h] += C_d_hg[h] / P_f[f]
                C_d_hg[h] = 0.0
            else
                C_d_hg[h] -= S_fg[f] * P_f[f]
                C_real_hg[h] += S_fg[f]
                S_fg[f] = 0.0
                delete!(F_g_active, e)
                isempty(F_g_active) && break
            end
        end
        filter!(h -> C_d_hg[h] > 0.0, H_g)
    end

    if !isempty(H_g)
        C_d_hg_ = copy(C_d_hg)
        F_g_ = findall(x -> x == g, G_f)
        filter!(i -> S_fg_[i] > 0.0 && S_f[i] > 0.0, F_g_)

        # weights according to size and price
        F_g_active = create_weighted_sampler(P_f, S_f, F_g_)

        while !isempty(H_g) && !isempty(F_g_active)

            shuffle!(H_g)
            for h in H_g
                e = rand(F_g_active)
                f = F_g_[e]

                if S_fg_[f] > C_d_hg_[h] / P_f[f]
                    S_fg[f] -= C_d_hg_[h] / P_f[f]
                    S_fg_[f] -= C_d_hg_[h] / P_f[f]
                    C_d_hg_[h] = 0.0
                else
                    C_d_hg_[h] -= S_fg_[f] * P_f[f]
                    S_fg[f] -= S_fg_[f]
                    S_fg_[f] = 0.0
                    delete!(F_g_active, e)
                    isempty(F_g_active) && break
                end
            end
            filter!(h -> C_d_hg_[h] > 0.0, H_g)
        end
    end

    a = @view(C_real_hg[1:H])
    b = @~ C_d_h .* b_HH_g[g] .- pos.(@view(C_d_hg[1:H]) .- b_CFH_g[g] .* I_d_h)
    c = @~ C_d_h .* b_HH_g[g] .+ b_CFH_g[g] .* I_d_h .- @view(C_d_hg[1:H])
    d = @~ pos.(b_CFH_g[g] .* I_d_h .- @view(C_d_hg[1:H]))

    @~ Q_d_i_g[:, g] .= @view(S_f[1:I]) .- @view(S_fg[1:I])
    @~ Q_d_m_g[:, g] .= @view(S_f[(I + 1):end]) .- @view(S_fg[(I + 1):end])

    @~ C_h_t[:, i] .+= b
    @~ I_h_t[:, i] .+= d

    C_j_g[g] = sum(@~ c_G_g[g] .* gov.C_d_j) - sum(@view(C_d_hg[(H + L + 1):(H + L + J)]))
    C_l_g[g] = sum(@~ c_E_g[g] .* rotw.C_d_l) - sum(@view(C_d_hg[(H + 1):(H + L)]))

    P_bar_h_g[g] = pos(sum(a) * sum(b) / sum(c))
    P_bar_CF_h_g[g] = pos(sum(a) * sum(d) / sum(c))

    P_j_g[g] = sum(@view(C_real_hg[(H + L + 1):(H + L + J)]))
    P_l_g[g] = sum(@view(C_real_hg[(H + 1):(H + L)]))
end

function compute_price_size_weights(P_f, S_f, F_g)
    # price probability of being selected
    pr_price_f_v = @~ exp.(-2 .* @view(P_f[F_g]))
    pr_price_f_sum = sum(pr_price_f_v)
    pr_price_f = @~ pos.(pr_price_f_v ./ pr_price_f_sum)
    # size probability of being selected
    pr_size_f_v = @view(S_f[F_g])
    pr_size_f_sum = sum(pr_size_f_v)
    pr_size_f = @~ pr_size_f_v ./ pr_size_f_sum
    # total weight of being selected
    w_cum_f_ = @~ pr_price_f .+ pr_size_f
    return w_cum_f_
end

function create_weighted_sampler(P_f, S_f, F_g)
    sampler = DynamicSampler()
    isempty(F_g) && return sampler
    w_cum_f_ = compute_price_size_weights(P_f, S_f, F_g)
    append!(sampler, 1:length(F_g), realpart.(w_cum_f_))
    return sampler
end
