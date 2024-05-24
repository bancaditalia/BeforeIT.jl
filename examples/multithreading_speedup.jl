# # Multithreading speedup for large models

# In this tutorial we illustrate how to make use of multi threading in BeforeIT to allow for faster 
# executions of single simulation runs.

import BeforeIT as Bit
using FileIO, Plots, StatsPlots


# We then initialise the model, this time we will use the Italy 2010Q1 scenario, 
# and we want to simulate the model for a large number of epochs

parameters = Bit.ITALY2010Q1.parameters
initial_conditions = Bit.ITALY2010Q1.initial_conditions
T = 50
model = Bit.initialise_model(parameters, initial_conditions, T);


# The model is in scale 1:2000, so it has around 30,000 households

println(model.prop.H)

# Note that households are the sum of active and inactive households and the owners of firms and of the bank
println(length(model.w_act) + length(model.w_inact) + length(model.firms) + 1)

# Let's fist check how many threads we have available in this Julia session

println(Threads.nthreads())

# Let's now compare the performance of single threading and multi threading

@time data = Bit.run_one_sim!(model; multi_threading = false);

model = Bit.initialise_model(parameters, initial_conditions, T);
@time data = Bit.run_one_sim!(model; multi_threading = true);

# Is the speedup in line to what we would expect?
