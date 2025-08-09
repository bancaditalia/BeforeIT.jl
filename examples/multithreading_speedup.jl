# # Multithreading speedup for large models

# In this tutorial we illustrate how to make use of multi-threading in `BeforeIT.jl`
# to allow for faster executions of single simulation runs.

import BeforeIT as Bit
using Plots, StatsPlots

# First, we initialise the model, this time we use the Italy 2010Q1 scenario
parameters = Bit.ITALY2010Q1.parameters
initial_conditions = Bit.ITALY2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions);

# The model is in scale 1:2000, so it has around 30,000 households
model.prop.H

# Note that the households number is actually the sum of active and
# inactive households, the owners of firms and of the bank
length(model.w_act) + length(model.w_inact) + length(model.firms) + 1

# Let's fist check how many threads we have available in this Julia session
Threads.nthreads()

# Then we need to first compile the code not to count compilation time,
# we can do that just by executing the function one time
t = 50
Bit.run!(model, T; parallel = false);

# Let's now compare the performance of single-threading and multi-threading
model = Bit.Model(parameters, initial_conditions);
@time Bit.run!(model, T; parallel = false);

model = Bit.Model(parameters, initial_conditions);
@time Bit.run!(model, T; parallel = true);

# Is the speedup in line to what we would expect? Yes!
