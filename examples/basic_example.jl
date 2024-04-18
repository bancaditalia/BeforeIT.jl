# We start by importing the BeforeIT library and other useful libraries.

import BeforeIT as Bit
using FileIO, Plots, StatsPlots


# We then initialise the model loading some precomputed set of parameters and by specifying a number of epochs.
# In another tutorial we will illustrate how to compute parameters and initial conditions.

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

# We can now initialise the model, by specifying in advance the maximum number of epochs.

T = 16
model = Bit.initialise_model(parameters, initial_conditions, T)


# Note that the it is very simple to inspect the model by typing

fieldnames(typeof(model))

# and to inspect the specific attributes of one agent type by typing

fieldnames(typeof(model.bank))

# We can now define a data tracker, which will store the time series of the model.

data = Bit.initialise_data(model);

# We can run now the model for a number of epochs and progressively update the data tracker.

for t in 1:T
    println(t)
    Bit.one_epoch!(model; multi_threading = true)
    Bit.update_data!(data, model)
end

# Note that we can equivalently run the model for a number of epochs in the single command 
# `data = BeforeIT.run_one_sim!(model)` , but writing the loop explicitely is more instructive.

# We can then plot any time series stored in the data tracker, for example

p1 = plot(data.real_gdp, title = "gdp", titlefont = 10)
p2 = plot(data.real_household_consumption, title = "household cons.", titlefont = 10)
p3 = plot(data.real_government_consumption, title = "gov. cons.", titlefont = 10)
p4 = plot(data.real_capitalformation, title = "capital form.", titlefont = 10)
p5 = plot(data.real_exports, title = "exports", titlefont = 10)
p6 = plot(data.real_imports, title = "imports", titlefont = 10)
p7 = plot(data.wages, title = "wages", titlefont = 10)
p8 = plot(data.euribor, title = "euribor", titlefont = 10)
p9 = plot(data.nominal_gdp ./ data.real_gdp, title = "gdp deflator", titlefont = 10)

plot(p1, p2, p3, p4, p5, p6, p7, p8, p9, layout = (3, 3), legend = false)

# To run multiple monte-carlo repetitions in parallel we can use

model = Bit.initialise_model(parameters, initial_conditions, T)
data_vector = Bit.run_n_sims(model, 4)

# Note that this will use the number of threads specified when activating the Julia environment.
# To discover the number of threads available, you can use the command 

Threads.nthreads()

# To activate Julia with a specific number of threads, say 8, you can use the command
# `julia -t 8` in the terminal.

# We can then plot the results of the monte-carlo repetitions.
# Since we are saving the initial data point, we effectively have T+1 data points in our time series.

Te = T + 1

p1 = errorline(1:Te, data_vector.real_gdp, errorstyle = :ribbon, title = "gdp", titlefont = 10)
p2 = errorline(
    1:Te,
    data_vector.real_household_consumption,
    errorstyle = :ribbon,
    title = "household cons.",
    titlefont = 10,
)
p3 =
    errorline(1:Te, data_vector.real_government_consumption, errorstyle = :ribbon, title = "gov. cons.", titlefont = 10)
p4 = errorline(1:Te, data_vector.real_capitalformation, errorstyle = :ribbon, title = "capital form.", titlefont = 10)
p5 = errorline(1:Te, data_vector.real_exports, errorstyle = :ribbon, title = "exports", titlefont = 10)
p6 = errorline(1:Te, data_vector.real_imports, errorstyle = :ribbon, title = "imports", titlefont = 10)
p7 = errorline(1:Te, data_vector.wages, errorstyle = :ribbon, title = "wages", titlefont = 10)
p8 = errorline(1:Te, data_vector.euribor, errorstyle = :ribbon, title = "euribor", titlefont = 10)
p9 = errorline(
    1:Te,
    data_vector.nominal_gdp ./ data.real_gdp,
    errorstyle = :ribbon,
    title = "gdp deflator",
    titlefont = 10,
)
plot(p1, p2, p3, p4, p5, p6, p7, p8, p9, layout = (3, 3), legend = false)
