# # Scenario analysis via custom shocks

# In this tutorial we will illustrate how to perform a scenario analysis by
# running the model multiple times under a specific shock and comparing the
# results with the unshocked model.

import BeforeIT as Bit
import StatsBase: mean, std
using Plots

parameters = Bit.AUSTRIA2010Q1.parameters;
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions;

# Initialise the model
model = Bit.Model(parameters, initial_conditions);

# Simulate the baseline model for T quarters, N_reps times, and collect the data
t = 16
n_sims = 64
model_vec_baseline = Bit.ensemblerun!((deepcopy(model) for _ in 1:n_sims), t);

# Now, apply a shock to the model and simulate it again.
# A shock is simply a function that takes the model and changes some of
# its parameters for a specific time period.
# We do this by first defining a "struct" with useful attributes.
# For example, we can define an productivity and a consumption shock with the following structs
struct ProductivityShock
    productivity_multiplier::Float64    # productivity multiplier
end

struct ConsumptionShock
    consumption_multiplier::Float64    # productivity multiplier
    final_time::Int
end

# and then by making the structs callable functions that change the parameters of the model,
# this is done in Julia using the syntax below

# A permanent change in the labour productivities by the factor s.productivity_multiplier
function (s::ProductivityShock)(model::Bit.Model)
    return model.firms.alpha_bar_i .= model.firms.alpha_bar_i .* s.productivity_multiplier
end

# A temporary change in the propensity to consume model.prop.psi by the factor s.consumption_multiplier
function (s::ConsumptionShock)(model::Bit.Model)
    return if model.agg.t == 1
        model.prop.psi = model.prop.psi * s.consumption_multiplier
    elseif model.agg.t == s.final_time
        model.prop.psi = model.prop.psi / s.consumption_multiplier
    end
end

# Define specific shocks, for example a 2% increase in productivity
productivity_shock = ProductivityShock(1.02)

# or a 4 quarters long 2% increase in consumption
consumption_shock = ConsumptionShock(1.02, 4)

# Simulate the model with the shock
model_vec_shocked = Bit.ensemblerun!((deepcopy(model) for _ in 1:n_sims), t; shock = consumption_shock);

# extract the data vectors from the model vectors
data_vector_baseline = Bit.DataVector(model_vec_baseline);
data_vector_shocked = Bit.DataVector(model_vec_shocked);

# Compute mean and standard error of GDP for the baseline and shocked simulations
mean_gdp_baseline = mean(data_vector_baseline.real_gdp, dims = 2)
mean_gdp_shocked = mean(data_vector_shocked.real_gdp, dims = 2)
sem_gdp_baseline = std(data_vector_baseline.real_gdp, dims = 2) / sqrt(N_reps)
sem_gdp_shocked = std(data_vector_shocked.real_gdp, dims = 2) / sqrt(N_reps)

# Compute the ratio of shocked to baseline GDP
gdp_ratio = mean_gdp_shocked ./ mean_gdp_baseline

# the standard error on a ratio of two variables is computed with the error propagation formula
sem_gdp_ratio = gdp_ratio .* ((sem_gdp_baseline ./ mean_gdp_baseline) .^ 2 .+ (sem_gdp_shocked ./ mean_gdp_shocked) .^ 2) .^ 0.5

# Finally, we can plot the impulse response curve
plot(
    1:(t + 1),
    gdp_ratio,
    ribbon = sem_gdp_ratio,
    fillalpha = 0.2,
    label = "",
    xlabel = "quarters",
    ylabel = "GDP change",
)

# We can save the figure using: savefig("gdp_shock.png")
