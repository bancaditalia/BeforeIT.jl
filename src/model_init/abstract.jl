export AbstractBank, AbstractCentralBank, AbstractFirms, AbstractGovernment, AbstractRestOfTheWorld, AbstractRestOfTheWorld, AbstractWorkers, @worker, @firm, @bank, @centralBank, @aggregates, @restOfTheWorld

abstract type AbstractWorkers end
abstract type AbstractFirms end
abstract type AbstractBank end
abstract type AbstractCentralBank end
abstract type AbstractGovernment end
abstract type AbstractRestOfTheWorld end

macro worker(T= Float64, I = Vector{Float64})
    return esc(quote
        Y_h::$T
        D_h::$T
        K_h::$T
        w_h::$T
        O_h::$I
        C_d_h::$T
        I_d_h::$T
        C_h::$T
        I_h::$T
    end)
end

macro firm(T = Float64, I = Vector{Float64})
    return esc(quote
                  G_i::$I
    alpha_bar_i::$T
    beta_i::$T
    kappa_i::$T
    w_i::$T
    w_bar_i::$T
    delta_i::$T
    tau_Y_i::$T
    tau_K_i::$T
    N_i::$I
    Y_i::$T
    Q_i::$T
    Q_d_i::$T
    P_i::$T
    S_i::$T
    K_i::$T
    M_i::$T
    L_i::$T
    pi_bar_i::$T
    D_i::$T
    Pi_i::$T
    V_i::$I
    I_i::$T
    E_i::$T
    P_bar_i::$T
    P_CF_i::$T
    DS_i::$T
    DM_i::$T
    DL_i::$T
    DL_d_i::$T
    K_e_i::$T
    L_e_i::$T
    Q_s_i::$T
    I_d_i::$T
    DM_d_i::$T
    N_d_i::$I
    Pi_e_i::$T
    ### Household fields (firms' owners)
    Y_h::$T
    C_d_h::$T
    I_d_h::$T
    C_h::$T
    I_h::$T
    K_h::$T
    D_h::$T
end)
end

macro bank(T = Float64)
    return esc(quote
    E_k::$T
    Pi_k::$T
    Pi_e_k::$T
    D_k::$T
    r::$T
    Y_h::$T
    C_d_h::$T
    I_d_h::$T
    C_h::$T
    I_h::$T
    K_h::$T
    D_h::$T
        end)
end

macro centralBank(T = Float64)
    return esc(quote
    r_bar::$T
    r_G::$T
    rho::$T
    r_star::$T
    pi_star::$T
    xi_pi::$T
    xi_gamma::$T
    E_CB::$T
        end)
end

macro government(T=Float64)
    return esc(quote
    alpha_G::$T
    beta_G::$T
    sigma_G::$T
    Y_G::$T
    C_G::$T
    L_G::$T
    sb_inact::$T
    sb_other::$T
    C_d_j::Vector{$T}
    C_j::$T
    P_j::$T
            end)
end

macro restOfTheWorld(T = Float64)
    return esc(quote
    alpha_E::$T
    beta_E::$T
    sigma_E::$T
    alpha_I::$T
    beta_I::$T
    sigma_I::$T
    Y_EA::$T
    gamma_EA::$T
    pi_EA::$T
    alpha_pi_EA::$T
    beta_pi_EA::$T
    sigma_pi_EA::$T
    alpha_Y_EA::$T
    beta_Y_EA::$T
    sigma_Y_EA::$T
    D_RoW::$T
    Y_I::$T
    C_E::$T
    C_d_l::Vector{$T}
    C_l::$T
    Y_m::Vector{$T}
    Q_m::Vector{$T}
    Q_d_m::Vector{$T}
    P_m::Vector{$T}
    P_l::$T
            end)
end

macro aggregates(T = Float64, I = Vector{Float64})
    return esc(quote
    Y::Vector{$T}
    pi_::Vector{$T}
    P_bar::$T
    P_bar_g::Vector{$T}
    P_bar_HH::$T
    P_bar_CF::$T
    P_bar_h::$T
    P_bar_CF_h::$T
    Y_e::$T
    gamma_e::$T
    pi_e::$T
    epsilon_Y_EA::$T
    epsilon_E::$T
    epsilon_I::$T
    t::$I
            end)
end    
