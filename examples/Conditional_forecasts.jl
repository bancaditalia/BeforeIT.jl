# Forecasts conditional on the REALISED path of Government expenditure, Exports and Imports

import BeforeIT as Bit
using Plots, StatsPlots
# using Pkg 
# Pkg.add("MAT") uncomment if needed
using MAT

Bit.@object struct NewModel(Bit.Model) <: Bit.AbstractModel end

Bit.@object mutable struct ExogenousGovernment(Bit.Government) <: Bit.AbstractGovernment
    C_Gs::Vector{Float64}  # Time series of government expenditure
end

Bit.@object mutable struct ExogenousRestOfTheWorld(Bit.RestOfTheWorld) <: Bit.AbstractRestOfTheWorld
    C_Es::Vector{Float64}  # Time series of exports
    Y_Is::Vector{Float64}  # Time series of imports
end

# Replace the default stochastic government spending with a deterministic function
function Bit.gov_expenditure(gov::ExogenousGovernment, model::Bit.AbstractModel)
    println("Using overridden gov_expenditure at t = ", model.agg.t)
    c_G_g = model.prop.c_G_g    # weights for gov consumption across goods
    P_bar_g = model.agg.P_bar_g # price levels for those goods
    pi_e = model.agg.pi_e       # expected inflation

    # DEFAULT BEHAVIOUR
    # epsilon_G = randn() * gov.sigma_G
    # C_G = exp(gov.alpha_G * log(gov.C_G) + gov.beta_G + epsilon_G) # This would normally compute C_G using a log-linear stochastic process with a random shock (epsilon_G)

    C_G = gov.C_Gs[model.agg.t] # actual government expenditure for the current time step t
    J = size(gov.C_d_j, 1)      # Get the number of goods J
    C_d_j = C_G ./ J .* ones(J) .* sum(c_G_g .* P_bar_g) .* (1 + pi_e) # demand for each good from the government, adjusted for inflation and price

    return C_G, C_d_j # total government expenditure at time t AND vector of demand across goods
end

function Bit.rotw_import_export(rotw::ExogenousRestOfTheWorld, model::Bit.AbstractModel)
    println("Using overridden rotw_import_export at t = ", model.agg.t)
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

# Initialise custom objects

standard_government = Bit.Government(p, ic)
standard_rotw = Bit.RestOfTheWorld(p, ic)

# Upload the variables used to condition the forecast
file = matopen("C:/Users/341756/OneDrive - Bank of England/Documents/BoE ABM - local/BeforeIT.jl-main/data/CF_data_2010Q1_2019Q4.mat")

vars = names(file)
println(vars)
data_CF = read(file, "data_CF_10")  # This is your matrix
close(file)

initial_C_G = standard_government.C_G
initial_C_E = standard_rotw.C_E
initial_Y_I = standard_rotw.Y_I

T = 16  # forecast horizon

# Extract columns
C_Gs = data_CF[:, 1]  # Government consumption
C_Es = data_CF[:, 2]  # Exports
Y_Is = data_CF[:, 3]  # Imports

println("C_Gs = ", C_Gs)
println("C_Es = ", C_Es)
println("Y_Is = ", Y_Is)

exog_government = ExogenousGovernment(Bit.fields(standard_government)..., C_Gs)
exog_rotw = ExogenousRestOfTheWorld(Bit.fields(standard_rotw)..., C_Es, Y_Is)

agg = Bit.Aggregates(p, ic)
properties = Bit.Properties(p, ic)
data = Bit.Data()

new_model = NewModel((w_act, w_inact, firms, bank, cb, exog_government, exog_rotw, agg, properties, data))

model_vec_new = Bit.ensemblerun(new_model, T, 100)

# Get all variable names from the forecast object
variables = propertynames(model_vec_new[1].data)
# (:collection_time, :nominal_gdp, :real_gdp, :nominal_gva, :real_gva, :nominal_household_consumption, :real_household_consumption, :nominal_government_consumption, :real_government_consumption, :nominal_capitalformation, :real_capitalformation, :nominal_fixed_capitalformation, :real_fixed_capitalformation, :nominal_fixed_capitalformation_dwellings, :real_fixed_capitalformation_dwellings, :nominal_exports, :real_exports, :nominal_imports, :real_imports, :operating_surplus, :compensation_employees, :wages, :taxes_production, :gdp_deflator_growth_ea, :real_gdp_ea, :euribor, :nominal_sector_gva, :real_sector_gva)

# PLOT sliced data (EM)

# write function (to then be included in the package)
function plot_data_vectors_sliced(model_vector; titlefont=9, quantities=nothing, t_start=1, t_end=nothing)

    data_vectors = Bit.DataVector.(model_vector)
    Te = length(data_vectors[1].vector[1].wages)
    t_end = isnothing(t_end) ? Te : min(t_end, Te)
    t_range = t_start:t_end

    # If no quantities are provided, use all available ones
    all_vars = propertynames(data_vectors[1])
    exclude_vars = [:vector, :nominal_sector_gva, :real_sector_gva]  # exclude if needed
    selected_vars = isnothing(quantities) ? filter(q -> !(q in exclude_vars), all_vars) : quantities

    quarters = ["$(y)Q$(q)" for y in 2010:2025 for q in 1:4]
    quarter_labels = quarters[t_range]

    ps = []

    for q in selected_vars
        title = string(q)
        tick_indices = 1:4:length(t_range)
        xticks = (t_range[tick_indices], quarter_labels[tick_indices])

        try
            if q == :gdp_deflator
                nominals = [dv.nominal_gdp[t_range] for dv in data_vectors]
                reals = [dv.real_gdp[t_range] for dv in data_vectors]
                ratios = [nom ./ real for (nom, real) in zip(nominals, reals)]
                y_matrix = reduce(hcat, ratios)'
            else
                values = [getproperty(dv, q)[t_range] for dv in data_vectors]
                y_matrix = reduce(hcat, values)'
            end

            p = errorline(t_range, y_matrix,
                errorstyle = :ribbon,
                title = title,
                titlefont = titlefont,
                legend = false,
                xticks = xticks
            )
            push!(ps, p)
        catch e
            @warn "Skipping variable $q due to error: $e"
        end
    end

    return ps
end

# PLOT ALL available variables
ps = plot_data_vectors_sliced(model_vec_new, quantities=[
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
    :nominal_sector_gva, :real_sector_gva
], t_start=5)

plot(ps..., layout=(5, 5), size=(1500, 1000))
# savefig("Cond_forecast_2011-2014_ALL.png")

# PLOT Replication Fig 3 POLEDNA (sliced - start in 2011)
ps = plot_data_vectors_sliced(model_vec_new, quantities=[
        :real_gdp,
        :real_household_consumption,
        :real_fixed_capitalformation,
        :real_government_consumption,
        :real_exports,
        :real_imports,
    ], t_start=5)

plot(ps..., layout=(2, 3), size = (1000, 600))
# savefig("Cond_forecast_2011-2014 (Poledna Fig3 rep).png")

# PLOT the whole forecast from 2010Q2 for the 6 variables in POLEDNA fig 3:
ps = Bit.plot_data_vector(model_vec_new, quantities = [
    :real_gdp,
    :real_household_consumption,
    :real_fixed_capitalformation,
    :real_government_consumption,
    :real_exports,
    :real_imports,
])

plot(ps..., layout = (2, 3))
