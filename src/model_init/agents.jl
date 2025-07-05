
include("object_macro.jl")

abstract type AbstractWorkers <: AbstractObject end
abstract type AbstractFirms <: AbstractObject end
abstract type AbstractBank <: AbstractObject end
abstract type AbstractCentralBank <: AbstractObject end
abstract type AbstractGovernment <: AbstractObject end
abstract type AbstractRestOfTheWorld <: AbstractObject end
abstract type AbstractAggregates <: AbstractObject end
abstract type AbstractModel <: AbstractObject end

"""
This is a Workers. Each field is an array which stores the values for all the workers in
the economy. Note that the `O_h` field is an integer, while the rest are floats.

For all fields the entry at index `i` corresponds to the `i`th worker.

# Fields
- `Y_h`: Net disposable income of worker owner (investor)
- `D_h`: Deposits
- `K_h`: Capital stock
- `w_h`: Wages (0 if inactive or unemployed)
- `O_h`: Occupation (0 if unemployed, -1 if inactive)
- `C_d_h`: Consumption budget
- `I_d_h`: Investment budget
- `C_h`: Realised consumption
- `I_h`: Realised investment
"""
Bit.@object struct Workers(Object) <: AbstractWorkers
    Y_h::Vector{typeFloat}
    D_h::Vector{typeFloat}
    K_h::Vector{typeFloat}
    w_h::Vector{typeFloat}
    O_h::Vector{typeInt}
    C_d_h::Vector{typeFloat}
    I_d_h::Vector{typeFloat}
    C_h::Vector{typeFloat}
    I_h::Vector{typeFloat}
end

"""
This is a Firms type. Each field is an array which stores the values for all the firms in
the economy. Note that the `G_i`, `N_i` and `V_i` fields are integers, while the rest are floats.

For all fields the entry at index `i` corresponds to the `i`th firm.

# Fields
- `G_i`: Principal product
- `alpha_bar_i`: Average productivity of labor
- `beta_i`: Productivity of intermediate consumption
- `kappa_i`: Productivity of capital
- `w_i`: Wages
- `w_bar_i`: Average wage rate
- `delta_i`: Depreciation rate for capital
- `tau_Y_i`: Net tax rate on products
- `tau_K_i`: Net tax rate on production
- `N_i`: Number of persons employed
- `Y_i`: Production of goods
- `Q_i`: Sales of goods
- `Q_d_i`: Demand for goods
- `P_i`: Price
- `S_i`: Inventories
- `K_i`: Capital, in real terms
- `M_i`: Intermediate goods/services and raw materials, in real terms
- `L_i`: Outstanding loans
- `pi_bar_i`: Operating margin
- `D_i`: Deposits of the firm
- `Pi_i`: Profits
- `V_i`: Vacancies
- `I_i`: Investments
- `E_i`: Equity
- `P_bar_i`: Price index
- `P_CF_i`: Price index
- `DS_i`: Differnece in stock of final goods
- `DM_i`: Difference in stock of intermediate goods
- `DL_i`: Obtained loans
- `DL_d_i`: Target loans
- `K_e_i`: Expected capital 
- `L_e_i`: Expected loans
- `Q_s_i`: Expected sales
- `I_d_i`: Desired investments
- `DM_d_i`: Desired materials
- `N_d_i`: Desired employment
- `Pi_e_i`: Expected profits
### Household fields (firms' owners)
- `Y_h`: Net disposable income of firm owner (investor)
- `C_d_h`: Consumption budget
- `I_d_h`: Investment budget
- `C_h`: Realised consumption
- `I_h`: Realised investment
- `K_h`: Capital stock
- `D_h`: Deposits of the owner of the firms
"""
Bit.@object struct Firms(Object) <: AbstractFirms
    G_i::Vector{typeInt}
    alpha_bar_i::Vector{typeFloat}
    beta_i::Vector{typeFloat}
    kappa_i::Vector{typeFloat}
    w_i::Vector{typeFloat}
    w_bar_i::Vector{typeFloat}
    delta_i::Vector{typeFloat}
    tau_Y_i::Vector{typeFloat}
    tau_K_i::Vector{typeFloat}
    N_i::Vector{typeInt}
    Y_i::Vector{typeFloat}
    Q_i::Vector{typeFloat}
    Q_d_i::Vector{typeFloat}
    P_i::Vector{typeFloat}
    S_i::Vector{typeFloat}
    K_i::Vector{typeFloat}
    M_i::Vector{typeFloat}
    L_i::Vector{typeFloat}
    pi_bar_i::Vector{typeFloat}
    D_i::Vector{typeFloat}
    Pi_i::Vector{typeFloat}
    V_i::Vector{typeInt}
    I_i::Vector{typeFloat}
    E_i::Vector{typeFloat}
    P_bar_i::Vector{typeFloat}
    P_CF_i::Vector{typeFloat}
    DS_i::Vector{typeFloat}
    DM_i::Vector{typeFloat}
    DL_i::Vector{typeFloat}
    DL_d_i::Vector{typeFloat}
    K_e_i::Vector{typeFloat}
    L_e_i::Vector{typeFloat}
    Q_s_i::Vector{typeFloat}
    I_d_i::Vector{typeFloat}
    DM_d_i::Vector{typeFloat}
    N_d_i::Vector{typeInt}
    Pi_e_i::Vector{typeFloat}
    ### Household fields (firms' owners)
    Y_h::Vector{typeFloat}
    C_d_h::Vector{typeFloat}
    I_d_h::Vector{typeFloat}
    C_h::Vector{typeFloat}
    I_h::Vector{typeFloat}
    K_h::Vector{typeFloat}
    D_h::Vector{typeFloat}
end

"""
This is a Bank type. It represents the bank of the model.

# Fields
- `E_k`: equity capital (common equity) of the bank
- `Pi_k`: Profits of the bank
- `Pi_e_k`: Expected profits of the bank
- `D_k`: Residual and balancing item on the bank’s balance sheet
- `r`: Rate for loans and morgages
### Household fields (bank' owner)
- `Y_h`: Net disposable income of bank owner (investor)
- `C_d_h`: Consumption budget
- `I_d_h`: Investment budget
- `C_h`: Realised consumption
- `I_h`: Realised investment
- `K_h`: Capital stock
- `D_h`: Deposits
"""
Bit.@object mutable struct Bank(Object) <: AbstractBank
    E_k::typeFloat
    Pi_k::typeFloat
    Pi_e_k::typeFloat
    D_k::typeFloat
    r::typeFloat
    Y_h::typeFloat
    C_d_h::typeFloat
    I_d_h::typeFloat
    C_h::typeFloat
    I_h::typeFloat
    K_h::typeFloat
    D_h::typeFloat
end

"""
This is a CentralBank type. It represents the central bank of the model.

# Fields
- `r_bar`: Nominal interest rate
- `r_G`: Interest rate on government bonds
- `rho`: Parameter for gradual adjustment of the policy rate
- `r_star`: Real equilibrium interest rate
- `pi_star`: Inflation target by CB
- `xi_pi`: Weight the CB puts on inflation targeting
- `xi_gamma`: Weight placed on economic
- `E_CB`: Central bank equity
"""
Bit.@object mutable struct CentralBank(Object) <: AbstractCentralBank
    r_bar::typeFloat
    r_G::typeFloat
    rho::typeFloat
    r_star::typeFloat
    pi_star::typeFloat
    xi_pi::typeFloat
    xi_gamma::typeFloat
    E_CB::typeFloat
end

"""
This is a Government type. It represents the government of the model.

# Fields
- `alpha_G`: Autoregressive coefficient for government consumption
- `beta_G`: Scalar constant for government consumption
- `sigma_G`: Variance coefficient for government consumption
- `Y_G`: Government revenues
- `C_G`: Consumption demand of the general government
- `L_G`: Loans taken out by the government
- `sb_inact`: Social benefits for inactive persons
- `sb_other`: Social benefits for all
- `C_d_j [vector]`: Local governments consumption demand
- `C_j`: Realised government consumption
- `P_j`: Price inflation of government goods <- ??
"""
Bit.@object mutable struct Government(Object) <: AbstractGovernment
    alpha_G::typeFloat
    beta_G::typeFloat
    sigma_G::typeFloat
    Y_G::typeFloat
    C_G::typeFloat
    L_G::typeFloat
    sb_inact::typeFloat
    sb_other::typeFloat
    C_d_j::Vector{typeFloat}
    C_j::typeFloat
    P_j::typeFloat
end

"""
This is a RestOfTheWorld type. It represents the rest of the world of the model.

# Fields
- `alpha_E`: Autoregressive coefficient for exports
- `beta_E`: Scalar constant for exports
- `sigma_E`: Variance coefficient for exports
- `alpha_I`: Autoregressive coefficient for imports
- `beta_I`: Scalar constant for imports
- `sigma_I`: Variance coefficient for imports
- `Y_EA`: GDP euro area
- `gamma_EA`: Growth euro area
- `pi_EA`: Inflation euro area
- `alpha_pi_EA`: Autoregressive coefficient for euro area inflation
- `beta_pi_EA`: Autoregressive coefficient for euro area inflation Scalar constant for euro area inflation
- `sigma_pi_EA`: Variance coefficient for euro area inflation
- `alpha_Y_EA`: Autoregressive coefficient for euro area GDP
- `beta_Y_EA`: Autoregressive coefficient for euro area GDP Scalar constant for euro area GDP
- `sigma_Y_EA`: Variance coefficient for euro area GDP
- `D_RoW`: Net creditor/debtor position of the national economy to the rest of the world
- `Y_I`: Supply of imports (in real terms)
- `C_E`: Total demand for exports
- `C_d_l [vector]`: Demand for exports of specific product
- `C_l`: Realised consumption by foreign consumers
- `Y_m [vector]`: Supply of imports per sector
- `Q_m [vector]`: Sales for imports per sector
- `Q_d_m [vector]`: Demand for goods
- `P_m [vector]`: Price of imports per sector
- `P_l`: Price inflation of exports <- ??
"""
Bit.@object mutable struct RestOfTheWorld(Object) <: AbstractRestOfTheWorld
    alpha_E::typeFloat
    beta_E::typeFloat
    sigma_E::typeFloat
    alpha_I::typeFloat
    beta_I::typeFloat
    sigma_I::typeFloat
    Y_EA::typeFloat
    gamma_EA::typeFloat
    pi_EA::typeFloat
    alpha_pi_EA::typeFloat
    beta_pi_EA::typeFloat
    sigma_pi_EA::typeFloat
    alpha_Y_EA::typeFloat
    beta_Y_EA::typeFloat
    sigma_Y_EA::typeFloat
    D_RoW::typeFloat
    Y_I::typeFloat
    C_E::typeFloat
    C_d_l::Vector{typeFloat}
    C_l::typeFloat
    Y_m::Vector{typeFloat}
    Q_m::Vector{typeFloat}
    Q_d_m::Vector{typeFloat}
    P_m::Vector{typeFloat}
    P_l::typeFloat
end

"""
This is a Aggregates type. It is used to store the aggregate variables of the economy.
Note that `t` is an integer, while the rest are floats or vectors of floats.

# Fields
- `Y [vector]`: GDP data + predictions
- `pi_ [vector]`: inflation data + predictions
- `P_bar`: Global price index
- `P_bar_g [vector]`: Producer price index for principal good g
- `P_bar_HH`: Consumer price index
- `P_bar_CF`: Capital price index
- `P_bar_h`: CPI_h
- `P_bar_CF_h`: Capital price index _h
- `Y_e`: Expected GDP
- `gamma_e`: Expected growth
- `pi_e`: Expected inflation
- `t`: Time index
"""
Bit.@object mutable struct Aggregates(Object) <: AbstractAggregates
    Y::Vector{typeFloat}
    pi_::Vector{typeFloat}
    P_bar::typeFloat
    P_bar_g::Vector{typeFloat}
    P_bar_HH::typeFloat
    P_bar_CF::typeFloat
    P_bar_h::typeFloat
    P_bar_CF_h::typeFloat
    Y_e::typeFloat
    gamma_e::typeFloat
    pi_e::typeFloat
    epsilon_Y_EA::typeFloat
    epsilon_E::typeFloat
    epsilon_I::typeFloat
    t::typeInt
end

"""
This is a Model type. It is used to store all the agents of the economy.

# Fields
- `w_act`: Workers that are active
- `w_inact`: Workers that are inactive
- `firms`: Firms
- `bank`: Bank
- `cb`: CentralBank
- `gov`: Government
- `rotw`: RestOfTheWorld
- `agg`: Aggregates
"""
mutable struct Model{W1<:AbstractWorkers,W2<:AbstractWorkers,
                     F<:AbstractFirms,B<:AbstractBank,
                     C<:AbstractCentralBank,G<:AbstractGovernment,
                     R<:AbstractRestOfTheWorld,A<:AbstractAggregates,
                     P,D} <: AbstractModel
    w_act::W1
    w_inact::W2
    firms::F
    bank::B
    cb::C
    gov::G
    rotw::R
    agg::A
    prop::P
    data::D
    function Model(w_act::W1, w_inact::W2, firms::F, bank::B, cb::C, gov::G, rotw::R, 
        agg::A, prop::P, data::D) where {
            W1<:AbstractWorkers, W2<:AbstractWorkers, F<:AbstractFirms, B<:AbstractBank,
            C<:AbstractCentralBank, G<:AbstractGovernment, R<:AbstractRestOfTheWorld, A<:Aggregates,
            P, D
        }
        model = new{W1,W2,F,B,C,G,R,A,P,D}(w_act, w_inact, firms, bank, cb, gov, rotw, agg, prop, data)
        
        # add workers to firms
        V_i, w_bar_i = firms.V_i, firms.w_bar_i
        O_h, w_h, Y_h = w_act.O_h, w_act.w_h, w_act.Y_h
        sb_other, tau_SIW, tau_INC, theta_UB = prop.sb_other, prop.tau_SIW, prop.tau_INC, prop.theta_UB
        h = 1
        for i in 1:prop.I
            while V_i[i] > 0
                O_h[h] = i
                w_h[h] = w_bar_i[i]
                V_i[i] -= 1
                h += 1
            end
        end

        P_bar_HH = 1.0
        H_W = prop.H_act - prop.I - 1
        for h in 1:H_W
            if O_h[h] != 0
                Y_h[h] = (w_h[h] * (1 - tau_SIW - tau_INC * (1 - tau_SIW)) + sb_other) * P_bar_HH
            else
                Y_h[h] = (theta_UB * w_h[h] + sb_other) * P_bar_HH
            end
        end

        w_act.D_h .= prop.D_H * Y_h #/ sum(Y_h)
        w_act.K_h .= prop.K_H * Y_h #/ sum(Y_h)

        # bank initialization which depends on firms
        bank.Pi_k = prop.mu * sum(firms.L_i) + prop.r_bar * prop.E_k
        bank.D_k = sum(firms.D_i) + prop.E_k - sum(firms.L_i)
        bank.Y_h = prop.theta_DIV * (1 - tau_INC) * (1 - prop.tau_FIRM) * max(0, bank.Pi_k) + sb_other * P_bar_HH
        bank.D_h = prop.D_H * bank.Y_h # Need to normalise wrt sum(Y_h) at the end of initialisation
        bank.K_h = prop.K_H * bank.Y_h # Need to normalise wrt sum(Y_h) at the end of initialisation

        # update model variables with global quantities (total income, total deposits) obtained from all the agents
        update_variables_with_totals!(model)

        # initialize data collection
        update_data_init!(model)

        return model
    end
end

# helper functions
length(f::AbstractFirms) = length(f.G_i)
length(w::AbstractWorkers) = length(w.Y_h)
