include("object_macro.jl")

abstract type AbstractWorkers <: AbstractObject end
abstract type AbstractFirms <: AbstractObject end
abstract type AbstractBanks <: AbstractObject end
abstract type AbstractCentralBank <: AbstractObject end
abstract type AbstractGovernment <: AbstractObject end
abstract type AbstractRestOfTheWorld <: AbstractObject end
abstract type AbstractAggregates <: AbstractObject end
abstract type AbstractModel <: AbstractObject end

include("../utils/modify.jl")

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
- `B_h`: Bank assignment
"""
Bit.@object mutable struct Workers(Object) <: AbstractWorkers
    const del::Base.RefValue{Bool}
    const lastid::Base.RefValue{Int}
    const id_to_index::Dict{Int, Int}
    const ID::Vector{Int}
    const Y_h::Vector{Bit.typeFloat}
    const D_h::Vector{Bit.typeFloat}
    const K_h::Vector{Bit.typeFloat}
    const w_h::Vector{Bit.typeFloat}
    const O_h::Vector{Bit.typeInt}
    const C_d_h::Vector{Bit.typeFloat}
    const I_d_h::Vector{Bit.typeFloat}
    const C_h::Vector{Bit.typeFloat}
    const I_h::Vector{Bit.typeFloat}
    const B_h::Vector{Bit.typeInt}
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
Bit.@object mutable struct Firms(Object) <: AbstractFirms
    const del::Base.RefValue{Bool}
    const lastid::Base.RefValue{Int}
    const id_to_index::Dict{Int, Int}
    const ID::Vector{Int}
    const G_i::Vector{Bit.typeInt}
    const alpha_bar_i::Vector{Bit.typeFloat}
    const beta_i::Vector{Bit.typeFloat}
    const kappa_i::Vector{Bit.typeFloat}
    const w_i::Vector{Bit.typeFloat}
    const w_bar_i::Vector{Bit.typeFloat}
    const delta_i::Vector{Bit.typeFloat}
    const tau_Y_i::Vector{Bit.typeFloat}
    const tau_K_i::Vector{Bit.typeFloat}
    const N_i::Vector{Bit.typeInt}
    const Y_i::Vector{Bit.typeFloat}
    const Q_i::Vector{Bit.typeFloat}
    const Q_d_i::Vector{Bit.typeFloat}
    const P_i::Vector{Bit.typeFloat}
    const S_i::Vector{Bit.typeFloat}
    const K_i::Vector{Bit.typeFloat}
    const M_i::Vector{Bit.typeFloat}
    const L_i::Vector{Bit.typeFloat}
    const pi_bar_i::Vector{Bit.typeFloat}
    const D_i::Vector{Bit.typeFloat}
    const Pi_i::Vector{Bit.typeFloat}
    const V_i::Vector{Bit.typeInt}
    const I_i::Vector{Bit.typeFloat}
    const E_i::Vector{Bit.typeFloat}
    const P_bar_i::Vector{Bit.typeFloat}
    const P_CF_i::Vector{Bit.typeFloat}
    const DS_i::Vector{Bit.typeFloat}
    const DM_i::Vector{Bit.typeFloat}
    const DL_i::Vector{Bit.typeFloat}
    const DL_d_i::Vector{Bit.typeFloat}
    const K_e_i::Vector{Bit.typeFloat}
    const L_e_i::Vector{Bit.typeFloat}
    const Q_s_i::Vector{Bit.typeFloat}
    const I_d_i::Vector{Bit.typeFloat}
    const DM_d_i::Vector{Bit.typeFloat}
    const N_d_i::Vector{Bit.typeInt}
    const Pi_e_i::Vector{Bit.typeFloat}
    const B_i::Vector{Bit.typeInt}
    ### Household fields (firms' owners)
    const Y_h::Vector{Bit.typeFloat}
    const C_d_h::Vector{Bit.typeFloat}
    const I_d_h::Vector{Bit.typeFloat}
    const C_h::Vector{Bit.typeFloat}
    const I_h::Vector{Bit.typeFloat}
    const K_h::Vector{Bit.typeFloat}
    const D_h::Vector{Bit.typeFloat}
end

"""
This is a Banks type. Each field is an array which stores the values for all the banks in
the economy.

For all fields the entry at index `i` corresponds to the `i`th firm.

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
Bit.@object mutable struct Banks(Object) <: AbstractBanks
    const del::Base.RefValue{Bool}
    const lastid::Base.RefValue{Int}
    const id_to_index::Dict{Int, Int}
    const ID::Vector{Int}
    const E_k::Vector{Bit.typeFloat}
    const Pi_k::Vector{Bit.typeFloat}
    const Pi_e_k::Vector{Bit.typeFloat}
    const D_k::Vector{Bit.typeFloat}
    const r::Vector{Bit.typeFloat}
    const Y_h::Vector{Bit.typeFloat}
    const C_d_h::Vector{Bit.typeFloat}
    const I_d_h::Vector{Bit.typeFloat}
    const C_h::Vector{Bit.typeFloat}
    const I_h::Vector{Bit.typeFloat}
    const K_h::Vector{Bit.typeFloat}
    const D_h::Vector{Bit.typeFloat}
    const firms::Vector{Vector{Agent{<:AbstractFirms}}}
    const w_act::Vector{Vector{Agent{<:AbstractWorkers}}}
    const w_inact::Vector{Vector{Agent{<:AbstractWorkers}}}
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
end

"""
This is a Model type. It is used to store all the agents of the economy.

# Fields
- `w_act`: Workers that are active
- `w_inact`: Workers that are inactive
- `firms`: Firms
- `banks`: Banks
- `cb`: CentralBank
- `gov`: Government
- `rotw`: RestOfTheWorld
- `agg`: Aggregates
"""
Bit.@object mutable struct Model{
        W1 <: Bit.AbstractWorkers, W2 <: Bit.AbstractWorkers,
        F <: Bit.AbstractFirms, B <: Bit.AbstractBanks,
        C <: Bit.AbstractCentralBank, G <: Bit.AbstractGovernment,
        R <: Bit.AbstractRestOfTheWorld, A <: Bit.AbstractAggregates,
        P, D,
    }(Object) <: Bit.AbstractModel
    w_act::W1
    w_inact::W2
    firms::F
    banks::B
    cb::C
    gov::G
    rotw::R
    agg::A
    prop::P
    data::D
end

function (::Type{T})(agents) where {T <: AbstractModel}

    w_act, w_inact, firms, banks, cb, gov, rotw, agg, prop, data = agents
    model = T(w_act, w_inact, firms, banks, cb, gov, rotw, agg, prop, data)

    # initialize bank assignments for firms and workers (sticky: random initial assignment)
    n_banks = length(banks)
    N_firms = length(firms)
    N_workers_act = length(w_act)
    N_workers_inact = length(w_inact)

    # For backward compatibility: n_banks=1 means all agents use bank 1
    if n_banks == 1
        firms.B_i .= 1
        w_act.B_h .= 1
        w_inact.B_h .= 1
    else
        firms.B_i .= rand(1:n_banks, N_firms)
        w_act.B_h .= rand(1:n_banks, N_workers_act)
        w_inact.B_h .= rand(1:n_banks, N_workers_inact)
    end

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
    H_W = length(w_act)
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
    for bank_id in eachbank(model)
        banks.firms[bank_id] = [firms[i] for i in eachfirm(model) if firms.B_i[i] == bank_id]
        banks.w_act[bank_id] = [w_act[i] for i in eachindex(model.w_act.D_h) if w_act.B_h[i] == bank_id]
        banks.w_inact[bank_id] = [w_inact[i] for i in eachindex(model.w_inact.D_h) if w_inact.B_h[i] == bank_id]

        L_base = sum(f.L_i for f in banks.firms[bank_id])
        D_base = sum(f.D_i for f in banks.firms[bank_id])
        # per-bank equity: prop.E_k is the sector aggregate, banks.E_k[bank_id] its share
        E_k_base = banks.E_k[bank_id]
        Pi_k_base = prop.mu * L_base + prop.r_bar * E_k_base
        D_k_base = D_base + E_k_base - L_base
        banks.Pi_k[bank_id] = Pi_k_base
        banks.D_k[bank_id] = D_k_base
        banks.Y_h[bank_id] = prop.theta_DIV * (1 - tau_INC) * (1 - prop.tau_FIRM) * max(0, banks.Pi_k[bank_id]) + sb_other * P_bar_HH
        banks.D_h[bank_id] = prop.D_H * banks.Y_h[bank_id] # Need to normalise wrt sum(Y_h) at the end of initialisation
        banks.K_h[bank_id] = prop.K_H * banks.Y_h[bank_id] # Need to normalise wrt sum(Y_h) at the end of initialisation
    end

    # update model variables with global quantities (total income, total deposits) obtained from all the agents
    update_variables_with_totals!(model)

    # initialize data collection
    collect_data!(model)

    return model
end

# helper functions
length(f::AbstractFirms) = length(f.G_i)
length(w::AbstractWorkers) = length(w.Y_h)
length(b::AbstractBanks) = length(b.E_k)

# multi-bank helper functions
eachbank(model::AbstractModel) = 1:model.prop.n_banks #eachindex(model.banks)
#getbank(model::AbstractModel, bank_id::Int) = model.banks[bank_id]
#nbanks(model::AbstractModel) = length(model.banks)
eachfirm(model::AbstractModel) = 1:model.prop.I
