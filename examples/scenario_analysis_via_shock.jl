# # Scenario analysis via custom shocks

# In this tutorial we will illustrate how to perform a scenario analysis by running the model multiple times
# under a specific shock and comparing the results with the unshocked model.

import BeforeIT as Bit
using Plots, StatsPlots


parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

# initialise the model and the data collector
T = 20
model = Bit.init_model(parameters, initial_conditions, T);

# Simulate the model for T quarters
data_vec_baseline = Bit.run_n_sims(model, 4)

# Now, apply a shock to the model and simulate it again
# A shock is simply a function that takes the model and changes some of its parameters for a specific time period.

# In this case, let's define an interest rate shock that sets the interest rate for a number of epochs.

# We do this by first defining a "struct" with some useful attributes
struct CustomShock
    rate::Float64    # target rate for the first 10 epochs
    final_time::Int  # number of epochs for the shock
end

# and then by making the struct a callable function that changes the interest rate in the model,
# this is done in Julia using the syntax below
function (s::CustomShock)(model::Bit.Model)
    if model.agg.t <= s.final_time
        model.cb.r_bar = s.rate
    end
end

# Now we define a specific shock with a rate of 0.01 for the first 10 epochs, and run a shocked simulation

custom_shock = CustomShock(0.0, 10)
data_vec_shocked = Bit.run_n_sims(model, 4; shock = custom_shock)

# Finally, we can plot baseline and shocked simulations

Te = T + 1
StatsPlots.errorline(
    1:Te,
    data_vec_baseline.real_gdp,
    errortype = :sem,
    label = "baseline",
    titlefont = 10,
    xlabel = "quarters",
    ylabel = "GDP",
)
StatsPlots.errorline!(
    1:Te,
    data_vec_shocked.real_gdp,
    errortype = :sem,
    label = "shock",
    titlefont = 10,
    xlabel = "quarters",
    ylabel = "GDP",
)

# Note that, importantly, once the function central_bank_rate has been changed, the model will use the new 
# interest rate in all the simulations, unless the function is changed again.
# To restore the original interest rate, we can simply re-import the function central_bank_rate
