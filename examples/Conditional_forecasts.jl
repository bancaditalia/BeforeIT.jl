# Forecasts conditional on the REALISED path of Government expenditure, Exports and Imports

import BeforeIT as Bit
using Plots

Bit.@object struct NewModel(Bit.Model) <: Bit.AbstractModel end

Bit.@object mutable struct ExogenousGovernment(Bit.Government) <: Bit.AbstractGovernment
    C_Gs::Vector{Float64}  # Time series of government expenditure
end

Bit.@object mutable struct ExogenousRestOfTheWorld(Bit.RestOfTheWorld) <: Bit.AbstractRestOfTheWorld
    C_Es::Vector{Float64}  # Time series of exports
    Y_Is::Vector{Float64}  # Time series of imports
end

# Replace the default stochastic government spending with a deterministic function
function Bit.gov_expenditure(model::NewModel)
    println("Using overridden gov_expenditure at t = ", model.agg.t)
    gov = model.gov
    c_G_g = model.prop.c_G_g    # weights for gov consumption across goods
    P_bar_g = model.agg.P_bar_g # price levels for those goods
    pi_e = model.agg.pi_e       # expected inflation

    C_G = gov.C_Gs[model.agg.t] # actual government expenditure for the current time step t
    J = size(gov.C_d_j, 1)      # Get the number of goods J
    C_d_j = C_G ./ J .* ones(J) .* sum(c_G_g .* P_bar_g) .* (1 + pi_e) # demand for each good from the government, adjusted for inflation and price

    return C_G, C_d_j # total government expenditure at time t AND vector of demand across goods
end

function Bit.rotw_import_export(model::NewModel)
    println("Using overridden rotw_import_export at t = ", model.agg.t)
    rotw = model.rotw
    c_E_g = model.prop.c_E_g    # consumption weights for exports across goods.
    c_I_g = model.prop.c_I_g    # consumption weights for imports
    P_bar_g = model.agg.P_bar_g # average prices of goods
    pi_e = model.agg.pi_e       # expected inflation.

    # Export Demand
    C_E = rotw.C_Es[model.agg.t] # export value at time t, taken from the exogenous path.
    L = length(rotw.C_d_l)       # number of export sectors
    C_d_l = C_E ./ L .* ones(L) .* sum(c_E_g .* P_bar_g) .* (1 + pi_e) # disaggregated export demand across L sectors, scaled by consumption weights and price levels.

    # Import Demand
    Y_I = rotw.Y_Is[model.agg.t] # import value at time t, from the exogenous path
    Y_m = c_I_g * Y_I            # total import demand, weighted by c_I_g.
    P_m = P_bar_g * (1 + pi_e)   # adjusted import price, accounting for inflation.

    return C_E, Y_I, C_d_l, Y_m, P_m
end

# Load parameters and initial conditions
p, ic = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions

firms = Bit.Firms(p, ic)
w_act, w_inact = Bit.Workers(p, ic)
cb = Bit.CentralBank(p, ic)
bank = Bit.Bank(p, ic)
agg = Bit.Aggregates(p, ic)
properties = Bit.Properties(p, ic)
data = Bit.Data()

# Initialise custom objects
standard_government = Bit.Government(p, ic)
standard_rotw = Bit.RestOfTheWorld(p, ic)
initial_C_G = standard_government.C_G
initial_C_E = standard_rotw.C_E
initial_Y_I = standard_rotw.Y_I
# Extract exogenous paths from initial conditions
T0 = Int(p["T_prime"])    # starting index
C_Gs = ic["C_G"][T0:end]
C_Es = ic["C_E"][T0:end]
Y_Is = ic["Y_I"][T0:end]
# check that the initial values match
println("Initial C_G match: ", initial_C_G == C_Gs[1])
println("Initial C_E match: ", initial_C_E == C_Es[1])
println("Initial Y_I match: ", initial_Y_I == Y_Is[1])

exog_government = ExogenousGovernment(Bit.fields(standard_government)..., C_Gs)
exog_rotw = ExogenousRestOfTheWorld(Bit.fields(standard_rotw)..., C_Es, Y_Is)
new_model = NewModel((w_act, w_inact, firms, bank, cb, exog_government, exog_rotw, agg, properties, data))

# run conditional forecasts
T = 12  # forecast horizon
model_vec_new = Bit.ensemblerun(new_model, T, 8);

# Plot all available variables
ps = Bit.plot_data_vector(
    model_vec_new; quantities = [
        :nominal_gdp, :real_gdp,
        :nominal_gva, :real_gva,
        :nominal_household_consumption, :real_household_consumption,
        :nominal_government_consumption, :real_government_consumption,
        :nominal_capitalformation, :real_capitalformation,
        :nominal_fixed_capitalformation, :real_fixed_capitalformation,
        :nominal_fixed_capitalformation_dwellings, :real_fixed_capitalformation_dwellings,
        :nominal_exports, :real_exports,
        :nominal_imports, :real_imports,
        :operating_surplus, :compensation_employees,
        :wages, :taxes_production,
        :gdp_deflator_growth_ea, :real_gdp_ea,
        :euribor,
    ], t_start = 5
)
plot(ps..., layout = (5, 5), size = (1500, 1000))

# Plot replication Fig 3 Poledna (sliced - start in 2011)
ps = Bit.plot_data_vector(
    model_vec_new, quantities = [
        :real_gdp,
        :real_household_consumption,
        :real_fixed_capitalformation,
        :real_government_consumption,
        :real_exports,
        :real_imports,
    ], t_start = 5
)
plot(ps..., layout = (2, 3), size = (1000, 600))


# Plot the whole forecast from 2010Q2 for the 6 variables in Poledna fig 3:
ps = Bit.plot_data_vector(
    model_vec_new, quantities = [
        :real_gdp,
        :real_household_consumption,
        :real_fixed_capitalformation,
        :real_government_consumption,
        :real_exports,
        :real_imports,
    ]
)
plot(ps..., layout = (2, 3))
