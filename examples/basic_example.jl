# # Essential use of BeforeIT

# We start by importing the BeforeIT library and other useful libraries.
import BeforeIT as Bit
using Plots, StatsPlots

# We then initialise the model loading some precomputed set of parameters and by specifying a number of epochs.
# In another tutorial we will illustrate how to compute parameters and initial conditions.

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

# We can now initialise the model
model = Bit.Model(parameters, initial_conditions);

# Note that the it is very simple to inspect the model by typing
fieldnames(typeof(model))

# and to inspect the specific attributes of one agent type by typing
fieldnames(typeof(model.bank))

# We can run now the model for a number of epochs
T = 16
for t in 1:T
    Bit.step!(model; parallel = true)
    Bit.update_data!(model)
end

# Note that we can equivalently run the model for a number of epochs in the single command 
# `Bit.run!(model)`, but writing the loop explicitely is more instructive.
# We can then plot any time series stored in the data tracker, for example
plot(model.data.real_gdp, title = "gdp", titlefont = 10)

# Or we can plot multiple time series at once using the function `plot_data`
ps = Bit.plot_data(model,
                   quantities = [:real_gdp, :real_household_consumption,
                       :real_government_consumption, :real_capitalformation,
                       :real_exports, :real_imports, :wages, :euribor, :gdp_deflator])
plot(ps..., layout = (3, 3))

# To run multiple monte-carlo repetitions in parallel we can use
model = Bit.Model(parameters, initial_conditions)
model_vec = Bit.ensemblerun(model, T, 4)

# Note that this will use the number of threads specified when activating the Julia environment.
# To discover the number of threads available, you can use the command 
Threads.nthreads()

# To activate Julia with a specific number of threads, say 8, you can use the command
# `julia -t 8` in the terminal.
# We can then plot the results of the monte-carlo repetitions using the function `plot_data_vector`
ps = Bit.plot_data_vector(model_vec)
plot(ps..., layout = (3, 3))
