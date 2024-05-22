export Workers, Firms, Bank, CentralBank, Government, RestOfTheWorld, Aggregates, Model
include("abstract.jl")
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
struct Workers{T <: AbstractVector, I <: AbstractVector} <: AbstractWorkers
    @worker T I
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
mutable struct Firms{T <: AbstractVector, I <: AbstractVector} <: AbstractFirms
    @firm T I
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
mutable struct Bank{P} <: AbstractBank
    @bank P
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
mutable struct CentralBank{T} <: AbstractCentralBank

    @centralBank T
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
mutable struct Government{T} <: AbstractGovernment

    @government T
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
mutable struct RestOfTheWorld{T} <: AbstractRestOfTheWorld

    @restOfTheWorld T
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
mutable struct Aggregates{T, I}
    @Aggregates T I
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
mutable struct Model
    w_act::AbstractWorkers
    w_inact::AbstractWorkers
    firms::AbstractFirms
    bank::AbstractBank
    cb::AbstractCentralBank
    gov::AbstractGovernment
    rotw::RestOfTheWorld
    agg::Aggregates
    prop::Any
end


# helper functions
length(f::AbstractFirms) = length(f.G_i)
length(w::AbstractWorkers) = length(w.Y_h)
