
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
    Y_h::Vector{Bit.typeFloat}
    D_h::Vector{Bit.typeFloat}
    K_h::Vector{Bit.typeFloat}
    w_h::Vector{Bit.typeFloat}
    O_h::Vector{Bit.typeInt}
    C_d_h::Vector{Bit.typeFloat}
    I_d_h::Vector{Bit.typeFloat}
    C_h::Vector{Bit.typeFloat}
    I_h::Vector{Bit.typeFloat}
    function Workers(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
    G_i::Vector{Bit.typeInt}
    alpha_bar_i::Vector{Bit.typeFloat}
    beta_i::Vector{Bit.typeFloat}
    kappa_i::Vector{Bit.typeFloat}
    w_i::Vector{Bit.typeFloat}
    w_bar_i::Vector{Bit.typeFloat}
    delta_i::Vector{Bit.typeFloat}
    tau_Y_i::Vector{Bit.typeFloat}
    tau_K_i::Vector{Bit.typeFloat}
    N_i::Vector{Bit.typeInt}
    Y_i::Vector{Bit.typeFloat}
    Q_i::Vector{Bit.typeFloat}
    Q_d_i::Vector{Bit.typeFloat}
    P_i::Vector{Bit.typeFloat}
    S_i::Vector{Bit.typeFloat}
    K_i::Vector{Bit.typeFloat}
    M_i::Vector{Bit.typeFloat}
    L_i::Vector{Bit.typeFloat}
    pi_bar_i::Vector{Bit.typeFloat}
    D_i::Vector{Bit.typeFloat}
    Pi_i::Vector{Bit.typeFloat}
    V_i::Vector{Bit.typeInt}
    I_i::Vector{Bit.typeFloat}
    E_i::Vector{Bit.typeFloat}
    P_bar_i::Vector{Bit.typeFloat}
    P_CF_i::Vector{Bit.typeFloat}
    DS_i::Vector{Bit.typeFloat}
    DM_i::Vector{Bit.typeFloat}
    DL_i::Vector{Bit.typeFloat}
    DL_d_i::Vector{Bit.typeFloat}
    K_e_i::Vector{Bit.typeFloat}
    L_e_i::Vector{Bit.typeFloat}
    Q_s_i::Vector{Bit.typeFloat}
    I_d_i::Vector{Bit.typeFloat}
    DM_d_i::Vector{Bit.typeFloat}
    N_d_i::Vector{Bit.typeInt}
    Pi_e_i::Vector{Bit.typeFloat}
    ### Household fields (firms' owners)
    Y_h::Vector{Bit.typeFloat}
    C_d_h::Vector{Bit.typeFloat}
    I_d_h::Vector{Bit.typeFloat}
    C_h::Vector{Bit.typeFloat}
    I_h::Vector{Bit.typeFloat}
    K_h::Vector{Bit.typeFloat}
    D_h::Vector{Bit.typeFloat}
    function Firms(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
    E_k::Bit.typeFloat
    Pi_k::Bit.typeFloat
    Pi_e_k::Bit.typeFloat
    D_k::Bit.typeFloat
    r::Bit.typeFloat
    Y_h::Bit.typeFloat
    C_d_h::Bit.typeFloat
    I_d_h::Bit.typeFloat
    C_h::Bit.typeFloat
    I_h::Bit.typeFloat
    K_h::Bit.typeFloat
    D_h::Bit.typeFloat
    function Bank(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
    r_bar::Bit.typeFloat
    r_G::Bit.typeFloat
    rho::Bit.typeFloat
    r_star::Bit.typeFloat
    pi_star::Bit.typeFloat
    xi_pi::Bit.typeFloat
    xi_gamma::Bit.typeFloat
    E_CB::Bit.typeFloat
    function CentralBank(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
    alpha_G::Bit.typeFloat
    beta_G::Bit.typeFloat
    sigma_G::Bit.typeFloat
    Y_G::Bit.typeFloat
    C_G::Bit.typeFloat
    L_G::Bit.typeFloat
    sb_inact::Bit.typeFloat
    sb_other::Bit.typeFloat
    C_d_j::Vector{Bit.typeFloat}
    C_j::Bit.typeFloat
    P_j::Bit.typeFloat
    function Government(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
    alpha_E::Bit.typeFloat
    beta_E::Bit.typeFloat
    sigma_E::Bit.typeFloat
    alpha_I::Bit.typeFloat
    beta_I::Bit.typeFloat
    sigma_I::Bit.typeFloat
    Y_EA::Bit.typeFloat
    gamma_EA::Bit.typeFloat
    pi_EA::Bit.typeFloat
    alpha_pi_EA::Bit.typeFloat
    beta_pi_EA::Bit.typeFloat
    sigma_pi_EA::Bit.typeFloat
    alpha_Y_EA::Bit.typeFloat
    beta_Y_EA::Bit.typeFloat
    sigma_Y_EA::Bit.typeFloat
    D_RoW::Bit.typeFloat
    Y_I::Bit.typeFloat
    C_E::Bit.typeFloat
    C_d_l::Vector{Bit.typeFloat}
    C_l::Bit.typeFloat
    Y_m::Vector{Bit.typeFloat}
    Q_m::Vector{Bit.typeFloat}
    Q_d_m::Vector{Bit.typeFloat}
    P_m::Vector{Bit.typeFloat}
    P_l::Bit.typeFloat
    function RestOfTheWorld(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
    Y::Vector{Bit.typeFloat}
    pi_::Vector{Bit.typeFloat}
    P_bar::Bit.typeFloat
    P_bar_g::Vector{Bit.typeFloat}
    P_bar_HH::Bit.typeFloat
    P_bar_CF::Bit.typeFloat
    P_bar_h::Bit.typeFloat
    P_bar_CF_h::Bit.typeFloat
    Y_e::Bit.typeFloat
    gamma_e::Bit.typeFloat
    pi_e::Bit.typeFloat
    epsilon_Y_EA::Bit.typeFloat
    epsilon_E::Bit.typeFloat
    epsilon_I::Bit.typeFloat
    t::Bit.typeInt
    function Aggregates(args...)
        args = transform_for_differentiability!(args)
        new(args...)
    end
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
        for i in 1:realpart(prop.I)
            while V_i[i] > 0
                O_h[h] = i
                w_h[h] = w_bar_i[i]
                V_i[i] -= 1
                h += 1
            end
        end

        P_bar_HH = 1.0
        H_W = prop.H_act - prop.I - 1
        for h in 1:realpart(H_W)
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

function transform_for_differentiability!(args)
    t1 = Bit.typeFloat == Dual128 && Bit.typeInt == Dual{Int64}
    t2 = Bit.typeFloat != Dual128 && Bit.typeInt != Dual{Int64}
    if t1
        new_args = []
        for a in args
            new_a = a isa Vector ? a : a
            push!(new_args, new_a)
        end
        return new_args
    end
    t2 && return args
    error("Incorrect Float/Int Types")
end
