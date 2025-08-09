# # Scenario analysis via function overloading

# In this tutorial we will illustrate how to perform a scenario analysis by running
# the model multiple times under a specific shock and comparing the results with the
# unshocked model.

import BeforeIT as Bit
using Plots, StatsPlots

parameters = Bit.AUSTRIA2010Q1.parameters;
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions;

# Initialise the model
model = Bit.Model(parameters, initial_conditions);

# Simulate the model for T quarters
T = 20
model_vec_baseline = Bit.ensemblerun!((deepcopy(model) for _ in 1:4), t);

# Now, apply a shock to the model and simulate it again
# Here, we do this by overloading the central_bank_rate function with the wanted behaviour
function Bit.central_bank_rate(cb::Bit.CentralBank, model::Bit.Model)
    gamma_EA = model.rotw.gamma_EA
    pi_EA = model.rotw.pi_EA
    taylor_rate = Bit.taylor_rule(cb.rho, cb.r_bar, cb.r_star, cb.pi_star, cb.xi_pi, cb.xi_gamma, gamma_EA, pi_EA)
    if model.agg.t < 10
        return 0.01
    else
        return taylor_rate
    end
end

model_vec_shocked = Bit.ensemblerun!((deepcopy(model) for _ in 1:4), t);

# Finally, we can plot baseline and shocked simulations
te = t + 1
StatsPlots.errorline(
    1:te,
    Bit.DataVector(model_vec_baseline).real_gdp,
    errortype = :sem,
    label = "baseline",
    titlefont = 10,
    xlabel = "quarters",
    ylabel = "GDP",
)
StatsPlots.errorline!(
    1:te,
    Bit.DataVector(model_vec_shocked).real_gdp,
    errortype = :sem,
    label = "shock",
    titlefont = 10,
    xlabel = "quarters",
    ylabel = "GDP",
)

# Note that, importantly, once the function `central_bank_rate` has been changed,
# the model will use the new interest rate in all the simulations, unless the
# function is changed again. To restore the original interest rate, you could
# close and restart the Julia session.
